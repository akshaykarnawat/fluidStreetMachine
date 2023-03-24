# fluidStreetMachine -- code structure

``` text
$ tree ./
.
|____.circleci/
| |____config.yml
|____configs/
|____dashboards/
|____databases/
| |____snowflake/
| | |____file_formats/
| | |____tables/
| | |____migrations/
| | | |____V0.0.1__initial_database_objects.sql
| | | |____V0.0.2__load_data_from_s3.sql
| | |____transformations/
| | |____stages/
| | |____stored_procedures/
| | |____functions/
| | |____views/
|____demo/
| |____data/
| | |____processed/
| | |____raw/
|____docs/
|____iac/
| |____terraform/
| |____cfn/
|____jobs/
| |____workflows/
|____notebooks/
|____references/
|____scripts/
|____src/
| |____common/
| | |____utils/
| | |____abstractions/
| | |____extractors/
| | |____loaders/
| |____data/
| | |____make_dataset.py
| |____features/
| |____models/
| |____visualizations/
|____tests/
|____.pre-commit-config.yaml
|____Makefile
|____README.md
|____requirements.txt
```
