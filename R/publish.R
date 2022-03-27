library(aws.s3)

publish <- function(data_in = NULL,
                    code = NULL,
                    data_out = NULL,
                    meta = NULL, 
                    provdb = "prov.tsv", #fs::path(bucket, prefix, "prov.tsv"),
                    bucket, 
                    prefix = "",
                    registries = "https://hash-archive.org"){
  
  files <- c(data_in,code, data_out, meta)
  objects <- paste0(prefix, basename(files))
  
  lapply(seq_along(files), function(i) 
    aws.s3::put_object(files[[i]], objects[[i]], bucket)
  )
  
  
}





