readRenviron("~/.Renviron") # compatible with littler
#source(".Rprofile")

## Process the raw data into the target variable product
library(neonstore)
library(tidyverse)


export_dir <- path.expand("~/neon4cast-neonstore")
fs::dir_create(export_dir)


#temporary aquatic repo during test of new workflow
site_data <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv")
aq_sites <- site_data |> filter(aquatics == 1) |> pull(field_site_id)
ter_sites <- site_data |> filter(terrestrial == 1) |> pull(field_site_id)
tick_sites <- site_data |> filter(ticks == 1) |> pull(field_site_id)

message("aquatics targets")
neonstore::neon_download("DP1.20288.001", site = aq_sites) # water quality
neonstore::neon_download("DP1.20264.001", table ='30', site =  aq_sites)
neonstore::neon_download("DP1.20053.001", table ='30', site =  aq_sites)
neonstore::neon_store(table = "waq_instantaneous", n = 50)
neonstore::neon_store(table = "TSD_30_min")
neonstore::neon_store(table = "TSW_30min")

message("beetles targets")
neonstore::neon_download(product="DP1.10022.001", type = "expanded")
neonstore::neon_store(product = "DP1.10022.001")

message("Terrestrial targets")
print("Downloading: DP4.00200.001")
neonstore::neon_download(product = "DP4.00200.001", site = ter_sites, type = "basic")
neonstore::neon_store(product = "DP4.00200.001") 

message("Ticks targets")

neon_download(product = "DP1.10093.001", site = tick_sites)
neonstore::neon_store(product =  "DP1.10093.001", delim=",") 


## free RAM associated with write.
neon_disconnect()
## export via read-only connection
db <- neon_db(memory_limit = 4) # soft limit
message("exporting to parquet...")
neonstore::neon_export_db(export_dir, db = db)

DBI::dbDisconnect(db, shutdown=TRUE)
rm(db)
gc()


neonstore::standardize_export_names(export_dir)
#minio::install_mc()
#minio::mc_alias_set(endpoint = "data.ecoforecast.org")
minio::mc(glue::glue("mirror --overwrite {export_dir} minio/neon4cast-targets/neon"))




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
neonstore::neon_export_db(export_dir, db = db)


DBI::dbDisconnect(db, shutdown=TRUE)
rm(db)
gc()


neonstore::standardize_export_names(export_dir)

## remotes::install_github("cboettig/minio")
# minio::install_mc()
# minio::mc_alias_set(endpoint = "data.ecoforecast.org")
suppressMessages({
minio::mc(glue::glue("mirror --overwrite {export_dir} minio/neon4cast-targets/neon"))
})
message("DONE!")
