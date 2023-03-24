# fluidStreetMachine -- code structure

``` text
$ tree ./
.
|____databases/
| |____snowflake/
| | |____file_formats/
| | |____tables/
| | | |____change_history.sql
| | |____migrations/
| | | |____V1.0.0__initial_database_objects.sql
| | |____stages/
| | |____functions/
| | |____views/
|____requirements.txt
|____references/
|____Makefile
|____tests/
|____docs/
|____README.md
|____iac/
| |____terraform/
| |____cfn/
| | |____s3_bucket.yaml
|____.gitignore
|____dashboards/
|____configs/
| |____schemachange-config.yml
|____scripts/
|____jobs/
| |____workflows/
|____.circleci/
| |____config.yml
|____notebooks/
|____src/
| |____features/
| |______init__.py
| |____utils/
| |____models/
| |____common/
| |____visualizations/
| |____data/
| | |______init__.py
| | |____make_dataset.py
```
