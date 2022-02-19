monthly_targets <- function(targets_file){
  
  
  targets <- readr::read_csv(targets_file, guess_max = 10000, show_col_types = FALSE)
  
  targets_month_year <- targets %>% 
    dplyr::mutate(month = lubridate::month(time),
                  year = lubridate::year(time)) %>% 
    dplyr::select(month, year) %>% 
    dplyr::distinct()
  
  file_names <- rep(NA, length(nrow(targets_month_year)))
  
  for(i in 1:nrow(targets_month_year)){
    month_file <- targets %>% 
      dplyr::filter(lubridate::month(time) == targets_month_year$month[i],
                    lubridate::year(time) == targets_month_year$year[i])
    
    month <- targets_month_year$month[i] 
    if(targets_month_year$month[i] < 10){
      month <- paste0("0", month)
    }
    
    output <- paste0(targets_month_year$year[i], "-", month, "-", basename(targets_file))
    
    theme <- unlist(stringr::str_split_fixed(basename(targets_file),"-",2 ))[1]
    
    fs::dir_create(file.path("targets",theme,"monthly"))
    
    readr::write_csv(month_file, file.path("targets", theme, "monthly", output))
    
    #aws.s3::s3write_using(FUN = readr::write_csv,
    #                      x = month_file,
    #                      object = file.path(theme, "monthly", output),
    #                      bucket = "targets",
    #                      opts = list(
    #                        base_url = "ecoforecast.org",
    #                        region = "data"))
    
    file_names[i] <- file.path("targets", theme, "monthly", output)
  }
  invisible(file_names)
}

match_targets <- function(forecast_file, targets_file){
  
  if(any(vapply(c("[.]csv", "[.]csv\\.gz"), grepl, logical(1), forecast_file))){
    d <- readr::read_csv(forecast_file, guess_max = 10000, show_col_types = FALSE)
    time <- d$time
  }else{
    nc <- ncdf4::nc_open(forecast_file)
    time <- as.integer(ncdf4::ncvar_get(nc, "time"))
    t_string <- strsplit(ncdf4::ncatt_get(nc, varid = "time", "units")$value, " ")[[1]]
    if(t_string[1] == "days"){
      tustr<-strsplit(ncdf4::ncatt_get(nc, varid = "time", "units")$value, " ")
      time <-lubridate::as_date(time,origin=unlist(tustr)[3])
    }else{
      tustr <- lubridate::as_datetime(strsplit(ncdf4::ncatt_get(nc, varid = "time", "units")$value, " ")[[1]][3])
      time <- as.POSIXct.numeric(time, origin = tustr)
    } 
    ncdf4::nc_close(nc)
  }
  
  targets_month_year <- tibble::tibble(time) %>% 
    dplyr::mutate(month = lubridate::month(time),
                  year = lubridate::year(time)) %>% 
    dplyr::select(month, year) %>% 
    dplyr::distinct()
  
  file_names <- rep(NA, length(nrow(targets_month_year)))
  
  for(i in 1:nrow(targets_month_year)){
    month <- targets_month_year$month[i] 
    if(targets_month_year$month[i] < 10){
      month <- paste0("0", month)
    }
    
    output <- paste0(targets_month_year$year[i], "-", month, "-", basename(targets_file))
    
    theme <- unlist(stringr::str_split_fixed(basename(targets_file),"-",2 ))[1]
    
    file_names[i] <- file.path("targets", theme, "monthly", output)
  }
  return(list(forecast_file = forecast_file, targets_files = file_names))
}
