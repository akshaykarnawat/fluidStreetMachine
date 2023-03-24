from abc import ABCMeta, abstractmethod


class AbcLoader(metaclass=ABCMeta):
    def __init__(self):
        super().__init__()

    def load(self, *args, **kwargs):
        return self._load(*args, **kwargs)

    @abstractmethod
    def _load(self, *args, **kwargs):
        return NotImplementedError
