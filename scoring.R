# remotes::install_deps()
library(score4cast)
library(arrow)
library(purrr)
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")

## we simply establish connections to our buckets and away we go:
endpoint = "data.ecoforecast.org"
endpoint = "minio.carlboettiger.info" # faster mirror
s3_prov <- arrow::s3_bucket("prov", endpoint_override = endpoint)
s3_forecasts <- arrow::s3_bucket("forecasts", endpoint_override = endpoint)
s3_targets <- arrow::s3_bucket("targets", endpoint_override = endpoint)

## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set
s3_scores <- arrow::s3_bucket("scores", endpoint_override = endpoint)

## a single score
#score_theme("aquatics", s3_forecasts, s3_targets, s3_scores, s3_prov, endpoint)

# Here we go!
c("aquatics",             ## 15.5s
  "beetles",              ## 9.36s
  "ticks",                ## 4.3m
  "terrestrial_daily",    ## 9.2m
  "terrestrial_30min",    ## 1.87hr (18m for csv.gz files)
  "phenology") %>%        ## 34.8m (6.31m for csv)
  purrr::map(score_theme, s3_forecasts, s3_targets, s3_scores, s3_prov, endpoint)


## Confirm we can access scores
#s3 <- arrow::s3_bucket("scores/parquet", endpoint_override = "minio.carlboettiger.info")
#ds <- arrow::open_dataset(s3, partitioning = c("theme", "year"))
#ds %>% count(theme) %>% collect()

# filtering by theme or year before collect will be fast too!
# ds %>% filter(year > 2021, theme=="phenology") %>% collect()




