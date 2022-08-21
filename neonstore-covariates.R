renv::restore()

## 02_generate_targets_aquatics
## Process the raw data into the target variable produc
library(neonstore)
library(tidyverse)
readRenviron("~/.Renviron") # compatible with littler
Sys.setenv("NEONSTORE_HOME" = "/home/rstudio/data/neonstore")

site_data <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv")
aq_sites <- site_data |> filter(aquatics == 1) |> pull(field_site_id)
ter_sites <- site_data |> filter(terrestrial == 1) |> pull(field_site_id)
tick_sites <- site_data |> filter(ticks == 1) |> pull(field_site_id)

## Use explicit table names to avoid downloading 1min / 2min or 5min versions of tables

message("Meterological covariates") # 
neon_download(product = "DP1.00006.001", table = "THRPRE_30min") # Precip, thoughfall
neon_download(product = "DP1.00098.001", table = "RH_30min") # Humidity, note two different sensor positions
neon_download(product = "DP1.00003.001", table= "TAAT_30min") # Temp (triple-aspirated)
neon_download(product = "DP1.00002.001", table="SAAT_30min") #Temp single aspirated
neon_download(product = "DP1.00023.001", table = "SLRNR_30min") # Short and long wave radiation
neon_download(product = "DP1.00006.001", table = "SECPRE_30min") # Precipitation secondary

neon_store(product = "DP1.00006.001", table = "THRPRE_30min") # Precip, thoughfall
neon_store(product = "DP1.00098.001", table = "RH_30min") # Humidity, note two different sensor positions
neon_store(product = "DP1.00003.001", table= "TAAT_30min") # Temp (triple-aspirated)
neon_store(product = "DP1.00002.001", table="SAAT_30min") #Temp single aspirated
neon_store(product = "DP1.00023.001", table = "SLRNR_30min") # Short and long wave radiation
neon_store(product = "DP1.00006.001", table = "SECPRE_30min") # Precipitation secondary
#neon_store(product = "DP1.00100.001") #empty?
neon_download(product = "DP4.00001.001") # Summary weather
neon_store(product = "DP4.00001.001") # Summary weather


message("Aquatic covariates:")
# note, is not downloading sensor positions
neon_download(product = "DP1.20059.001", site = aq_sites, table = "WSDBuoy_30min") # Wind Speed
neon_download(product = "DP1.20004.001", site = aq_sites, table = "BP_30min") # pressure
neon_download(product = "DP1.20046.001", site = aq_sites, table = "RHbuoy_30min") # temperature, humidity
neon_download(product = "DP1.20042.001", site = aq_sites, table = "PARWS_30min") # PAR surface
neon_download(product = "DP1.20261.001", site = aq_sites, table = "uPAR_30min") # PAR below
neon_download(product = "DP1.20016.001", site = aq_sites, table = "EOS_30_min") # Elevation of surface water
neon_download(product = "DP1.20217.001", site = aq_sites, table = "TGW_30_minute") # Groundwater temperature
neon_download(product = "DP1.20033.001", site = aq_sites, table = "NSW_15_minute") # Nitrate
neon_store(product = "DP1.20059.001", table="WSDBuoy_30min") # Wind Speed
neon_store(product = "DP1.20004.001", table = "BP_30min") # pressure
neon_store(product = "DP1.20046.001", table = "RHbuoy_30min") # temperature
neon_store(product = "DP1.20042.001",  table = "PARWS_30min") # PAR surface
neon_store(product = "DP1.20261.001", table = "uPAR_30min") # PAR below
neon_store(product = "DP1.20016.001", table = "EOS_30_min") # Elevation of surface water
neon_store(product = "DP1.20217.001", table = "TGW_30_minute") # Groundwater temperature
neon_store(product = "DP1.20033.001", table = "NSW_15_minute") # Nitrate


neon_disconnect()

## export via read-only connection
db <- neon_db(memory_limit = 4) # soft limit

## duckdb parquet export is not particularly RAM-efficient!
message("exporting to parquet...")
fs::dir_create("/home/rstudio/neon4cast-neonstore")
neonstore::neon_export_db("/home/rstudio/neon4cast-neonstore", db = db)

DBI::dbDisconnect(db, shutdown=TRUE)
rm(db)
gc()

message("Sync'ing to S3 bucket...")
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
Sys.setenv(AWS_EC2_METADATA_DISABLED="TRUE")
s3 <- arrow::s3_bucket("neon4cast-targets/neon", endpoint_override = "data.ecoforecast.org")
dir <- "/home/rstudio/neon4cast-neonstore"
neonstore::neon_sync_db(s3, dir)

