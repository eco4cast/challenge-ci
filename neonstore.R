## 02_generate_targets_aquatics
## Process the raw data into the target variable produc
library(neonstore)
library(tidyverse)

Sys.setenv("NEONSTORE_HOME" = "/home/rstudio/data/neonstore")
Sys.setenv("NEONSTORE_DB" = "/home/rstudio/data/neonstore")

sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-aquatics/master/Aquatic_NEON_Field_Site_Metadata_20210928.csv")
focal_sites <- sites$field_site_id

# aquatics
neonstore::neon_download("DP1.20288.001",site = focal_sites, type = "basic")
neonstore::neon_download("DP1.20264.001", site =  focal_sites, type = "basic")
neonstore::neon_download("DP1.20053.001", site =  focal_sites, type = "basic")
neonstore::neon_store(table = "TSD_30_min")
neonstore::neon_store(table = "waq_instantaneous", n = 50)
neonstore::neon_store(table = "TSW_30min")

# beetles
neonstore::neon_download(product="DP1.10022.001", type = "expanded")
neonstore::neon_store(product = "DP1.10022.001")

## Terrestrial
sites <- read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-terrestrial/master/Terrestrial_NEON_Field_Site_Metadata_20210928.csv")
print("Downloading: DP4.00200.001")
neonstore::neon_download(product = "DP4.00200.001", site = sites$field_site_id, type = "basic")
neonstore::neon_store(product = "DP4.00200.001") 

#fs::dir_create("/efi_neon_challenge/archive/neonstore")
#neonstore::neon_export_db("/efi_neon_challenge/archive/neonstore")
