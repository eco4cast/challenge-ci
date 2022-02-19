# remotes::install_deps()
library(aws.s3)
library(neon4cast)
library(magrittr)
library(future)


## Heper utility:
source("R/filter_forecasts.R")
source("R/monthly_targets.R")


## A place to store everything
fs::dir_create("forecasts")
fs::dir_create("targets")
fs::dir_create("prov")
#Sys.setenv("AWS_DEFAULT_REGION" = "data",
#           "AWS_S3_ENDPOINT" = "ecoforecast.org")

message("Downloading forecasts ...")

## Note: s3sync stupidly also requires auth credentials even to download from public bucket

sink(tempfile()) # aws.s3 is crazy chatty and ignores suppressMessages()...
aws.s3::s3sync("forecasts", bucket= "forecasts",  direction= "download", verbose= FALSE)
aws.s3::s3sync("targets", "targets", direction= "download", verbose=FALSE)
aws.s3::s3sync("prov", bucket= "prov",  direction= "download", verbose= FALSE)

sink()

## List all the downloaded files
targets <- fs::dir_ls("targets", recurse = TRUE, type = "file")
forecasts <- fs::dir_ls("forecasts", recurse = TRUE, type = "file")

## Opt in to parallel execution (for score-it)
future::plan(future::multisession)
furrr::furrr_options(seed=TRUE)
options("mc.cores"=2)  # using too many cores with too little RAM wil crash

themes <- c("aquatics", "beetles", "phenology", "terrestrial_30min", "terrestrial_daily", "ticks")

for(i in 1:length(themes)){
  message(paste0(themes[i]," ..."))
  targets_file <- filter_theme(targets, themes[i])
  #targets_files <- monthly_targets(targets_file)
  forecast_files <- filter_theme(forecasts, themes[i])
  forecast_files <- filter_dates(forecast_files)
  #matched_targets <- lapply(forecast_files, match_targets, targets_file= targets_file)
  
  forecast_files <- forecast_files %>%
    filter_prov( "prov/scores-prov.tsv", targets_file)
  
  if(length(forecast_files) > 0){
    score_files <- neon4cast:::score_it(targets_file, forecast_files, dir = "scores/")
    prov::write_prov_tsv(data_in = c(targets_file, forecast_files),  data_out = score_files, provdb =  "prov/scores-prov.tsv")
  }
}

##### Requires secure credentials to upload data to s3 bucket  ##########

message("Uploading scores to EFI server...")
sink(tempfile())  # aws.s3 is crazy chatty and ignores suppressMessages()..

aws.s3::s3sync("scores", "scores", direction= "upload", verbose=FALSE)
aws.s3::s3sync("prov", bucket= "prov",  direction= "upload", verbose= FALSE)

sink()
