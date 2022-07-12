## CRON-job to update the recent GEFS parquet files
## Will pick up from the day after the last date on record

# WARNING: needs >= GDAL 3.4.x
#remotes::install_github("eco4cast/gefs4cast")
library(gefs4cast)

# be littler-compatible
readRenviron("~/.Renviron")

# Set destination bucket
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
Sys.setenv(AWS_EC2_METADATA_DISABLED="TRUE")
s3 <- arrow::s3_bucket("drivers", endpoint_override = "data.ecoforecast.org")

# most recent date on record (FIXME should check data is complete?)
start <- as.Date( max(basename(s3$ls("noaa/neon/gefs"))) ) + 1
end <- Sys.Date()
dates <- seq(start, end, by=1)

# Set desired dates and threads
# Adjust threads between 70 - 1120 depending on available RAM, CPU, + bandwidth
threads <- 100


p1 <-  purrr::map(dates, noaa_gefs, cycle="00", 
           threads=threads, s3=s3, gdal_ops="")

cycle <- c("6", "12", "18")
p1 <-  purrr::map(cycle, 
           function(cy) {
             map(dates, noaa_gefs, cycle=cy, max_horizon = 6,
                 threads=threads, s3=s3, gdal_ops="")
           })
