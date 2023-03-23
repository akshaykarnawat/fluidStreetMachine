import click


@click.command()
@click.option("--input", help="Input")
@click.option("--output", help="Output")
def make_data(input, output):
    print(f"{input} is being transformed and to {output} here")


if __name__ == "__main__":
    make_data()
