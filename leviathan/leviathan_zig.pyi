from typing import (
    TypeVar,
    TypeVarTuple,
    Callable,
    Optional,
    Coroutine,
    Any,
    AsyncGenerator,
)
from contextvars import Context
import asyncio, weakref

_T = TypeVar("_T")

class Future(asyncio.Future[_T]):
    def __init__(self, loop: asyncio.AbstractEventLoop) -> None: ...

class Task(asyncio.Task[_T]):
    def __init__(
        self,
        coro: Coroutine[Any, Any, _T],
        loop: asyncio.AbstractEventLoop,
        *,
        name: Optional[str] = None,
        context: Optional[Context] = None,
    ) -> None: ...

_Ts = TypeVarTuple("_Ts")

class Loop(asyncio.AbstractEventLoop):  # type: ignore
    _asyncgens: weakref.WeakSet[AsyncGenerator[Any]]

    def __init__(
        self,
        ready_tasks_queue_min_bytes_capacity: int,
        exception_handler: Callable[[Exception], None],
    ) -> None: ...

class StreamTransport(asyncio.Transport):
    def __init__(
        self,
        fd: int,
        protocol: asyncio.Protocol | asyncio.BufferedProtocol,
        loop: asyncio.AbstractEventLoop,
    ) -> None: ...
