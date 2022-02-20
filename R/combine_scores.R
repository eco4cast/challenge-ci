
library(arrow)
library(dplyr)
library(bench) # only for benchmarking
Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")
Sys.unsetenv("AWS_ACCESS_KEY_ID")
Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")

## readr way, via local copy of `scores` dir
bench::bench_time({ # 1.44m w/o lazy. 4.58 sec with lazy
  scores_dir <- "/efi_neon_challenge/scores/"
  scores_files <- fs::dir_ls(scores_dir, type="file", recurse = TRUE)
  ds <- readr::read_csv(scores_files, progress = FALSE, lazy=TRUE)
  combined <- ds %>% collect()
})

## arrow local:
bench::bench_time({ # 3.35s
  scores_dir <- "/efi_neon_challenge/scores/"
  s <- neon4cast::score_schema()
  ds <- open_dataset(scores_dir, schema=s, format = "csv", skip_rows = 1)
  combined <- ds %>% collect()
})

## Remote arrow (internal network):  8.9s
bench::bench_time({
  s <- neon4cast::score_schema()
  s3 <- s3_bucket(bucket = "scores", endpoint_override = "data.ecoforecast.org", anonymous=TRUE)
  ds <- open_dataset(s3, schema=s, format = "csv", skip_rows = 1)
  combined <- ds %>% collect()
})


#### Reading a 'pre-combined' (single file) object: 

## arrow network csv
bench::bench_time({ # 8.3s
  analysis <- arrow::s3_bucket(bucket = "analysis", endpoint_override = "data.ecoforecast.org", anonymous = TRUE)
  ds <- arrow::read_csv_arrow(analysis$OpenInputFile("part-0.csv"))
})

## arrow network csv.gz
bench::bench_time({ # ERROR
  analysis <- arrow::s3_bucket(bucket = "analysis", endpoint_override = "data.ecoforecast.org", anonymous = TRUE)
  ds <- arrow::read_csv_arrow(analysis$OpenInputFile("combined_forecasts_scores.csv.gz"))
  ds %>% collect()
})


## arrow, network
bench::bench_time({ # 14s
  analysis <- arrow::s3_bucket(bucket = "analysis", endpoint_override = "data.ecoforecast.org", anonymous = TRUE)
  ds <- arrow::read_parquet(analysis$OpenInputFile("part-0.parquet"))
})

# arrow, local, parquet
bench::bench_time({  # 0.357 s
  ds <- arrow::read_parquet("/efi_neon_challenge/analysis/part-0.parquet")
})
# arrow, local, csv
bench::bench_time({ #1.01s
  ds <- arrow::read_csv_arrow("/efi_neon_challenge/analysis/part-0.csv")
})
# arrow local csv.gz
bench::bench_time({ # arrow, local, csv 2.69s
  ds <- arrow::read_csv_arrow("/efi_neon_challenge/analysis/combined_forecasts_scores.csv.gz")
})



## uncompressed, network
bench::bench_time({ # 39s, 5.4s lazy
  ds <- readr::read_csv("https://data.ecoforecast.org/analysis/part-0.csv", lazy=FALSE)
})
## compressed, network
bench::bench_time({ # 8.17s, 4.49s lazy
  ds <- readr::read_csv("https://data.ecoforecast.org/analysis/combined_forecasts_scores.csv.gz", lazy = FALSE)
})

## uncompressed, local
bench::bench_time({ # 4.3 s, 1.04s lazy
  ds <- readr::read_csv("/efi_neon_challenge/analysis/part-0.csv", lazy=TRUE)
})

## compressed, local
bench::bench_time({ # 7.51 seconds, 4.2s lazy
  ds <- readr::read_csv("/efi_neon_challenge/analysis/combined_forecasts_scores.csv.gz", lazy=TRUE)
})








## Writing
bench::bench_time({
analysis <- arrow::s3_bucket(bucket = "analysis", endpoint_override = "data.ecoforecast.org")
  ds %>% write_dataset(analysis, format="parquet")
  ds %>% write_dataset(analysis, format="csv") # requires dev version of arrow
  
})
## Simpler format fails due to date vs datetime formatting of "time"
#ds <- open_dataset(s3, format = "csv")


