
from src.common.abstractions.abc_loader import AbcLoader


class CSVLoader(AbcLoader):

    def __init__(self):
        super().__init__()

    def _load(self, *args, **kwargs):
        if 'dataframe' not in kwargs:
            raise ValueError("No 'dataframe' in kwargs to save")
        df = kwargs.get('dataframe')
        kwargs.pop('dataframe')
        df.to_csv(*args, **kwargs)
