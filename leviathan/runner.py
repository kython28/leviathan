from .loop import Loop

from typing import Any, Coroutine, TypeVar
import asyncio

_T = TypeVar("_T")


def run(coro_or_future: Coroutine[Any, Any, _T]) -> _T:
    return asyncio.run(coro_or_future, loop_factory=Loop)
