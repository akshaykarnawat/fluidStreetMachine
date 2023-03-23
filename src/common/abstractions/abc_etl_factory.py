
from abc import ABCMeta, abstractmethod

from src.common.utils.logger import logger


class ETLFactory(metaclass=ABCMeta):

    extractor       = None
    transformer     = None
    loader          = None

    def __init__(self):
        logger.info('initializiing an instance of an etl factory')

    def extract(self, *args, **kwargs):
        return self._extract(*args, **kwargs)

    def transform(self, *args, **kwargs):
        return self._transform(*args, **kwargs)

    def load(self, *args, **kwargs):
        return self._load(*args, **kwargs)

    @abstractmethod # must be defined in all the concrete classes
    def _extract(self, *args, **kwargs):
        return NotImplementedError

    @abstractmethod # must be defined in all the concrete classes
    def _transform(self, *args, **kwargs):
        return NotImplementedError

    @abstractmethod # must be defined in all the concrete classes
    def _load(self, *args, **kwargs):
        return NotImplementedError