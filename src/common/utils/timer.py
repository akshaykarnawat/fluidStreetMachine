from functools import wraps
from time import time

from src.common.utils.logger import logger


def timer(func):
    """
    Get the time it takes to run the function `func`
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        st = time()
        func_val = func(*args, **kwargs)
        et = time()
        logger.info("Time taken to run func %s was: %s", func.__name__, et - st)
        return func_val

    return wrapper
