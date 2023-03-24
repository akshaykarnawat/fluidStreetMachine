from pandas import read_csv

from src.common.abstractions.abc_extractor import AbcExtractor


class CSVExtractor(AbcExtractor):
    def __init__(self):
        super().__init__()

    def _extract(self, *args, **kwargs):
        return read_csv(**kwargs)
