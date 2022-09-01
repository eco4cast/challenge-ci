readRenviron("~/.Renviron") # compatible with littler
source(".Rprofile")
renv::restore()

## Process the raw data into the target variable produc
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
neonstore::neon_store(product =  "DP1.10093.001") 


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
#minio::mc_alias_set()
minio::mc(glue::glue("mirror --overwrite {export_dir} minio/neon4cast-targets/neon"))





