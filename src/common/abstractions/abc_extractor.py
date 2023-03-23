
from abc import ABCMeta, abstractmethod

class AbcExtractor(metaclass=ABCMeta):

    def __init__(self):
        super().__init__()

    def extract(self, *args, **kwargs):
        return self._extract(*args, **kwargs)
    
    @abstractmethod
    def _extract(self, *args, **kwargs):
        return NotImplementedError
