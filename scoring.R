# remotes::install_deps()
library(score4cast)
library(arrow)
library(purrr)

readRenviron("/home/rstudio/.Renviron")
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")

## we simply establish connections to our buckets and away we go:
endpoint = "data.ecoforecast.org"
s3_forecasts <- arrow::s3_bucket("neon4cast-forecasts", endpoint_override = endpoint)
s3_targets <- arrow::s3_bucket("neon4cast-targets", endpoint_override = endpoint)
## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set
s3_scores <- arrow::s3_bucket("neon4cast-scores", endpoint_override = endpoint)
s3_prov <- arrow::s3_bucket("neon4cast-prov", endpoint_override = endpoint)


## a single score
#errors <- score_theme("beetles", s3_forecasts, s3_targets, s3_scores, s3_prov, endpoint)


# Here we go!
errors <- 
  c("aquatics", "beetles",  "ticks",  "terrestrial_daily", 
    "terrestrial_30min", "phenology") %>%   
  purrr::map(score_theme, s3_forecasts, s3_targets,
             s3_scores, s3_prov, endpoint)


## Check logs:
failed_urls <- unlist(map(1:6, function(i)
  errors[[i]]$urls
))
message(paste("some URLs failed to score:\n",
              paste(failed_urls, collapse="\n")))


## Confirm we can access scores
library(dplyr)

s3 <- arrow::s3_bucket("neon4cast-scores/parquet", endpoint_override = endpoint)
ds <- arrow::open_dataset(s3, partitioning = c("theme", "year"))
ds %>% dplyr::count(theme) %>% dplyr::collect()


ds %>% dplyr::group_by(theme) %>% 
  dplyr::summarize(max = max(start_time)) %>%
  dplyr::collect()
