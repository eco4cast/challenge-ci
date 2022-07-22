library(arrow)
library(dplyr)
library(lubridate)

partition_targets <- function(theme, s3) {
  
  df <- readr::read_csv(glue::glue("https://data.ecoforecast.org/neon4cast-targets/{theme}/{theme}-targets.csv.gz", theme=theme),
                        show_col_types = FALSE)
  
  TARGET_VARS <- c("oxygen", 
                   "temperature", "richness", "abundance", "nee", "le", "vswc", 
                   "gcc_90", "rcc_90", "ixodes_scapularis", "amblyomma_americanum",
                   "Amblyomma americanum")
  
  
  path <- s3$path(glue::glue("{theme}/monthly", theme=theme))
  df %>% 
    neon4cast:::pivot_target(TARGET_VARS) %>%
    mutate(theme = theme, 
           year = year(time), 
           month = month(time),
           time = as_datetime(time)) %>%
    group_by(year, month) %>%
    write_dataset(path, format="csv")
} 

## Publishing Requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY set


# Here we go: split targets into monthly files (with hive-partitions).
endpoint = "data.ecoforecast.org"

endpoint = "minio.carlboettiger.info"

s3_targets <- arrow::s3_bucket("neon4cast-targets", endpoint_override = endpoint)
themes <- c("aquatics", "beetles",  "ticks",  "terrestrial_daily",
            "terrestrial_30min",  "phenology")

#partition_targets("ticks", s3_targets)
purrr::walk(themes, partition_targets, s3 = s3_targets)





## it is pretty easy to access all or part of a target file:
theme <- "phenology"
s <- 
  arrow::schema(
    site       = arrow::string(),
    x          = arrow::float64(),
    y          = arrow::float64(),
    z          = arrow::float64(),
    time       = arrow::timestamp("ns"),
    target     = arrow::string(),
    observed   = arrow::float64(),
    theme      = arrow::string()
  )
path <- s3_targets$path(glue::glue("{theme}/monthly", theme=theme))
target <- arrow::open_dataset(path, format="csv", skip_rows=1, schema=s) %>% collect()





