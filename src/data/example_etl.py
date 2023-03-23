
import traceback

from src.common.abstractions.abc_etl_factory import ETLFactory
from src.common.extractors.csv_extractor import CSVExtractor
from src.common.loaders.csv_loader import CSVLoader
from src.common.utils.helpers import i_help
from src.common.utils.logger import logger


class ETLExample(ETLFactory):
    """
    Just an example ETL Process based off the Abstract ETL Factory
    """

    def __init__(self):
        super(ETLExample, self).__init__()

        self.extractor = CSVExtractor()
        self.transformer = None
        self.loader = CSVLoader()

    def _extract(self, *args, **kwargs):
        # read the data using the CSV extractor
        self.data = None
        try:
            self.data = self.extractor.extract(*args, **kwargs)
        except Exception as e:
            traceback.format_exc(e)
        return self

    def _transform(self, *args, **kwargs):
        # self.transformer.transform()
        i_help()
        logger.info('transforming the data by removing some columns')
        _ = [self.data.drop(col, axis=1, inplace=True) for col in kwargs.get('colsToDrop', [])]
        return self

    def _load(self, *args, **kwargs):
        # load the data
        kwargs['dataframe'] = self.data
        try:
            self.loader.load(*args, **kwargs)
        except Exception as e:
            traceback.format_exc(e)
        return self
