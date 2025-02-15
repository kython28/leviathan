from .leviathan_zig import Loop as _Loop

from concurrent.futures import ThreadPoolExecutor
from typing import (
    Any,
    Callable,
    TypedDict,
    NotRequired,
    AsyncGenerator,
    Awaitable,
    TypeVar,
    TypeVarTuple,
    Unpack
)
from logging import getLogger

import asyncio, socket
import threading

logger = getLogger(__package__)

_T = TypeVar("_T")
_Ts = TypeVarTuple("_Ts")


class ExceptionContext(TypedDict):
    message: NotRequired[str]
    exception: Exception
    callback: NotRequired[object]
    future: NotRequired[asyncio.Future[Any]]
    task: NotRequired[asyncio.Task[Any]]
    handle: NotRequired[asyncio.Handle]
    protocol: NotRequired[asyncio.BaseProtocol]
    transport: NotRequired[asyncio.BaseTransport]
    socket: NotRequired[socket.socket]
    asyncgen: NotRequired[AsyncGenerator[Any]]


class Loop(_Loop):
    def __init__(self, ready_tasks_queue_min_bytes_capacity: int = 10**6) -> None:
        _Loop.__init__(
            self, ready_tasks_queue_min_bytes_capacity, self._call_exception_handler
        )

        self._exception_handler: Callable[[ExceptionContext], None] = (
            self.default_exception_handler
        )

        self._default_executor: ThreadPoolExecutor|None = None
        self._shutdown_executor_called: bool = False

    def _call_exception_handler(
        self,
        exception: Exception,
        *,
        message: str | None = None,
        callback: object | None = None,
        future: asyncio.Future[Any] | None = None,
        task: asyncio.Task[Any] | None = None,
        handle: asyncio.Handle | None = None,
        protocol: asyncio.BaseProtocol | None = None,
        transport: asyncio.BaseTransport | None = None,
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
        if transport is not None:
            context["transport"] = transport
        if socket is not None:
            context["socket"] = socket
        if asyncgenerator is not None:
            context["asyncgen"] = asyncgenerator

        self._exception_handler(context)

    def default_exception_handler(self, context: ExceptionContext) -> None: # type: ignore
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

    def call_exception_handler(self, context: ExceptionContext) -> None: # type: ignore
        self._exception_handler(context)

    # --------------------------------------------------------------------------------------------------------
    # If you're interested in using debug mode, use the CPython event loop implementation instead of Leviathan.
    def get_debug(self) -> bool:
        return False

    def set_debug(self, enabled: bool) -> None:
        _ = enabled
        return

    # --------------------------------------------------------------------------------------------------------

    async def shutdown_asyncgens(self) -> None:
        asyncgens = self._asyncgens
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

    def run_until_complete(self, future: Awaitable[_T]) -> _T:
        if self.is_closed() or self.is_running():
            raise RuntimeError("Event loop is closed or already running")

        new_task = not asyncio.isfuture(future)
        new_future = asyncio.ensure_future(future, loop=self)
        new_future.add_done_callback(self.__run_until_complete_cb)
        try:
            self.run_forever()
        except:
            if new_task and new_future.done() and not new_future.cancelled():
                new_future.exception()
            raise
        finally:
            new_future.remove_done_callback(self.__run_until_complete_cb)

        if not new_future.done():
            raise RuntimeError("Event loop stopped before Future completed.")

        return new_future.result()

    def run_in_executor(
        self, executor: Any, func: Callable[[Unpack[_Ts]], _T], *args: Unpack[_Ts]
    ) -> asyncio.Future[_T]:
        if executor is None and (executor := self._default_executor) is None:
            if self._shutdown_executor_called:
                raise RuntimeError("Default executor shutted down")

            executor = ThreadPoolExecutor(thread_name_prefix="leviathan")
            self._default_executor = executor

        concurrent_future = executor.submit(func, *args)
        return asyncio.wrap_future(concurrent_future, loop=self) # type: ignore

    def set_default_executor(self, executor: Any) -> None:
        if not isinstance(executor, ThreadPoolExecutor):
            raise TypeError("executor must be ThreadPoolExecutor")

        self._default_executor = executor

    def _do_shutdown(self, future: asyncio.Future[None]) -> None:
        is_closed: Callable[[], bool] = self.is_closed # type: ignore
        call_soon_threadsafe: Callable[..., asyncio.Handle] = self.call_soon_threadsafe # type: ignore

        if (executor := self._default_executor) is None:
            raise RuntimeError("Default executor is None")

        try:
            executor.shutdown(wait=True)
            if not is_closed():
                call_soon_threadsafe(
                    asyncio.futures._set_result_unless_cancelled, # type: ignore
                    future, None
                )
        except Exception as ex:
            if not is_closed() and not future.cancelled():
                call_soon_threadsafe(future.set_exception, ex)

    async def shutdown_default_executor(self, timeout: float|None = None) -> None:
        if timeout is not None and timeout < 0:
            raise ValueError("Invalid timeout")

        self._shutdown_executor_called = True
        executor = self._default_executor
        if executor is None:
            return

        future: asyncio.Future[None] = self.create_future() # type: ignore
        thread = threading.Thread(target=self._do_shutdown, args=(future,))
        thread.start()
        try:
            async with asyncio.timeouts.timeout(timeout):
                await future
        except asyncio.TimeoutError:
            executor.shutdown(wait=False)
        else:
            thread.join()
