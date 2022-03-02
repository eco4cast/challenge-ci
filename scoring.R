# remotes::install_deps()
library(neon4cast)
library(future)
library(arrow)
library(dplyr)
library(purrr)

## Helper functions probably belong in `neon4cast`

## Helper utility because arrow::write_csv_arrow() can't handle diff-time!!
serialize_raw <- function(object,
                          fun = readr::write_csv,
                          ...) {
  zzz <- file(open="w+b") # we will serialize to an 'anonymous file'
  on.exit(close(zzz))
  fun(object, zzz, ...)
  readBin(zzz, "raw", seek(zzz))
}

## Our publish functions to the scoring bucket select the filename from file contents
score_name <- function(scores, ext = "csv") {
  r <- utils::head(scores, 1)
  paste0(paste("scores", r$theme, r$time, r$team, sep = "-"), ".", ext)
}

## because arrow::write_csv_arrow() sucks
write_csv_s3 <- function(df,
                         s3,
                         file_name = score_name(df, "csv")
                         ) {
  raw <- serialize_raw(df, readr::write_csv)
  x <- s3$OpenOutputStream(file_name)
  x$write(raw)
  x$close()
  
  file_name
}

write_parquet_s3 <- function(df, 
                             s3,
                             file_name = score_name(df, "parquet")
                             ) {
  path <- s3$path(file_name)
  arrow::write_parquet(df, path)
  file_name
}

TARGET_VARS <- c("oxygen", 
                "temperature", "richness", "abundance", "nee", "le", "vswc", 
                "gcc_90", "rcc_90", "ixodes_scapularis", "amblyomma_americanum")

#
#  Scoring follows a customized strategy here for efficiency
#  Because we have many forecasts for each single target, 
#  we pivot the target ONCE and score across all forecasts in the theme.
# 
#  In future, we will have separate targets by month, breaking this many-one strategy
#  And targets will also be pre-pivoted.
#
#  In that case, the helper utility will want to compute the appropriate subset of target
#  files to read based on having read in the forecast.
#

## assumes a pivoted targets data.frame is provided.
score_fn <- function(forecast_file, target, target_vars = TARGET_VARS) {
  options(readr.show_progress=FALSE) # read_forecast is verbose
  
  forecast_file %>% 
    neon4cast:::read_forecast() %>%
    mutate(filename = forecast_file) %>% 
    neon4cast:::pivot_forecast(target_vars) %>% 
    neon4cast:::crps_logs_score(target) %>%
    neon4cast:::include_horizon()
}

score_all <- function(forecast_files, targets_file,
                      s3_scores, target_vars = TARGET_VARS) {
  ## parse target file *once*
  theme <- strsplit(basename(targets_file), "[-_]")[[1]][[1]]
  target <- readr::read_csv(targets_file, show_col_types = FALSE, 
                            lazy = FALSE, progress = FALSE) %>% 
    mutate(theme = theme) %>% 
    neon4cast:::pivot_target(target_vars)
  
  ## Score every forecast against the same targets
  furrr::future_walk(forecast_files, 
                     function(file) {
                       score_fn(file, 
                                target = target, 
                                target_vars = target_vars) %>%
                         write_csv_s3(s3_scores)
                     }
  )
}




score_theme <- function(theme, s3_forecasts, s3_targets, s3_scores){

  ## extract URLs for forecasts & targets
  targets <- stringr::str_subset(s3_targets$ls(theme), "[.]csv(.gz)?")
  forecasts <- c(stringr::str_subset(s3_forecasts$ls(theme), "[.]csv(.gz)?"),
                 stringr::str_subset(s3_forecasts$ls(theme), "[.]nc"))
  forecast_urls <- paste0("https://", endpoint, "/forecasts/", forecasts )
  target_urls <- paste0("https://", endpoint, "/targets/", targets )
  
  ## Ideally, filter forecasts that have already been scored.
  ## Cheap option: determine score file name, and see if either forecast or target is newer.
  
  tick <- bench::bench_time({
  score_all(forecast_urls, target_urls, s3_scores)
  })
  message(paste("scored", theme, "in", tick[[2]]))
  
}


## parallel scoring optional, too many cores/RAM will crash
#future::plan(future::multicore)
#furrr::furrr_options(seed=TRUE)


## we simply establish connections to our buckets and away we go:
endpoint = "minio.thelio.carlboettiger.info"
s3_forecasts <- arrow::s3_bucket("forecasts", endpoint_override = endpoint)
s3_targets <- arrow::s3_bucket("targets", endpoint_override = endpoint)
## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set
s3_scores <- arrow::s3_bucket("scores", endpoint_override = endpoint)

# Here we go!
c("aquatics",             ## 26.5s
  "beetles",              ## 17s
  #"ticks",               ## error plotID column does not exist
  "terrestrial_daily",    ## 9.2m
  "terrestrial_30min",    ## 18.1m
  "phenology") %>%        ## 6.31m
  purrr::map(score_theme, s3_forecasts, s3_targets, s3_scores)




## Confirm we can access scores
scores_df <- arrow::open_dataset(s3_scores, 
                                 format="csv",
                                 schema = neon4cast::score_schema(),
                                 skip_rows=1)
scores_df %>% count(theme) %>% collect()






