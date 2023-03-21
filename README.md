# fluidStreetMachine -- code structure

``` text
$ tree ./
.
|____databases/
| |____snowflake/
| | |____file_formats/
| | |____tables/
| | |____stages/
| | |____functions/
| | |____views/
| | |____migration/
| | | |____v3__feature.sql
| | | |____v2__feature.sql
| | | |____v1__feature.sql
|____requirements.txt
|____.pre-commit-config.yaml
|____references/
|____Makefile
|____tests/
|____docs/
|____README.md
|____iac/
| |____terraform/
| |____cfn/
|____.gitignore
|____dashboards/
|____configs/
|____scripts/
|____jobs/
| |____workflows/
|____.circleci/
|____notebooks/
|____src/
| |____features/
| |____utils/
| |____models/
| |____common/
| |____visualizations/
| |____data/
```