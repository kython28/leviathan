from leviathan import Task, Loop

from unittest.mock import AsyncMock

from contextvars import copy_context, Context
from typing import Any

import pytest, asyncio, io


def test_checking_subclassing_and_arguments() -> None:
    another_loop = asyncio.new_event_loop()
    loop = Loop()
    try:
        coro = AsyncMock()()
        with pytest.raises(TypeError):
            Task(coro, loop=another_loop)

        assert asyncio.isfuture(Task(coro, loop=loop))
        with pytest.raises(TypeError):
            Task(None, loop=loop)  # type: ignore

        loop.call_soon(loop.stop)
        loop.run_forever()
    finally:
        another_loop.close()
        loop.close()


def test_get_coro() -> None:
    loop = Loop()
    try:
        coro = AsyncMock()()
        task = Task(coro, loop=loop)
        assert task.get_coro() is coro
    finally:
        loop.close()


def test_get_context() -> None:
    loop = Loop()
    try:
        task = Task(AsyncMock()(), loop=loop)
        assert type(task.get_context()) is Context

        ctx = copy_context()
        task = Task(AsyncMock()(), loop=loop, context=ctx)
        assert task.get_context() is ctx
    finally:
        loop.close()


def test_get_loop() -> None:
    loop = Loop()
    try:
        task = Task(AsyncMock()(), loop=loop)
        assert task.get_loop() is loop
    finally:
        loop.close()


def test_name() -> None:
    loop = Loop()
    try:
        task = Task(AsyncMock()(), loop=loop)
        assert task.get_name()

        task = Task(AsyncMock()(), loop=loop, name="test")
        assert task.get_name() == "test"

        task.set_name("test2")
        assert task.get_name() == "test2"

        task.set_name(23)
        assert task.get_name() == "23"
    finally:
        loop.close()


def test_stack() -> None:
    loop = Loop()
    try:
        task = Task(AsyncMock()(), loop=loop)
        with io.StringIO() as buf:
            task.print_stack(file=buf)
            assert buf.getvalue()
    finally:
        loop.close()


def test_coro_running() -> None:
    loop = Loop()
    try:
        coro = AsyncMock(return_value=42)
        task = Task(coro(), loop=loop)
        loop.call_soon(loop.stop)
        loop.run_forever()

        coro.assert_called_once()
        assert task.result() == 42
    finally:
        loop.close()


def test_current_task() -> None:
    async def test_func(loop: asyncio.AbstractEventLoop) -> asyncio.Task[Any]|None:
        return asyncio.current_task(loop)

    loop = Loop()
    try:
        task = Task(test_func(loop), loop=loop)
        loop.call_soon(loop.stop)
        loop.run_forever()

        assert task.result() == task
    finally:
        loop.close()

def test_parent_task_cancels_child() -> None:
    async def child_task() -> str|None:
        try:
            await asyncio.sleep(1)
            return None
        except asyncio.CancelledError:
            return "Child cancelled"

    async def parent_task() -> str|None:
        child = asyncio.create_task(child_task())
        await asyncio.sleep(0.1)
        child.cancel()
        result = await child
        return result

    loop = Loop()
    try:
        result = loop.run_until_complete(parent_task())
        assert result == "Child cancelled"
    finally:
        loop.close()

def test_parent_task_cancels_while_awaiting() -> None:
    async def child_task() -> str|None:
        try:
            await asyncio.sleep(1)
            return None
        except asyncio.CancelledError:
            return "Child cancelled"

    async def parent_task(child: asyncio.Task[Any]) -> str|None:
        result = await child
        return result

    loop = Loop()
    try:
        task2 = loop.create_task(child_task())
        loop.call_later(0.1, task2.cancel)
        result = loop.run_until_complete(parent_task(task2))
        assert result == "Child cancelled"
    finally:
        loop.close()

def test_cancel_parent_not_child() -> None:
    child_done = asyncio.Event()

    async def child_task() -> str:
        try:
            await asyncio.sleep(0.5)
            child_done.set()
            return "Child completed"
        except asyncio.CancelledError:
            return "Child cancelled"

    async def parent_task() -> tuple[str, str]|None:
        child = asyncio.create_task(child_task())
        try:
            await asyncio.sleep(1)
            return None
        except asyncio.CancelledError:
            await child
            return "Parent cancelled", await child

    loop = Loop()
    try:
        parent = asyncio.ensure_future(parent_task(), loop=loop)
        loop.call_later(0.1, parent.cancel)
        result = loop.run_until_complete(parent)
        assert result == ("Parent cancelled", "Child completed")
        assert child_done.is_set()
    finally:
        loop.close()

def test_cancel_parent_with_long_wait() -> None:
    child_done = asyncio.Event()

    async def child_task() -> str:
        try:
            await asyncio.sleep(0.5)
            child_done.set()
            return "Child completed"
        except asyncio.CancelledError:
            return "Child cancelled"

    async def parent_task() -> tuple[str, str]|None:
        child = asyncio.create_task(child_task())
        try:
            await asyncio.sleep(3600)
            return None
        except asyncio.CancelledError:
            await child
            return "Parent cancelled", await child

    loop = Loop()
    try:
        parent = asyncio.ensure_future(parent_task(), loop=loop)
        loop.call_later(0.1, parent.cancel)
        result = loop.run_until_complete(parent)
        assert result == ("Parent cancelled", "Child completed")
        assert child_done.is_set()
    finally:
        loop.close()

def test_task_exception_propagation() -> None:
    async def raise_exception() -> None:
        raise ValueError("Test exception")

    async def parent_task() -> None:
        await asyncio.create_task(raise_exception())

    loop = Loop()
    try:
        with pytest.raises(ValueError, match="Test exception"):
            loop.run_until_complete(parent_task())
    finally:
        loop.close()

def test_task_result_timing() -> None:
    async def slow_task() -> str:
        await asyncio.sleep(0.1)
        return "Done"

    loop = Loop()
    try:
        task = asyncio.ensure_future(slow_task(), loop=loop)
        with pytest.raises(asyncio.InvalidStateError):
            task.result()  # Should raise because task is not done
        loop.run_until_complete(task)
        assert task.result() == "Done"  # Should not raise now
    finally:
        loop.close()

def test_task_cancel_callback() -> None:
    cancel_called = False

    def on_cancel(_: asyncio.Task[None]) -> None:
        nonlocal cancel_called
        cancel_called = True

    async def cancelable_task() -> None:
        try:
            await asyncio.sleep(1)
        except asyncio.CancelledError:
            raise

    loop = Loop()
    try:
        task = asyncio.ensure_future(cancelable_task(), loop=loop)
        task.add_done_callback(on_cancel)
        loop.call_later(0.1, task.cancel)
        with pytest.raises(asyncio.CancelledError):
            loop.run_until_complete(task)
        assert cancel_called
    finally:
        loop.close()
