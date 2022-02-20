# ci-server

Configuration files for deploying EFI CI setup.

## Services

All services are defined by Docker Containers, as specified in [`docker-compose.yml`](docker-compose.yml).  These include:

- `caddy`:  Caddy is a reverse-proxy server that puts the other services behind a pretty domain name and configures https secure acccess. (https://caddyserver.com/)
- `minio`: Minio is popular high-performance object store (https://min.io/), providing AWS-S3-compliant buckets for upload and or download.
- `netdata`: Netdata is a monitoring service (https://www.netdata.cloud/)
- `shiny`: An RStudio-Shiny-server instance for interactively exploring scores.  
- `rstudio` RStudio server instance (https://rstudio.com)


## Deploying

This setup depends only on open source software and can be easily deployed on any VM, cloud, or local machine running Docker with [docker-compose](https://docs.docker.com/compose/) installed.  Deployment is nearly configuration-free. To get started, simply clone the repo and switch into the directory: 

```bash
git clone https://github.com/eco4cast/challenge-ci/ && cd challenge-ci
```

### Configuration

- In `config/` dir:
  - `minio` requires a user key and password, fill out the `minio_env_template.sh` and save it as `minio_env.sh`.  
  - `rstudio` requires a password, fill out `rstudio_env_template.sh` and save as `rstudio_env.sh`.  (Username is 'rstudio').
  - Edit `Caddyfile` for your own domain name, if desired.  Otherwise, omit caddy and connect to containers using the port numbers shown in the `docker-compose.yml`.
- Edit volume mappings as desired inside `docker-compose.yml`.  

Bring up all the services automatically with `docker-compose up -d`, or bring up individual services by name: (may require prepending commands with `sudo`)

```
docker-compose up -d minio
```

See the [docker-compose](https://docs.docker.com/compose/) docs for details.  For more on using `minio`, including programmatic access and configuration of access policies, see [minio client guide](https://docs.min.io/docs/minio-client-quickstart-guide.html).  




## User-facing addresses

- https://data.ecoforecast.org  (Data portal, see below)
- https://status.ecoforecast.org (netdata monitoring of server capacity)
- https://shiny.ecoforcast.org
- https://rstudio.ecoforecast.org

## Data buckets:

- https://data.ecoforecast.org/minio/drivers/  Download-only portal of Driver data  
- https://data.ecoforecast.org/minio/submissions Upload-only portal for submissions
- https://data.ecoforecast.org/minio/targets Target variables, derived from raw NEON data
- https://data.ecoforecast.org/minio/forecasts NEON Forecasts
- https://data.ecoforecast.org/minio/scores Scores of forecasts in the `forecasts` bucket

Can use web interface, direct download URLs, or AWS-S3 API tools.

## Deployment script

An example of a bash script for deploying the server

```
#!/bin/bash
mkdir eco4cast
cd ~/eco4cast
git clone https://github.com/eco4cast/challenge-ci
cd ~/eco4cast/challenge-ci
echo "MINIO_ACCESS_KEY=[insert]" > config/minio_env.sh
echo "MINIO_SECRET_KEY=[insert]" >> config/minio_env.sh
echo "PASSWORD=[insert]" > config/rstudio_env.sh
echo "root=TRUE" >> config/rstudio_env.sh
echo "S3_BASE=/efi_neon_forecast" > .env

## Make sure DNS mapping is up-to-date first
## Now we're ready to bring up the server!
cd ~/eco4cast/challenge-ci/server
docker-compose up -d
```

