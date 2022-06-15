# remotes::install_deps()
library(score4cast)
library(read4cast)
library(arrow)
library(purrr)
library(glue)
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
#Sys.unsetenv("AWS_ACCESS_KEY_ID")
#Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")


## we simply establish connections to our buckets and away we go:

processed <- function(x, s3) {
  fc <- read_forecast(x)
  key <- tools::file_path_sans_ext(basename(x), compression = TRUE)
  df <- score4cast:::pivot_forecast(fc, target_vars = score4cast:::TARGET_VARS)
  path <- s3$path(glue("processed/{key}.parquet"))
  write_parquet(df,path)
}

pivot_all_forecasts <- function(theme = "phenology",
                                bucket = "forecasts",
                                endpoint = "data.ecoforecast.org") {
  s3 <- arrow::s3_bucket(bucket, endpoint_override = endpoint)
  files <- s3$ls(theme)
  files <- files[!grepl("[.]xml", files)]
  urls <- paste0(glue::glue("https://{endpoint}/{bucket}/", 
                            bucket=bucket,
                            endpoint=endpoint),
                 files)
  
  purrr::walk(urls, processed, s3=s3)
}

#walk(urls[csvs], processed, s3=s3)
#walk(urls[ncs], processed, s3=s3)
#walk(urls[gz], processed, s3=s3)

bench::bench_time({
  pivot_all_forecasts("phenology")
  
})


#read_parquet(path)
