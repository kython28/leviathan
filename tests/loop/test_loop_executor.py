from concurrent.futures import ThreadPoolExecutor

from leviathan import Loop

import pytest, time


def simple_function(return_value: str) -> str:
    time.sleep(0.01)
    return return_value

def test_run_in_executor_with_specific_executor() -> None:
    loop = Loop()
    executor = ThreadPoolExecutor(max_workers=1)
    try:
        future = loop.run_in_executor(executor, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()

        executor.shutdown(wait=True)

def test_run_in_executor_with_default_executor() -> None:
    loop = Loop()
    try:
        future = loop.run_in_executor(None, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()

def test_set_new_default_executor() -> None:
    loop = Loop()
    try:
        executor = ThreadPoolExecutor(max_workers=1)
        loop.set_default_executor(executor)
        future = loop.run_in_executor(None, simple_function, "test")
        result = loop.run_until_complete(future)
        assert result == "test", "Function did not execute with expected result in specific executor."
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()


def test_set_incorrect_executor() -> None:
    loop = Loop()
    try:
        with pytest.raises(TypeError):
            loop.set_default_executor("No an executor") # type: ignore
    finally:
        loop.close()

def test_run_in_executor_with_invalid_inputs() -> None:
    loop = Loop()
    try:
        # Test with non-callable function
        with pytest.raises(TypeError):
            loop.run_in_executor(None, "not a function")  # type: ignore

        # Test with None function
        with pytest.raises(TypeError):
            loop.run_in_executor(None, None)  # type: ignore

        # Test with invalid executor type
        with pytest.raises(TypeError):
            loop.run_in_executor("not an executor", simple_function, "test")  # type: ignore

    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()

def test_shutdown_default_executor_edge_cases() -> None:
    loop = Loop()
    try:
        # Test multiple shutdowns
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.run_until_complete(loop.shutdown_default_executor())  # Should not raise error

        # Test shutdown with invalid timeout
        with pytest.raises(TypeError):
            loop.run_until_complete(loop.shutdown_default_executor("not a number"))  # type: ignore

        with pytest.raises(ValueError):
            loop.run_until_complete(loop.shutdown_default_executor(-1))

    finally:
        loop.close()

def test_executor_with_multiple_arguments() -> None:
    def multi_arg_function(a: int, b: int, c: str) -> str:
        time.sleep(0.01)
        return f"{a}_{b}_{c}"

    loop = Loop()
    try:
        future = loop.run_in_executor(None, multi_arg_function, 1, 2, "test")
        result = loop.run_until_complete(future)
        assert result == "1_2_test", "Multi-argument function did not execute correctly"
    finally:
        loop.run_until_complete(loop.shutdown_default_executor())
        loop.close()
