from .leviathan_zig_single_thread import Loop as _LoopSingleThread
from .leviathan_zig_single_thread import Future as _FutureSingleThread
from .leviathan_zig import Loop as _Loop
from .leviathan_zig import Future as _Future

from concurrent.futures import ThreadPoolExecutor

from typing import (
    Any,
    Callable,
    TypedDict,
    NotRequired,
    AsyncGenerator,
    Awaitable,
    TypeVar,
    Unpack,
)
from logging import getLogger

import asyncio, socket, weakref

logger = getLogger(__package__)

_T = TypeVar("_T")


class ExceptionContext(TypedDict):
    message: NotRequired[str]
    exception: Exception
    callback: NotRequired[object]
    future: NotRequired[asyncio.Future[Any]]
    task: NotRequired[asyncio.Task[Any]]
    handle: NotRequired[asyncio.Handle]
    protocol: NotRequired[asyncio.Protocol]
    socket: NotRequired[socket.socket]
    asyncgen: NotRequired[AsyncGenerator[Any]]


class _LoopHelpers:
    def __init__(self) -> None:
        self._exception_handler: Callable[[ExceptionContext], None] = (
            self.default_exception_handler
        )

    def _call_exception_handler(
        self,
        exception: Exception,
        *,
        message: str | None = None,
        callback: object | None = None,
        future: asyncio.Future[Any] | None = None,
        task: asyncio.Task[Any] | None = None,
        handle: asyncio.Handle | None = None,
        protocol: asyncio.Protocol | None = None,
        socket: socket.socket | None = None,
        asyncgenerator: AsyncGenerator[Any] | None = None,
    ) -> None:
        context: ExceptionContext = {"exception": exception}
        if message is not None:
            context["message"] = message
        if callback is not None:
            context["callback"] = callback
        if future is not None:
            context["future"] = future
        if task is not None:
            context["task"] = task
        if handle is not None:
            context["handle"] = handle
        if protocol is not None:
            context["protocol"] = protocol
        if socket is not None:
            context["socket"] = socket
        if asyncgenerator is not None:
            context["asyncgen"] = asyncgenerator

        self._exception_handler(context)
        self._default_executor: ThreadPoolExecutor|None = None
        self._shutdown_executor_called: bool = False

    def default_exception_handler(self, context: ExceptionContext) -> None:
        message = context.get("message")
        if not message:
            message = "Unhandled exception in event loop"

        log_lines = [message]
        for key, value in context.items():
            if key in {"message", "exception"}:
                continue
            log_lines.append(f"{key}: {value!r}")

        exception = context.get("exception")
        logger.error("\n".join(log_lines), exc_info=exception)

    def call_exception_handler(self, context: ExceptionContext) -> None:
        self._exception_handler(context)

    # --------------------------------------------------------------------------------------------------------
    # If you're interested in using debug mode, use the CPython event loop implementation instead of Leviathan.
    def get_debug(self) -> bool:
        return False

    def set_debug(self, enabled: bool) -> None:
        _ = enabled
        return

    # --------------------------------------------------------------------------------------------------------

    async def _shutdown_asyncgenerators(
        self, asyncgens: weakref.WeakSet[AsyncGenerator[Any]]
    ) -> None:
        closing_agens = list(asyncgens)
        asyncgens.clear()

        results = await asyncio.gather(
            *[agen.aclose() for agen in closing_agens], return_exceptions=True
        )

        for result, agen in zip(results, closing_agens, strict=True):
            if isinstance(result, Exception):
                self._exception_handler(
                    {
                        "message": f"an error occurred during closing of "
                        f"asynchronous generator {agen!r}",
                        "exception": result,
                        "asyncgen": agen,
                    }
                )

    def __run_until_complete_cb(self, future: asyncio.Future[Any]) -> None:
        loop = future.get_loop()
        loop.stop()

    def _run_until_complete(
        self, loop: asyncio.AbstractEventLoop, future: Awaitable[_T]
    ) -> _T:
        if loop.is_closed() or loop.is_running():
            raise RuntimeError("Event loop is closed or already running")

        new_task = not asyncio.isfuture(future)
        new_future = asyncio.ensure_future(future, loop=loop)
        new_future.add_done_callback(self.__run_until_complete_cb)
        try:
            loop.run_forever()
        except:
            if new_task and new_future.done() and not new_future.cancelled():
                new_future.exception()
            raise
        finally:
            new_future.remove_done_callback(self.__run_until_complete_cb)

        if not new_future.done():
            raise RuntimeError("Event loop stopped before Future completed.")

        return new_future.result()

    def _run_in_executor(
        self, loop: asyncio.AbstractEventLoop, executor: ThreadPoolExecutor|None, func: Callable[..., _T], *args: Any
    ) -> asyncio.Future[_T]:
        if executor is None and (executor := self._default_executor) is None:
            if self._shutdown_executor_called:
                raise RuntimeError("Default executor shutted down")

            executor = ThreadPoolExecutor(thread_name_prefix="leviathan")

        concurrent_future = executor.submit(func, *args)
        return asyncio.wrap_future(concurrent_future, loop=loop)

    def set_default_executor(self, executor: Any) -> None:
        if not isinstance(executor, ThreadPoolExecutor):
            raise TypeError("executor must be ThreadPoolExecutor")

        self._default_executor = executor


class Loop(_LoopSingleThread, _LoopHelpers):  # type: ignore
    def __init__(self, ready_tasks_queue_min_bytes_capacity: int = 10**6) -> None:
        _LoopHelpers.__init__(self)
        _LoopSingleThread.__init__(
            self, ready_tasks_queue_min_bytes_capacity, self._call_exception_handler
        )

    async def shutdown_asyncgens(self) -> None:
        await self._shutdown_asyncgenerators(self._asyncgens)

    def run_until_complete(self, future: Awaitable[_T]) -> _T:
        return self._run_until_complete(self, future)

    def run_in_executor(
        self, executor: ThreadPoolExecutor, func: Callable[..., _T], *args: Any
    ) -> asyncio.Future[_T]:
        return self._run_in_executor(self, executor, func, *args)


class ThreadSafeLoop(_Loop, _LoopHelpers):  # type: ignore
    def __init__(self, ready_tasks_queue_min_bytes_capacity: int = 10**6) -> None:
        _LoopHelpers.__init__(self)
        _Loop.__init__(
            self, ready_tasks_queue_min_bytes_capacity, self._call_exception_handler
        )

    async def shutdown_asyncgens(self) -> None:
        await self._shutdown_asyncgenerators(self._asyncgens)

    def run_until_complete(self, future: Awaitable[_T]) -> _T:
        return self._run_until_complete(self, future)

    def run_in_executor(
        self, executor: ThreadPoolExecutor, func: Callable[..., _T], *args: Any
    ) -> asyncio.Future[_T]:
        return self._run_in_executor(self, executor, func, *args)
