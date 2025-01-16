from .loop import Loop, ThreadSafeLoop

from typing import Any, Coroutine, TypeVar
import asyncio

_T = TypeVar("_T")


def run(coro_or_future: Coroutine[Any, Any, _T], thread_safe: bool = False) -> _T:
    if thread_safe:
        loop_factory = ThreadSafeLoop
    else:
        loop_factory = Loop

    return asyncio.run(coro_or_future, loop_factory=loop_factory)
