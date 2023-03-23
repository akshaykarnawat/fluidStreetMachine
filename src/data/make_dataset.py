import click

from src.common.utils.logger import logger
from src.data.example_etl import ETLExample


@click.command()
@click.option("--input", help="Input")
@click.option("--output", help="Output")
def make_data(input, output):
    """
    Make data

    Arguments:
        input: input file path
        output: output file path

    """

    logger.info("ETL job starting")
    logger.info(f"{input} data is being transformed to {output} here")
    example_etl = (
        ETLExample()
        .extract(filepath_or_buffer=input, delimiter=",")
        .transform(
            colsToDrop=[
                "High needs student 2020-2021 attendance rate - year to date",
                "High needs student 2019-2020 attendance rate",
            ]
        )
        .load(path_or_buf=output)
    )
    logger.info("ETL job comple")


if __name__ == "__main__":
    make_data()
