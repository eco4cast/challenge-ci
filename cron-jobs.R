#remotes::install_github("rqthomas/cronR")
#remotes::install_deps()
library(cronR)

home_dir <-  path.expand("~")
log_dir <- path.expand("~/log/cron")

noaa_download_repo <- "neon4cast-noaa-download"
aquatic_repo <- "neon4cast-aquatics"
terrestrial_repo <- "neon4cast-terrestrial"
beetle_repo <- "neon4cast-beetles"
phenology_repo <- "neon4cast-phenology"
ticks_repo <- "neon4cast-ticks"

challange_ci_repo <- "challenge-ci"

scoring_repo <- "neon4cast-scoring"
submissions_repo <- "neon4cast-submissions"


## NEON import/export
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "neonstore.R"),
                           rscript_log = file.path(log_dir, "neonstore.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/a658b77a-bae9-4908-8f06-3603e1b5ff3f")
cronR::cron_add(command = cmd, frequency = 'daily', at = "2 am", id = 'neonstore')
## NEON import/export
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "neonstore-covariates.R"),
                           rscript_log = file.path(log_dir, "neonstore-covariates.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/94bc7dee-f7db-46c2-8dd2-c5d7004b3425")
cronR::cron_add(command = cmd, frequency = 'daily', at = "2 pm", id = 'neonstore-covariates')



## Processing Submissions
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "process_submissions.R"),
                           rscript_log = file.path(log_dir, "process_submissions.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/dad902ab-4847-4303-bd61-c27de2a1b43a")
cronR::cron_add(command = cmd, frequency = 'hourly', id = 'process_submissions')


## GEFS arrow 
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-snapshot.R"),
                           rscript_log = file.path(log_dir, "gefs4cast-snapshot.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/2d9f4d2f-b572-4a95-9346-bd482d4c3b31"
                           )
cronR::cron_add(command = cmd, frequency = '0 */4 * * *', id = 'gefs4cast')

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-stage2.R"),
                           rscript_log = file.path(log_dir, "gefs4cast_stage2.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/99e26eaa-9c54-483c-8110-36b5478e2352"
)
cronR::cron_add(command = cmd, frequency = 'daily', at = "2 pm", id = 'gefs4cast-stage2')

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-stage3.R"),
                           rscript_log = file.path(log_dir, "gefs4cast_stage3.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/5f92ac9f-dc35-4eb6-af98-cc8afc4d69d0"
)
cronR::cron_add(command = cmd, frequency = 'daily', at = "11 am", id = 'gefs4cast-stage3')


## Scoring 

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "scoring.R"),
                           rscript_log = file.path(log_dir, "scoring.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/1dd67f13-3a08-4a2b-86a3-6f13ab36baca")
cronR::cron_add(command = cmd, frequency = 'daily', at = "11 am", id = 'scoring')

## Phenocam Download and Target Generation

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, phenology_repo, "01_download_phenocam_data.R"),
                           rscript_log = file.path(log_dir, "phenology-download.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, phenology_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/f5d48d96-bb41-4c21-b028-930fa2b01c5a")
cronR::cron_add(command = cmd,  frequency = '0 */2 * * *', id = 'phenocam_download')

## Aquatics Targets

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, aquatic_repo,"02_generate_targets_aquatics.R"),
                           rscript_log = file.path(log_dir, "aquatics-target.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, aquatic_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/1267b13e-8980-4ddf-8aaa-21aa7e15081c")
cronR::cron_add(command = cmd, frequency = 'daily', at = "7AM", id = 'aquatics-targets')

## Beetles

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, beetle_repo,"beetles-workflow.R"),
                           rscript_log = file.path(log_dir, "beetle.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, beetle_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/ed35da4e-01d3-4750-ae5a-ad2f5dfa6e99")
cronR::cron_add(command = cmd, frequency = 'daily', at = "8AM", id = 'beetles-workflow')

## Terrestrial targets

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, terrestrial_repo,"02_terrestrial_targets.R"),
                           rscript_log = file.path(log_dir, "terrestrial-targets.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, terrestrial_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/c1fb635f-95f8-4ba2-a348-98924548106c")
cronR::cron_add(command = cmd, frequency = 'daily', at = "9AM", id = 'terrestrial-targets')

## Ticks

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, ticks_repo,"ticks-workflow.R"),
                           rscript_log = file.path(log_dir, "ticks.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, ticks_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/09c7ab10-eb4e-40ef-a029-7a4addc3295b")
cronR::cron_add(command = cmd, frequency = "0 11 1 * *", id = 'ticks-workflow')


cronR::cron_ls()

#####

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo,"sync_scores.R"),
                           rscript_log = file.path(log_dir, "sync_scores.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, challange_ci_repo))
cronR::cron_add(command = cmd, frequency = "59 * * * *", id = 'sync-scores')


cronR::cron_ls()


