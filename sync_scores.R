
Sys.setenv("AWS_DEFAULT_REGION"="data")
Sys.setenv("AWS_S3_ENDPOINT"="ecoforecast.org")
aws.s3::s3sync("/efi_neon_challenge/local/cb",bucket = "scores", direction = "download")
