#renv::restore()

## Process the raw data into the target variable produc
library(neonstore)
library(tidyverse)
readRenviron("~/.Renviron") # compatible with littler
Sys.setenv("NEONSTORE_HOME" = "/home/rstudio/data/neonstore")
Sys.getenv("NEONSTORE_DB")

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
#neon_disconnect()
## export via read-only connection
#db <- neon_db(memory_limit = 4) # soft limit
## duckdb parquet export is not particularly RAM-efficient!
#message("exporting to parquet...")
#fs::dir_create("/home/rstudio/neon4cast-neonstore")
#neonstore::neon_export_db("/home/rstudio/neon4cast-neonstore", db = db)

#DBI::dbDisconnect(db, shutdown=TRUE)
#rm(db)
#gc()


#message("Sync'ing to S3 bucket...")
#Sys.unsetenv("AWS_DEFAULT_REGION")
#Sys.unsetenv("AWS_S3_ENDPOINT")
#Sys.setenv(AWS_EC2_METADATA_DISABLED="TRUE")
#s3 <- arrow::s3_bucket("neon4cast-targets/neon", endpoint_override = "data.ecoforecast.org")
#dir <- "/home/rstudio/neon4cast-neonstore"
#neonstore::neon_sync_db(s3, dir)

#parquet_labels <- function(dir) {
#  parquet_files <- list.files(dir, full.names = TRUE)
#  parquet_files <- parquet_files[grepl("[.]parquet",parquet_files)]
#  ## Ick, table names were mangled in file names, repair them!
#  con <- file.path(dir, "load.sql")
#  meta <- vroom::vroom_lines(con)
#  table_name <- from_sql_strings(meta, 2)
#  file_path <-  from_sql_strings(meta, 4)
#  names(table_name) <- file_path
#  table_name
#}

#from_sql_strings <- function(str, part = 2){ 
#  table_names <- vapply(strsplit(str, " "), 
#                        function(x){
#                          bits <- gsub("[\'\"]", "", x)
#                          bits[[part]]
#                        }, 
#                        character(1L))
#}

#table_names <- parquet_labels(dir)
#file_paths <- names(table_names)

#status <- lapply(seq_along(table_names), 
#                 function(i) {
#                   message(table_names[[i]])
#                   df <- arrow::open_dataset(file_paths[[i]])
#                   if(!is.null(df$schema$GetFieldByName("siteID"))){
#                     arrow::write_dataset(df, s3$path(table_names[[i]]), partitioning = "siteID")
#                   }else{
#                     arrow::write_dataset(df, s3$path(table_names[[i]]))
#                   }
#                 })



