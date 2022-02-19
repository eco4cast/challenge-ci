
filter_theme <- function(x, theme) {
  x <- x[grepl(paste0(theme, "-"), x)]
  x <- x[!stringr::str_detect(x, "xml")]
  x <- x[!stringr::str_detect(x, "prov")]
  x <- x[!stringr::str_detect(x, "not_in_standard")]
  x <- x[!stringr::str_detect(x, "monthly")]
  x
}
filter_prov <- function(x, prov_tsv, target){
  
  if(!file.exists(prov_tsv)) return(x)
  prov <- readr::read_tsv(prov_tsv, show_col_types = FALSE, lazy = FALSE)
  
  new_target <- !(contentid::content_id(target) %in% prov$id)
  if(new_target) return(x)
  
  
  ids <- contentid::content_id(x)
  keep <- !(ids %in% prov$id)
  x[keep]
}

filter_dates <- function(x, ndays = 35){
  parsed <- unlist(stringr::str_split_fixed(basename(x), pattern = "-" , n = 5))
  dates <- lubridate::as_date(paste(parsed[,2],parsed[,3],parsed[,4],sep = "-")) 
  x <- x[which(dates > (Sys.Date() - lubridate::days(ndays)))]
  return(x)
}