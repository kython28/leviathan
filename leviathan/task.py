from .leviathan_zig_single_thread import Task as _TaskSingleThread
from .leviathan_zig import Task as _Task

from typing import TypeVar, Coroutine, Optional, Any
from time import time
import asyncio

T = TypeVar('T')


class Task(_TaskSingleThread):
    def __init__(self, coro: Coroutine[Any, Any, T], *, loop: Optional[asyncio.AbstractEventLoop] = None,
                 name: Optional[Any] = None, context: Optional[Any] = None, eager_start: bool = False) -> None:
        if eager_start:
            raise RuntimeError("eager_start is not supported")

        if loop is None:
            loop = asyncio.get_running_loop()

        if name is None:
            name = f"Task-{int(time() * 1000)}"
        else:
            name = str(name)

        _TaskSingleThread.__init__(self, coro, loop, name, context)


class ThreadSafeTask(_Task):
    def __init__(self, coro: Coroutine[Any, Any, T], *, loop: Optional[asyncio.AbstractEventLoop] = None,
                 name: Optional[Any] = None, context: Optional[Any] = None, eager_start: bool = False) -> None:
        if eager_start:
            raise RuntimeError("eager_start is not supported")

        if loop is None:
            loop = asyncio.get_running_loop()

        if name is None:
            name = f"Task-{int(time() * 1000)}"
        else:
            name = str(name)

        _Task.__init__(self, coro, loop, name, context)
