# remotes::install_deps()
library(neon4cast)
library(future)
library(arrow)
library(dplyr)
library(purrr)

target_schema <- arrow::schema(
    site       = arrow::string(),
    x          = arrow::float64(),
    y          = arrow::float64(),
    z          = arrow::float64(),
    time       = arrow::timestamp("us", "UTC"),
    target     = arrow::string(),
    observed   = arrow::float64(),
    theme      = arrow::string()
    # year = arrow::int32()     ## can't use, see: https://issues.apache.org/jira/browse/ARROW-15879?filter=-2
  )

TARGET_VARS <- c("oxygen", 
                "temperature", "richness", "abundance", "nee", "le", "vswc", 
                "gcc_90", "rcc_90", "ixodes_scapularis", "amblyomma_americanum")

## takes a pivoted targets but un-pivoted forecast
## if pivot_* fns were smart they could conditionally pivot
score <- function(forecast_df, target_df) {
  forecast_df %>%
    neon4cast:::pivot_forecast(TARGET_VARS) %>%
    neon4cast:::crps_logs_score(target_df) %>%
    neon4cast:::include_horizon()
}

# "target" can be a pointer to S3 bucket
# works with local or target data.frame too, but is unnecessary in that case 
# (bc data is targets have been fully parsed then and scoring will do filtering join anyway)
subset_target <- function(forecast_df, target) {
  range <- forecast_df %>% 
    summarise(start = min(time), end=max(time))
  start <- range$start[[1]]
  end <- range$end[[1]]
  
  year <- lubridate::year(start) # potential speed up, but arrow bug...
  target %>%
    filter(
      #year >= {{year}}, 
           time >= {{start}}, 
           time <= {{end}}) %>%
    collect()
}

## Lots of alternative ways to write these; could use local file but would have to sync
## Note that S3 cannot 'append' to a stream
## A poor man's index: says only if id has been seen before
prov_has <- function(id, s3_prov) {
  prov <-  s3_prov$ls()
  any(grepl(id, prov))
}
prov_add <- function(id, s3_prov) {
  x <- s3_prov$OpenOutputStream(id)
  x$write(raw()) # no actual information
  x$close()
}
## Note, we can still access timestamp on prov, and purge older than etc

score_dest <- function(forecast_file, s3_scores, type="parquet"){ 
  
  out <- tools::file_path_sans_ext(basename(forecast_file), compression = TRUE)
  theme <- strsplit(out, "-")[[1]][[1]]
  year <-  strsplit(out, "-")[[1]][[2]]
  path <- paste(type, theme, year, paste0(out, ".", type), sep="/")
  
  s3_scores$path(path)
}

## Score a single forecast, conditionally on prov
score_if <- function(forecast_file, 
                     target, 
                     s3_prov,
                     score_file = score_dest(forecast_file, 
                                             s3_scores,
                                             "parquet")
                     ) {
  
  forecast_df <- neon4cast:::read_forecast(forecast_file) %>% 
    mutate(filename = forecast_file)
  target_df <- subset_target(forecast_df, target)
  
  id <- rlang::hash(list(forecast_df, target_df))
  
  ## score only unique combinations of subset of targets + forecast
  if(!prov_has(id, s3_prov))
    score(forecast_df, target_df) %>%
      write_parquet(score_file)
  
  prov_add(id, s3_prov)
  invisible(id)
}

## apply score_if to all forecasts from a theme
score_theme <- function(theme, s3_forecasts, s3_targets, s3_scores){
  
  path <- s3_targets$path(glue::glue("{theme}/monthly", theme=theme))
  target <- arrow::open_dataset(path, format="csv", 
                                skip_rows = 1, schema = target_schema) 
  
  ## extract URLs for forecasts & targets
  forecasts <- c(stringr::str_subset(s3_forecasts$ls(theme), "[.]csv(.gz)?"),
                 stringr::str_subset(s3_forecasts$ls(theme), "[.]nc"))
  forecast_urls <- paste0("https://", endpoint, "/forecasts/", forecasts )

  tictoc <- bench::bench_time({
    purrr::walk(forecast_urls, score_if, target, s3_prov)
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






