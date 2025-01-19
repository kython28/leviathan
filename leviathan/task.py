from .leviathan_zig import Task as _Task

from typing import TypeVar, Coroutine, Optional, Any
import asyncio

T = TypeVar('T')


class Task(_Task):
    def __init__(self, coro: Coroutine[Any, Any, T], *, loop: Optional[asyncio.AbstractEventLoop] = None,
                 name: Optional[Any] = None, context: Optional[Any] = None, eager_start: bool = False) -> None:
        if eager_start:
            raise RuntimeError("eager_start is not supported")

        if loop is None:
            loop = asyncio.get_running_loop()

        _Task.__init__(self, coro, loop, name=name, context=context)

