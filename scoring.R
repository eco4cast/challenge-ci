# remotes::install_deps()
library(score4cast)
library(arrow)

readRenviron(path.expand("~/.Renviron"))
Sys.setenv("AWS_EC2_METADATA_DISABLED"="TRUE")
Sys.unsetenv("AWS_DEFAULT_REGION")


endpoint = "data.ecoforecast.org"
s3_forecasts <- arrow::s3_bucket("neon4cast-forecasts", endpoint_override = endpoint)
s3_targets <- arrow::s3_bucket("neon4cast-targets", endpoint_override = endpoint)
## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set
s3_scores <- arrow::s3_bucket("neon4cast-scores", endpoint_override = endpoint)
s3_prov <- arrow::s3_bucket("neon4cast-prov", endpoint_override = endpoint)

# Here we go!
themes <- c("beetles",  
            "ticks", 
            "aquatics", 
            "terrestrial_daily",
            "phenology", 
            "terrestrial_30min")

time <- score_theme("beetles", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 365L)
message(paste("beetles done in", time[["real"]]))

time <- score_theme("ticks", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 365L)
message(paste("ticks done in", time[["real"]]))

time <- score_theme("aquatics", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 35L)
message(paste("aquatics done in", time[["real"]]))

time <- score_theme("terrestrial_daily", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 35L)
message(paste("terrestrial_daily done in", time[["real"]]))

time <- score_theme("phenology", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 35L)
message(paste("phenology done in", time[["real"]]))

time <- score_theme("terrestrial_30min", s3_forecasts, s3_targets, s3_scores, s3_prov, max_horizon = 35L)
message(paste("terrestrial_30min done in", time[["real"]]))

