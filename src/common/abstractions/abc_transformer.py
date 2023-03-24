from abc import ABCMeta, abstractmethod


class AbcTransformer(metaclass=ABCMeta):
    def __init__(self):
        super().__init__()

    def transform(self, *args, **kwargs):
        return self._transform(*args, **kwargs)

    @abstractmethod
    def _transform(self, *args, **kwargs):
        return NotImplementedError
