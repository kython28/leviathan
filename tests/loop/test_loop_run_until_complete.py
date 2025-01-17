from leviathan import Loop, ThreadSafeLoop
from typing import Type
import asyncio
import pytest

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_coroutine(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def coro() -> int:
        await asyncio.sleep(0.1)
        return 42

    loop = loop_obj()
    try:
        result = loop.run_until_complete(coro())
        assert result == 42
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_future(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    loop = loop_obj()
    try:
        future = loop.create_future()
        loop.call_soon(future.set_result, "Done")
        result = loop.run_until_complete(future)
        assert result == "Done"
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_task(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def coro() -> str:
        await asyncio.sleep(0.01)
        return "Task completed"

    loop = loop_obj()
    try:
        task = loop.create_task(coro())
        result = loop.run_until_complete(task)
        assert result == "Task completed"
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_exception(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def coro() -> None:
        await asyncio.sleep(0.1)
        raise ValueError("Test exception")

    loop = loop_obj()
    try:
        with pytest.raises(ValueError, match="Test exception"):
            loop.run_until_complete(coro())
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_cancellation(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def coro() -> str|None:
        try:
            await asyncio.sleep(1)
            return None
        except asyncio.CancelledError:
            return "Cancelled"

    loop = loop_obj()
    try:
        task = loop.create_task(coro())
        loop.call_soon(task.cancel)
        result = loop.run_until_complete(task)
        assert result == "Cancelled"
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_nested_coroutines(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def inner_coro() -> str:
        await asyncio.sleep(0.1)
        return "Inner"

    async def outer_coro() -> str:
        result = await inner_coro()
        return f"Outer: {result}"

    loop = loop_obj()
    try:
        result = loop.run_until_complete(outer_coro())
        assert result == "Outer: Inner"
    finally:
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_until_complete_with_multiple_tasks(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    async def coro(x: int) -> int:
        await asyncio.sleep(0.01)
        return x * 2

    async def main() -> list[int]:
        tasks = [coro(i) for i in range(5)]
        results = await asyncio.gather(*tasks)
        return results

    loop = loop_obj()
    try:
        results = loop.run_until_complete(main())
        assert results == [0, 2, 4, 6, 8]
    finally:
        loop.close()

