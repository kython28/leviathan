from leviathan.loop import Loop, ThreadSafeLoop
from leviathan.runner import run

from typing import Type
import pytest, asyncio


@pytest.mark.parametrize("thread_safe, expected_loop", [
    (False, Loop),
    (True, ThreadSafeLoop),
])
def test_run(thread_safe: bool, expected_loop: Type[asyncio.AbstractEventLoop]) -> None:
    async def test_coro(expected_loop: Type[asyncio.AbstractEventLoop]) -> tuple[str, bool]:
        return "test result", isinstance(asyncio.get_running_loop(), expected_loop)

    result = run(test_coro(expected_loop), thread_safe=thread_safe)

    assert isinstance(result, tuple)
    assert len(result) == 2

    assert result[0] == "test result"
    assert result[1]
