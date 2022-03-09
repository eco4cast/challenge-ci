# remotes::install_deps()
library(neon4cast)
library(future)
library(arrow)
library(dplyr)
library(purrr)

## Helper functions probably belong in `neon4cast`

s <- 
  arrow::schema(
    site       = arrow::string(),
    x          = arrow::float64(),
    y          = arrow::float64(),
    z          = arrow::float64(),
    time       = arrow::timestamp("ns"),
    target     = arrow::string(),
    observed   = arrow::float64(),
    theme      = arrow::string()
    # year = arrow::int32()     ## can't use, see: https://issues.apache.org/jira/browse/ARROW-15879?filter=-2
    
  )


## Helper utility because arrow::write_csv_arrow() can't handle diff-time!!
serialize_raw <- function(object,
                          fun = readr::write_csv,
                          ...) {
  zzz <- file(open="w+b") # we will serialize to an 'anonymous file'
  on.exit(close(zzz))
  fun(object, zzz, ...)
  readBin(zzz, "raw", seek(zzz))
}
## because arrow::write_csv_arrow() sucks
write_csv_s3 <- function(df,
                         s3,
                         file_name = score_name(df, "csv")
) {
  ## note: read_csv_arrow cannot handle Inf either...
  f <- paste0("csv/", file_name)
  
  raw <- serialize_raw(df, readr::write_csv)
  x <- s3$OpenOutputStream(f)
  x$write(raw)
  x$close()
  
  file_name
}



## Our publish functions to the scoring bucket select the filename from file contents
score_name <- function(scores, ext = "csv") {
  r <- utils::head(scores, 1)
  paste(r$theme,
    paste0(paste("scores", r$theme, r$time, r$team, sep = "-"),
           ".", ext),
        sep="/")
}



write_parquet_s3 <- function(df, 
                             s3,
                             file_name = score_name(df, "parquet")
                             ) {
  f <- paste0("parquet/", file_name)
  path <- s3$path(f)
  arrow::write_parquet(df, path)
  file_name
}

TARGET_VARS <- c("oxygen", 
                "temperature", "richness", "abundance", "nee", "le", "vswc", 
                "gcc_90", "rcc_90", "ixodes_scapularis", "amblyomma_americanum")




# Filter target by the dates in the forecast
# "target" can be a pointer to S3 bucket
# works with local or target data.frame too, but is unnecessary in that case 
# (bc data is targets have been fully parsed then and scoring will do filtering join anyway)

subset_target <- function(forecast_df, target) {
  range <- forecast_df %>% 
    summarise(start = min(time), end=max(time))
  start <- range$start[[1]]
  end <- range$end[[1]]
  
  year <- lubridate::year(start) # potential speed up
  target %>%
    filter(
      #year >= {{year}}, 
           time >= {{start}}, 
           time <= {{end}}) %>%
    collect()
}


score <- function(forecast_df, target_df) {
  forecast_df %>%
    neon4cast:::pivot_forecast(target_vars) %>%
    neon4cast:::crps_logs_score(target_df) %>%
    neon4cast:::include_horizon()
}

## A poor man's index: says only if id has been seen before
prov_has <- function(id, s3_prov) {
  prov <-  s3_prov$ls()
  any(grepl(id, prov))
}
prov_add <- function(id, s3_prov) {
  x <- s3_prov$OpenOutputStream(id2)
  x$write(raw()) # no actual information
  x$close()
}




score_if <- function(forecast_file, target, s3_scores, s3_prov) {
  

  forecast_df <- neon4cast:::read_forecast(forecast_file) %>% 
    mutate(filename = forecast_file)
  
  target_df <- subset_target(forecast_df, target)
  
  id <- rlang::hash(list(forecast_df, target_df))
  
  ## score only unique combinations
  if(!prov_has(id, s3_prov))
    score(forecast_df, target_df) %>%
      write_parquet_s3(s3_scores)
  
  prov_add(id, s3_prov)
  invisible(id)
}


score_theme <- function(theme, s3_forecasts, s3_targets, s3_scores){
  
  
  path <- s3_targets$path(glue::glue("{theme}/monthly", theme=theme))
  target <- arrow::open_dataset(path, format="csv", skip_rows = 1, schema = s) 
  
  ## extract URLs for forecasts & targets
  forecasts <- c(stringr::str_subset(s3_forecasts$ls(theme), "[.]csv(.gz)?"),
                 stringr::str_subset(s3_forecasts$ls(theme), "[.]nc"))
  forecast_urls <- paste0("https://", endpoint, "/forecasts/", forecasts )

  tictoc <- bench::bench_time({
    purrr::walk(forecast_urls, score_if, target, s3_scores, s3_prov)
  })
  message(paste("scored", theme, "in", tictoc[[2]]))
  
}


## we simply establish connections to our buckets and away we go:
endpoint = "data.ecoforecast.org"
endpoint = "minio.carlboettiger.info" # faster mirror
s3_prov <- arrow::s3_bucket("prov", endpoint_override = endpoint)
s3_forecasts <- arrow::s3_bucket("forecasts", endpoint_override = endpoint)
s3_targets <- arrow::s3_bucket("targets", endpoint_override = endpoint)
## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set
s3_scores <- arrow::s3_bucket("scores", endpoint_override = endpoint)


# score_theme("phenology", s3_forecasts, s3_targets, s3_scores)

# Here we go!
c("aquatics",             ## 15.5s
  "beetles",              ## 9.36s
  "ticks",                ## 4.3m
  "terrestrial_daily",    ## 9.2m
  "terrestrial_30min",    ## 1.87hr (18m for csv.gz files)
  "phenology") %>%        ## 34.8m (6.31m for csv)
  purrr::map(score_theme, s3_forecasts, s3_targets, s3_scores)




# score_theme("phenology", s3_forecasts, s3_targets, s3_scores)

# Here we go!
c("aquatics",             ## 15.5s
  "beetles",              ## 9.36s
  "ticks",                ## 4.3m
  "terrestrial_daily",    ## 9.2m
  "terrestrial_30min",    ## 1.87hr (18m for csv.gz files)
  "phenology") %>%        ## 34.8m (6.31m for csv)
  purrr::map(score_theme, s3_forecasts, s3_targets, s3_scores)




## Confirm we can access scores
scores_df <- arrow::open_dataset(s3_scores$path("parquet"))
scores_df %>% count(theme) %>% collect()






