from leviathan import Loop

from contextvars import Context, copy_context
from unittest.mock import AsyncMock
from time import monotonic
import asyncio


def test_subclassing() -> None:
    loop = Loop()
    try:
        assert isinstance(loop, asyncio.AbstractEventLoop)
    finally:
        loop.close()

def test_create_future() -> None:
    loop = Loop()
    try:
        loop.create_future()
    finally:
        loop.close()


def test_create_task() -> None:
    mock_func = AsyncMock(return_value=42)
    loop = Loop()
    try:
        task = loop.create_task(mock_func())
        loop.call_soon(loop.stop)
        loop.run_forever()
        mock_func.assert_called()
        mock_func.assert_awaited()
        assert task.result() == 42
    finally:
        loop.close()


def test_create_task_with_name() -> None:
    mock_func = AsyncMock(return_value=42)
    loop = Loop()
    try:
        task = loop.create_task(mock_func(), name="test")
        loop.call_soon(loop.stop)
        loop.run_forever()

        mock_func.assert_called()
        mock_func.assert_awaited()
        assert task.result() == 42
    finally:
        loop.close()


def test_create_task_with_context() -> None:
    async def test_func(context: Context) -> bool:
        return dict(context) == dict(copy_context())

    loop = Loop()
    try:
        context = copy_context()
        task = loop.create_task(test_func(context), context=context)
        loop.call_soon(loop.stop)
        loop.run_forever()
        assert task.result()
    finally:
        loop.close()


def test_create_task_with_context_and_name() -> None:
    async def test_func(context: Context) -> bool:
        return dict(context) == dict(copy_context())

    loop = Loop()
    try:
        context = copy_context()
        task = loop.create_task(test_func(context), name="test", context=context)
        loop.call_soon(loop.stop)
        loop.run_forever()

        assert task.result()
        assert task.get_name() == "test"
    finally:
        loop.close()


def test_time() -> None:
    loop = Loop()
    try:
        py_monotonic = monotonic()
        loop_monotonic = loop.time()
        assert abs(py_monotonic - loop_monotonic) < 0.1
    finally:
        loop.close()
