from leviathan import Future, Loop

from unittest.mock import MagicMock
from typing import Any

import pytest, asyncio


def test_checking_subclassing() -> None:
    loop = Loop()
    try:
        assert asyncio.isfuture(Future(loop=loop))
    finally:
        loop.close()


def test_getting_loop() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        assert future.get_loop() is loop
    finally:
        loop.close()


def test_setting_value_and_done() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.set_result(42)
        assert not (future.cancelled())
        assert future.result() == 42
        assert future.done()
    finally:
        loop.close()


def test_cancelling_after_value() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.set_result(42)
        assert not (future.cancel())
        assert not (future.cancelled())
        assert future.result() == 42
        assert future.done()
    finally:
        loop.close()


def test_cancelling_before_value() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        assert future.cancel()
        with pytest.raises(asyncio.InvalidStateError):
            future.set_result(42)
        assert future.done()
    finally:
        loop.close()


def test_cancelling() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        assert future.cancel()
        assert future.cancelled()
        assert future.done()
    finally:
        loop.close()


def test_setting_exception() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        exc = RuntimeError("test")
        future.set_exception(exc)
        assert future.exception() is exc
        assert not (future.cancelled())
        assert future.done()
        with pytest.raises(RuntimeError) as exc_info:
            future.result()
        assert exc_info.value.args[0] == "test"
    finally:
        loop.close()


def test_cancelling_with_message() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.cancel(msg="test")
        assert future.cancelled()
        assert future.done()
        with pytest.raises(asyncio.CancelledError) as exc_info:
            future.result()
        assert exc_info.value.args[0] == "test"
    finally:
        loop.close()


def test_initializing_with_wrong_loop() -> None:
    loop = asyncio.new_event_loop()
    try:
        with pytest.raises(TypeError):
            Future(loop=loop)
    finally:
        loop.close()


def test_adding_callback() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        mock_func = MagicMock()
        future.add_done_callback(mock_func)
        future.set_result(42)
        assert future.done()

        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == 1
    finally:
        loop.close()


def test_adding_several_callbacks() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        mock_func = MagicMock()
        mock_func2 = MagicMock()
        mock_func3 = MagicMock()

        future.add_done_callback(mock_func)
        for _ in range(3):
            future.add_done_callback(mock_func2)
            future.add_done_callback(mock_func3)

        for _ in range(10):
            future.add_done_callback(mock_func3)

        future.set_result(42)
        assert future.done()

        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == 1
        assert mock_func2.call_count == 3
        assert mock_func3.call_count == 13
    finally:
        loop.close()


def test_adding_several_callbacks_and_removing() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        mock_func = MagicMock()
        mock_func2 = MagicMock()
        mock_func3 = MagicMock()

        future.add_done_callback(mock_func)
        for _ in range(3):
            future.add_done_callback(mock_func2)
            future.add_done_callback(mock_func3)

        for _ in range(10):
            future.add_done_callback(mock_func3)

        assert future.remove_done_callback(mock_func2) == 3
        assert future.remove_done_callback(mock_func3) == 13

        future.set_result(42)
        assert future.done()

        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == 1
        assert mock_func2.call_count == 0
        assert mock_func3.call_count == 0
    finally:
        loop.close()


def test_adding_callbacks_after_setting_result() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        mock_func = MagicMock()
        mock_func2 = MagicMock()
        mock_func3 = MagicMock()

        future.add_done_callback(mock_func)
        for _ in range(3):
            future.add_done_callback(mock_func2)
            future.add_done_callback(mock_func3)

        future.set_result(42)

        for _ in range(10):
            future.add_done_callback(mock_func3)

        assert future.done()

        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == 1
        assert mock_func2.call_count == 3
        assert mock_func3.call_count == 13
    finally:
        loop.close()


def test_future_await() -> None:
    async def test_func(fut: asyncio.Future[int]) -> int:
        loop = asyncio.get_running_loop()
        loop.call_soon(fut.set_result, 42)
        result = await fut
        return result

    loop = Loop()
    try:
        future = Future(loop=loop)
        result = loop.run_until_complete(test_func(future))
        assert future.done()
        assert future.result() == 42
        assert result == 42
    finally:
        loop.close()


def test_future_await_tuple() -> None:
    async def test_func(fut: asyncio.Future[tuple[int, str]]) -> tuple[int, str]:
        loop = asyncio.get_running_loop()
        loop.call_soon(fut.set_result, (42, "hello"))
        result = await fut
        return result

    loop = Loop()
    try:
        future = Future(loop=loop)
        result = loop.run_until_complete(test_func(future))
        assert future.done()
        assert future.result() == (42, "hello")
        assert result == (42, "hello")
    finally:
        loop.close()


def test_future_cancel_during_callback() -> None:
    def callback(fut: asyncio.Future[Any]) -> None:
        fut.cancel()

    loop = Loop()
    try:
        future = Future(loop=loop)
        future.add_done_callback(callback)
        future.set_result("Done")

        loop.run_until_complete(future)
        assert not future.cancelled()
    finally:
        loop.close()


def test_future_remove_done_callback() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        mock_callback = MagicMock()
        future.add_done_callback(mock_callback)
        future.remove_done_callback(mock_callback)
        future.set_result("Done")

        loop.run_until_complete(future)
        mock_callback.assert_not_called()
    finally:
        loop.close()


def test_future_callbacks_exception_handling() -> None:
    def callback_with_exception(_: asyncio.Future[Any]) -> None:
        raise ValueError("Callback exception")

    loop = Loop()
    try:
        future = Future(loop=loop)
        future.add_done_callback(callback_with_exception)

        future.set_result("Done")
        loop.run_until_complete(future)
    finally:
        loop.close()


def test_future_set_result_after_done() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.set_result("First")

        with pytest.raises(asyncio.InvalidStateError):
            future.set_result("Second")

        assert future.result() == "First"
    finally:
        loop.close()


def test_future_set_exception_after_result() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.set_result("First")

        with pytest.raises(asyncio.InvalidStateError):
            future.set_exception(ValueError("Test exception"))

        assert future.result() == "First"
    finally:
        loop.close()


def test_future_set_result_after_exception() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        future.set_exception(ValueError("Test exception"))

        with pytest.raises(asyncio.InvalidStateError):
            future.set_result("First")

        with pytest.raises(ValueError):
            future.result()
    finally:
        loop.close()


def test_future_set_invalid_exception() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        
        with pytest.raises(TypeError):
            future.set_exception(None)
        
        with pytest.raises(TypeError):
            future.set_exception("Not an exception")
    finally:
        loop.close()


def test_future_set_result_with_different_types() -> None:
    loop = Loop()
    try:
        # Test setting result with various types to ensure no unexpected behavior
        future = Future(loop=loop)
        future.set_result(None)
        assert future.result() == None

        future = Future(loop=loop)
        future.set_result(42)
        assert future.result() == 42

        future = Future(loop=loop)
        future.set_result("string")
        assert future.result() == "string"

        future = Future(loop=loop)
        future.set_result([1, 2, 3])
        assert future.result() == [1, 2, 3]

        future = Future(loop=loop)
        future.set_result({"key": "value"})
        assert future.result() == {"key": "value"}
    finally:
        loop.close()


def test_future_multiple_cancellations() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        
        # First cancellation should return True
        assert future.cancel() is True
        
        # Subsequent cancellations should return False
        assert future.cancel() is False
        assert future.cancel() is False
        
        assert future.cancelled()
    finally:
        loop.close()


def test_future_cancel_with_invalid_message() -> None:
    loop = Loop()
    try:
        future = Future(loop=loop)
        
        # Test various invalid message types
        future.cancel(msg=None)
        future.cancel(msg=42)
        future.cancel(msg=["invalid"])
        
        assert future.cancelled()
    finally:
        loop.close()
