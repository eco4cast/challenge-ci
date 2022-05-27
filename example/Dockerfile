FROM rocker/geospatial

RUN apt-get update && apt-get -y install cron
RUN apt-get update && apt-get -y install jags
RUN install2.r renv cronR


COPY cron.sh /etc/services.d/cron/run

## Usage notes: 
## docker run --rm -ti -v $(pwd)/Rscript:/Rscript -v $(pwd)/cron.d:/etc/cron.d eco4cast/cron  

