#renv::restore()
#remotes::install_github("rqthomas/cronR")
#remotes::install_deps()
library(cronR)

home_dir <-  path.expand("~")
log_dir <- path.expand("~/log/cron")

challange_ci_repo <- "challenge-ci"
targets_repo <- "neon4cast-targets"
scoring_repo <- "neon4cast-scoring"
submissions_repo <- "neon4cast-submissions"


## NEON import/export
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "neonstore-targets.R"),
                           rscript_log = file.path(log_dir, "neonstore.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/a658b77a-bae9-4908-8f06-3603e1b5ff3f")
cronR::cron_add(command = cmd, frequency = 'daily', at = "2AM", id = 'neonstore-targets')

## NEON import/export
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "neonstore-covariates.R"),
                           rscript_log = file.path(log_dir, "neonstore-covariates.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/94bc7dee-f7db-46c2-8dd2-c5d7004b3425")
cronR::cron_add(command = cmd, frequency = 'daily', at = "2PM", id = 'neonstore-covariates')


## Processing Submissions
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "process_submissions.R"),
                           rscript_log = file.path(log_dir, "process_submissions.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/dad902ab-4847-4303-bd61-c27de2a1b43a")
cronR::cron_add(command = cmd, frequency = '0 */2 * * *', id = 'process_submissions')


## GEFS arrow 
cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-snapshot.R"),
                           rscript_log = file.path(log_dir, "gefs4cast-snapshot.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/2d9f4d2f-b572-4a95-9346-bd482d4c3b31"
                           )
cronR::cron_add(command = cmd, frequency = '0 */4 * * *', id = 'gefs4cast')
#cronR::cron_add(command = cmd, frequency = 'hourly', id = 'gefs4cast')

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-stage2.R"),
                           rscript_log = file.path(log_dir, "gefs4cast_stage2.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/99e26eaa-9c54-483c-8110-36b5478e2352"
)
cronR::cron_add(command = cmd, frequency = '30 4 * * *', id = 'gefs4cast-stage2')

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "gefs4cast-stage3.R"),
                           rscript_log = file.path(log_dir, "gefs4cast_stage3.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/5f92ac9f-dc35-4eb6-af98-cc8afc4d69d0"
)
cronR::cron_add(command = cmd, frequency = '30 8 * * *', id = 'gefs4cast-stage3')


## Scoring 

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo, "scoring.R"),
                           rscript_log = file.path(log_dir, "scoring.log"),
                           log_append = FALSE,
                           cmd = "/usr/local/bin/r", # use litter, more robust on CLI
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/1dd67f13-3a08-4a2b-86a3-6f13ab36baca")
cronR::cron_add(command = cmd, frequency = 'daily', at = "10PM", id = 'scoring')

#####

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, challange_ci_repo,"sync_scores.R"),
                           rscript_log = file.path(log_dir, "sync_scores.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, challange_ci_repo),
                           trailing_arg = "curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/2a0f669c-5488-4e8d-8969-a3b4c6e2983d")
cronR::cron_add(command = cmd, frequency = "59 * * * *", id = 'sync-scores')


cronR::cron_ls()


