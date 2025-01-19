from leviathan import Loop
import asyncio
import pytest


def test_run_until_complete_with_coroutine() -> None:
    async def coro() -> int:
        await asyncio.sleep(0.1)
        return 42

    loop = Loop()
    try:
        result = loop.run_until_complete(coro())
        assert result == 42
    finally:
        loop.close()


def test_run_until_complete_with_future() -> None:
    loop = Loop()
    try:
        future = loop.create_future()
        loop.call_soon(future.set_result, "Done")
        result = loop.run_until_complete(future)
        assert result == "Done"
    finally:
        loop.close()


def test_run_until_complete_with_task() -> None:
    async def coro() -> str:
        await asyncio.sleep(0.01)
        return "Task completed"

    loop = Loop()
    try:
        task = loop.create_task(coro())
        result = loop.run_until_complete(task)
        assert result == "Task completed"
    finally:
        loop.close()


def test_run_until_complete_with_exception() -> None:
    async def coro() -> None:
        await asyncio.sleep(0.1)
        raise ValueError("Test exception")

    loop = Loop()
    try:
        with pytest.raises(ValueError, match="Test exception"):
            loop.run_until_complete(coro())
    finally:
        loop.close()


def test_run_until_complete_with_cancellation() -> None:
    async def coro() -> str | None:
        try:
            await asyncio.sleep(1)
            return None
        except asyncio.CancelledError:
            return "Cancelled"

    loop = Loop()
    try:
        task = loop.create_task(coro())
        loop.call_soon(task.cancel)
        result = loop.run_until_complete(task)
        assert result == "Cancelled"
    finally:
        loop.close()


def test_run_until_complete_with_nested_coroutines() -> None:
    async def inner_coro() -> str:
        await asyncio.sleep(0.1)
        return "Inner"

    async def outer_coro() -> str:
        result = await inner_coro()
        return f"Outer: {result}"

    loop = Loop()
    try:
        result = loop.run_until_complete(outer_coro())
        assert result == "Outer: Inner"
    finally:
        loop.close()


def test_run_until_complete_with_multiple_tasks() -> None:
    async def coro(x: int) -> int:
        await asyncio.sleep(0.01)
        return x * 2

    async def main() -> list[int]:
        tasks = [coro(i) for i in range(5)]
        results = await asyncio.gather(*tasks)
        return results

    loop = Loop()
    try:
        results = loop.run_until_complete(main())
        assert results == [0, 2, 4, 6, 8]
    finally:
        loop.close()
