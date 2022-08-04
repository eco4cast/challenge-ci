## 02_generate_targets_aquatics
## Process the raw data into the target variable produc
library(neonstore)
library(tidyverse)
readRenviron("~/.Renviron") # compatible with littler
Sys.setenv("NEONSTORE_HOME" = "/home/rstudio/data/neonstore")
Sys.getenv("NEONSTORE_DB")

sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-aquatics/master/Aquatic_NEON_Field_Site_Metadata_20210928.csv")
aq_sites <- sites$field_site_id
sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-terrestrial/master/Terrestrial_NEON_Field_Site_Metadata_20210928.csv")
ter_sites <- sites$field_site_id
sites.df <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-ticks/master/Ticks_NEON_Field_Site_Metadata_20210928.csv")
tick_sites <- sites.df %>% pull(field_site_id)


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
neon_download(product = "DP1.20059.001", site = aq_sites) # Wind Speed
neon_download(product = "DP1.20004.001", site = aq_sites) # pressure
neon_download(product = "DP1.20046.001", site = aq_sites) # temperature
neon_download(product = "DP1.20042.001", site = aq_sites) # PAR surface
neon_download(product = "DP1.20261.001", site = aq_sites) # PAR below
neon_download(product = "DP1.20016.001", site = aq_sites) # Elevation of surface water
neon_download(product = "DP1.20217.001", site = aq_sites) # Groundwater temperature
neon_download(product = "DP1.20033.001", site = aq_sites) # Nitrate
neon_store(product = "DP1.20288.001") #Water Quality
neon_store(product = "DP1.20059.001") # Wind Speed
neon_store(product = "DP1.20004.001") # pressure
neon_store(product = "DP1.20046.001") # temperature
neon_store(product = "DP1.20042.001") # PAR surface
neon_store(product = "DP1.20261.001") # PAR below
neon_store(product = "DP1.20016.001") # Elevation of surface water
neon_store(product = "DP1.20217.001") # Groundwater temperature
neon_store(product = "DP1.20033.001") # Nitrate



message("export to parquet")
fs::dir_create("/home/rstudio/neon4cast-neonstore")
neonstore::neon_export_db("/home/rstudio/neon4cast-neonstore")

Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
Sys.setenv(AWS_EC2_METADATA_DISABLED="TRUE")
s3 <- arrow::s3_bucket("neon4cast-targets/neon", endpoint_override = "data.ecoforecast.org")
dir <- "/home/rstudio/neon4cast-neonstore"
neonstore::neon_sync_db(s3, dir)

