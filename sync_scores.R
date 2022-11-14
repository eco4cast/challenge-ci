#remotes::install_github("cboettig/minio")
library(minio)
install_mc()
mc_alias_set("efi",  endpoint="data.ecoforecast.org",
             access_key = "", secret_key = "")
mc("mirror --overwrite efi/neon4cast-scores /home/rstudio/data/scores")

# message("Starting score sync")
# message(Sys.time())
# 
# Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")
# Sys.unsetenv("AWS_ACCESS_KEY_ID")
# Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
# Sys.unsetenv("AWS_DEFAULT_REGION")
# Sys.unsetenv("AWS_S3_ENDPOINT")
# 
# challenge_config <- yaml::read_yaml("challenge_config.yml")
# 
# themes <- names(challenge_config$themes)
# 
# days90 <- as.character(Sys.Date() - lubridate::days(90))
# 
# unlink(file.path(challenge_config$DATA_DIR, "scores/parquet/"), recursive = TRUE)
# 
# library(arrow)
# for(i in 1:length(themes)){
#   message(themes[i])
# s3 <- s3_bucket(paste0("neon4cast-scores/parquet/", themes[i]), endpoint_override=challenge_config$endpoint_override)
# all_scores <- open_dataset(s3)
# if(themes[i] %in% c("aquatics","phenology","terrestrial_30min","terrestril_daily")){
#   all_scores <- all_scores |> 
#     dplyr::filter(reference_datetime > days90)
# }
# write_dataset(all_scores,
#               file.path(challenge_config$DATA_DIR, "scores/parquet/", themes[i]),
#               partitioning=c("model_id", "reference_datetime", "site_id"))
# }
# 
# gc()


message("Successfully synced scores")
