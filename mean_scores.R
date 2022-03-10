library(arrow)
library(tidyverse)
## we simply establish connections to our buckets and away we go:
endpoint = "data.ecoforecast.org"
endpoint = "minio.carlboettiger.info" # faster mirror

## Confirm we can access scores
s3_scores <- arrow::s3_bucket("scores", endpoint_override = "minio.carlboettiger.info")
phenology <- arrow::open_dataset(s3_scores$path("parquet/phenology"))


null_fill <- function(df, null_team = "EFInull") {
  df <- df %>% filter(!is.na(observed)) %>% collect()
  null <- df %>% 
    filter(team == null_team) %>%
    select("theme", "target", "x","y","z", "site", "time",
           "forecast_start_time", "crps", "logs")
  all <- tidyr::expand_grid(null, distinct(df,team))
  na_filled <- left_join(all, df,
                         by = c("theme", "team", "target", "x","y","z",
                                "site", "time", "forecast_start_time"),
                         suffix = c("_null", "_team"))
  null_filled <- na_filled %>% mutate(
    crps = case_when(is.na(crps_team) ~ crps_null,
                     !is.na(crps_team) ~ crps_team),
    logs = case_when(is.na(logs_team) ~ logs_null,
                     !is.na(logs_team) ~ logs_team)) %>% 
    select(-crps_null, -logs_null)
}


myfilled <- null_fill(df)

leaderboard <- myfilled %>% 
  group_by(team, target) %>%
  summarise(crps = mean(crps),
            logs = mean(logs),
            sample_crps = mean(crps_team, na.rm=TRUE),
            sample_logs = mean(logs_team, na.rm=TRUE),
            percent_NA = mean(is.na(crps_team)), .groups = "drop") 

## measure as distance from null
myfilled %>% 
  group_by(team, target, forecast_start_time) %>%
  summarise(crps = mean(crps),
            logs = mean(logs),
            sample_crps = mean(crps_team, na.rm=TRUE),
            sample_logs = mean(logs_team, na.rm=TRUE),
            percent_NA = mean(is.na(crps_team)), .groups = "drop") %>%
  ggplot(aes(forecast_start_time, crps, col=team)) + geom_path()

