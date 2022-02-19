library(aws.s3)

## Get all the targets.  
download_bucket <- function(bucket){
  index <- aws.s3::get_bucket(bucket, max = Inf)
  keys <- vapply(index, `[[`, "", "Key", USE.NAMES = FALSE)
  empty <- grepl("/$", keys)
  keys <- keys[!empty]
  lapply(keys, function(x) aws.s3::save_object(x, bucket = bucket, 
                                               file = file.path(bucket, x)))
  file.path(bucket, keys)
}