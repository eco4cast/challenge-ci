library(tidyverse)

#remotes::install_deps()
challenge_config <- yaml::read_yaml("challenge_config.yml")
## A place to store everything
local_dir <- file.path(challenge_config$DATA_DIR, "submissions")
unlink(local_dir, recursive = TRUE)
fs::dir_create(local_dir)

# cannot  set region="" using environmental variables!!
region=challenge_config$AWS_DEFAULT_REGION
Sys.setenv("AWS_DEFAULT_REGION" = challenge_config$AWS_DEFAULT_REGION,
           "AWS_S3_ENDPOINT" = challenge_config$AWS_S3_ENDPOINT)

message("Downloading forecasts ...")

## Note: s3sync stupidly also requires auth credentials even to download from public bucket

#sink(tempfile()) # aws.s3 is crazy chatty and ignores suppressMessages()...
aws.s3::s3sync(local_dir, bucket= "submissions",  direction= "download", verbose= FALSE, region=region)
#sink()

submissions <- fs::dir_ls(local_dir, recurse = TRUE, type = "file")

themes <- names(challenge_config$themes)


if(length(submissions) > 0){
  for(i in 1:length(submissions)){
    if(length(unlist(stringr::str_split(submissions[i], "/"))) == 3){
      file.copy(submissions[i], file.path(local_dir, basename(submissions[i])))
      submissions[i] <- file.path(local_dir, basename(submissions[i]))
    }
    curr_submission <- basename(submissions[i])
    theme <-  stringr::str_split(curr_submission, "-")[[1]][1]
    submission_date <- lubridate::as_date(paste(stringr::str_split(curr_submission, "-")[[1]][2:4], 
                                                collapse = "-"))
    print(i)
    print(curr_submission)
    print(theme)
    
    if((tools::file_ext(curr_submission) %in% c("nc", "gz", "csv", "xml")) & !is.na(submission_date)){
      
      log_file <- paste0(local_dir, "/",curr_submission,".log")
      
      if(theme %in% themes & submission_date <= Sys.Date()){
        
        capture.output({
          valid <- tryCatch(neon4cast::forecast_output_validator(file.path(local_dir,curr_submission)),
                            error = function(e) FALSE, 
                            finally = NULL)
        }, file = log_file, type = c("message"))
        
        if(valid){
          
          # pivot forecast before transferring
          if(!grepl("[.]xml", curr_submission)){
            fc <- read4cast::read_forecast(file.path(local_dir, curr_submission))
            df <- fc %>% 
              mutate(filename = basename(curr_submission)) %>% 
              score4cast::pivot_forecast(target_vars = score4cast:::TARGET_VARS)
            pivoted_fc <- paste0(tools::file_path_sans_ext(basename(curr_submission), compression=TRUE), ".csv.gz")
            tmp <- file.path(tempdir(), pivoted_fc) 
            readr::write_csv(df, tmp)
            # Then copy the original to the archives subdir
            aws.s3::put_object(file = tmp, 
                               object = paste0("s3://forecasts/", theme,"/",pivoted_fc), region=region)
            unlink(tmp) 
          }
          
          aws.s3::copy_object(from_object = curr_submission, 
                              from_bucket = "submissions", 
                              to_object = paste0("raw/", theme,"/",curr_submission), 
                              to_bucket = "forecasts",
                              region=region)
          if(aws.s3::object_exists(object = paste0(theme,"/",pivoted_fc), bucket = "forecasts", region=region)){
            print("delete")
            aws.s3::delete_object(object = curr_submission, bucket = "submissions", region=region)
          }
        } else { 
          aws.s3::copy_object(from_object = curr_submission, 
                              to_object = paste0("not_in_standard/",curr_submission), 
                              from_bucket = "submissions", 
                              to_bucket = "forecasts", region=region)
          if(aws.s3::object_exists(object = paste0("not_in_standard/",curr_submission), bucket = "forecasts", region=region)){
            print("delete")
            aws.s3::delete_object(object = curr_submission, bucket = "submissions", region=region)
          }
          
          aws.s3::put_object(file = log_file, 
                             object = paste0("not_in_standard/", 
                                             basename(log_file)), 
                             bucket = "forecasts", region=region)
        }
      } else if(!(theme %in% themes)){
        aws.s3::copy_object(from_object = curr_submission, 
                            to_object = paste0("not_in_standard/",curr_submission), 
                            from_bucket = "submissions",
                            to_bucket = "forecasts", region=region)
        capture.output({
          message(curr_submission)
          message("incorrect theme name in filename")
          message("Options are: ", paste(themes, collapse = " "))
        }, file = log_file, type = c("message"))
        
        if(aws.s3::object_exists(object = paste0("not_in_standard/",curr_submission), bucket = "forecasts", region=region)){
          print("delete")
          aws.s3::delete_object(object = curr_submission,
                                bucket = "submissions", region=region)
        }
        
        aws.s3::put_object(file = log_file,
                           object = paste0("not_in_standard/", 
                                           basename(log_file)), 
                           bucket = "forecasts", region=region)
      }else{
        #Don't do anything because the date hasn't occur yet
      }
    }else{
      aws.s3::copy_object(from_object = curr_submission, 
                          to_object = paste0("not_in_standard/",curr_submission), 
                          from_bucket = "submissions",
                          to_bucket = "forecasts", region=region)
    }
  }
}
unlink(local_dir, recursive = TRUE)

