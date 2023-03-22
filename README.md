# fluidStreetMachine -- code structure

``` text
$ tree ./
.
|____databases/
| |____snowflake/
| | |____file_formats/
| | | |____csv_no_header.sql
| | | |____json.sql
| | |____tables/
| | | |____test.sql
| | | |____trips.sql
| | | |____change_history.sql
| | | |____weather.sql
| | |____migrations/
| | | |____V1.0.2__create_table_test_using_vars.sql
| | | |____V1.0.0__initial_database_objects.sql
| | | |____V1.0.1__load_data_from_s3.sql
| | |____stages/
| | | |____trips.sql
| | | |____weather.sql
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