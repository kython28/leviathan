from concurrent.futures import ThreadPoolExecutor

from leviathan import Loop, ThreadSafeLoop

from typing import Type

import asyncio, pytest, time


def simple_function(return_value: str) -> str:
    time.sleep(0.01)
    return return_value

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_in_executor_with_specific_executor(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    loop = loop_obj()
    executor = ThreadPoolExecutor(max_workers=1)
    try:
        future = loop.run_in_executor(executor, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()

        executor.shutdown(wait=True)

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_run_in_executor_with_default_executor(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    loop = loop_obj()
    try:
        future = loop.run_in_executor(None, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()

@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_set_new_default_executor(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    loop = loop_obj()
    try:
        executor = ThreadPoolExecutor(max_workers=1)
        loop.set_default_executor(executor)
        future = loop.run_in_executor(None, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()


@pytest.mark.parametrize("loop_obj", [Loop, ThreadSafeLoop])
def test_set_incorrect_executor(loop_obj: Type[asyncio.AbstractEventLoop]) -> None:
    loop = loop_obj()
    try:
        with pytest.raises(TypeError):
            loop.set_default_executor("No an executor") # type: ignore
    finally:
        loop.close()
