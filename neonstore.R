## 02_generate_targets_aquatics
## Process the raw data into the target variable produc
library(neonstore)
library(tidyverse)
readRenviron("~/.Renviron") # compatible with littler
Sys.setenv("NEONSTORE_HOME" = "/home/rstudio/data/neonstore")
Sys.getenv("NEONSTORE_DB")

#temporary aquatic repo during test of new workflow
sites <- read_csv("https://raw.githubusercontent.com/OlssonF/neon4cast-aquatics/master/Aquatic_NEON_Field_Site_Metadata_20220727.csv")
#sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-aquatics/master/Aquatic_NEON_Field_Site_Metadata_20210928.csv")
aq_sites <- sites$field_site_id
sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-terrestrial/master/Terrestrial_NEON_Field_Site_Metadata_20210928.csv")
ter_sites <- sites$field_site_id
sites.df <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-ticks/master/Ticks_NEON_Field_Site_Metadata_20210928.csv")
tick_sites <- sites.df %>% pull(field_site_id)


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



message("export to parquet")
fs::dir_create("/home/rstudio/neon4cast-neonstore")
neonstore::neon_export_db("/home/rstudio/neon4cast-neonstore")

Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
Sys.setenv(AWS_EC2_METADATA_DISABLED="TRUE")
s3 <- arrow::s3_bucket("neon4cast-targets/neon", endpoint_override = "data.ecoforecast.org")
dir <- "/home/rstudio/neon4cast-neonstore"
message("copying to s3 bucket")
neonstore::neon_sync_db(s3, dir)

