message("Starting score sync")
message(Sys.time())

Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")
Sys.unsetenv("AWS_ACCESS_KEY_ID")
Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")

challenge_config <- yaml::read_yaml("challenge_config.yml")

themes <- names(challenge_config$themes)


library(arrow)
for(i in 1:length(themes)){
s3 <- s3_bucket(paste0("neon4cast-scores/parquet/", themes[i]), endpoint_override=challenge_config$endpoint_override)
all_scores <- open_dataset(s3)
write_dataset(all_scores,
              file.path(challenge_config$DATA_DIR, "scores/parquet/", themes[i]),
              format = 'parquet',  partitioning=c("model_id", "reference_datetime", "site_id"))
}

library(tidyverse)
all_scores |> 
  filter(target_id == "phenology", year>=2022) |> 
  select(start_time) |> 
  distinct(start_time) |> 
  collect() 
  group_by(model_id) |> 
  summarise(most_recent = max(start_time)) |> 
  collect()

## inspect most recent dates scored?
all_scores %>% 
  dplyr::group_by(target_id) %>% 
  dplyr::summarize(max = max(start_time)) %>%
  dplyr::collect()


message("Successfully synced scores")
