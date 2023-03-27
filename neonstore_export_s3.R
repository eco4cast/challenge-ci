library(neonstore)
library(DBI)
library(dplyr)
library(arrow)

neon_bucket <- function(table, endpoint = "https://sdsc.osn.xsede.org") {
  tbl =  stringr::str_replace(table, "-(DP\\d)", "/\\1") |> stringr::str_split_1("/")
  path = file.path("neon4cast-neonstore", tbl[[2]], tbl[[1]])
  bucket = paste0("bio230014-bucket01/", path)
  s3 <- arrow::S3FileSystem$create(endpoint_override = endpoint,
                                   access_key = Sys.getenv("OSN_KEY"),
                                   secret_key = Sys.getenv("OSN_SECRET"))
  s3_dir <- arrow::SubTreeFileSystem$create(bucket, s3)
  s3_dir
}


db <- neon_db()
tables <- db |> dbListTables()

tables <- tables[tables != "provenance"]
i  <- which(tables == "science_review_flags-DP4.00200.001")

tables <- tables[i:length(tables)]

for(table in tables) {
  message(table)

  df <- tbl(db, table)
  cols <- colnames(df)
  dest <- neon_bucket(table)
  if("startDateTime" %in% cols) {
  df <- df |>
    mutate(year = lubridate::year(startDateTime))
  } else {
    datecol <- cols[grepl("[Dd]ate", cols)]
    if(length(datecol) < 1)
      datecol <- cols[grepl("[Tt]ime", cols)]
    if(length(datecol) > 0) {
      datecol <- datecol[[1]]
      df <- df |>
        mutate(year = lubridate::year(.data[[datecol]]))
    }
  }

  if(all(c("siteID", "year") %in% colnames(df) )) {
    df  |>
      to_arrow() |>
      write_dataset(dest, partitioning = c("siteID", "year"))
  } else {
    df  |> to_arrow() |> write_dataset(dest)
  }
}
