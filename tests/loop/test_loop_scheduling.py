from leviathan import Loop

import contextvars
from contextvars import copy_context
from unittest.mock import MagicMock

import random
import pytest

DELAY_TIME = 0.01


def test_call_soon() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        for i in range(calls_num):
            loop.call_soon(mock_func, i)
        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == calls_num

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_soon_with_cancel() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        for x in range(calls_num):
            h = loop.call_soon(mock_func, x)
            if x % 2 == 0:
                h.cancel()
        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == (calls_num // 2)

        expected_calls = [((i,),) for i in range(calls_num) if i % 2 == 1]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_soon_with_context() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        for i in range(calls_num):
            loop.call_soon(mock_func, i, context=copy_context())
        loop.call_soon(loop.stop)
        loop.run_forever()
        assert mock_func.call_count == calls_num

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_later() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()
        for i in range(calls_num):
            loop.call_later(DELAY_TIME * (i + 1), mock_func, i)

        loop.call_later(DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == calls_num
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_later_with_cancel() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()
        for x in range(calls_num):
            h = loop.call_later(DELAY_TIME * (x + 1), mock_func, x)
            if x % 2 == 0:
                h.cancel()

        loop.call_later(DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == (calls_num // 2)
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num) if i % 2 == 1]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_later_with_context() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()

        for i in range(calls_num):
            loop.call_later(DELAY_TIME * (i + 1), mock_func, i, context=copy_context())

        loop.call_later(DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == calls_num
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_at() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()
        for i in range(calls_num):
            loop.call_at(start_time + DELAY_TIME * (i + 1), mock_func, i)

        loop.call_at(start_time + DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == calls_num
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_at_with_cancel() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()
        for x in range(calls_num):
            h = loop.call_at(start_time + DELAY_TIME * (x + 1), mock_func, x)
            if x % 2 == 0:
                h.cancel()

        loop.call_at(start_time + DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == (calls_num // 2)
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num) if i % 2 == 1]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()


def test_call_at_with_context() -> None:
    loop = Loop()
    try:
        calls_num = random.randint(1, 20)
        mock_func = MagicMock()
        start_time = loop.time()

        for i in range(calls_num):
            loop.call_at(
                start_time + DELAY_TIME * (i + 1), mock_func, i, context=copy_context()
            )

        loop.call_at(start_time + DELAY_TIME * (calls_num + 1), loop.stop)
        loop.run_forever()
        end_time = loop.time()

        assert mock_func.call_count == calls_num
        assert (
            DELAY_TIME * (calls_num + 1)
            <= (end_time - start_time)
            <= (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()

def test_scheduling_invalid_inputs() -> None:
    loop = Loop()
    try:
        # Test call_soon with invalid inputs
        with pytest.raises(TypeError):
            loop.call_soon(None)  # type: ignore

        with pytest.raises(TypeError):
            loop.call_soon("not a callable")  # type: ignore

        # Test call_later with invalid inputs
        with pytest.raises(ValueError):
            loop.call_later(-1, print, "test")  # Negative delay

        with pytest.raises(ValueError):
            loop.call_later(None, print, "test")  # type: ignore

        with pytest.raises(TypeError):
            loop.call_later(DELAY_TIME, None)  # type: ignore

        # Test call_at with invalid inputs
        with pytest.raises(ValueError):
            loop.call_at(None, print, "test")  # type: ignore

        with pytest.raises(TypeError):
            loop.call_at(DELAY_TIME, None)  # type: ignore
    finally:
        loop.close()

def test_scheduling_with_complex_callbacks() -> None:
    loop = Loop()
    try:
        # Test callback with multiple arguments
        def complex_callback(a: int, b: str, c: list[int]) -> None:
            pass

        mock_func = MagicMock(side_effect=complex_callback)
        
        loop.call_soon(mock_func, 1, "test", [1, 2, 3])
        loop.call_later(DELAY_TIME, mock_func, 2, "another", [4, 5])
        loop.call_at(loop.time() + DELAY_TIME, mock_func, 3, "last", [6])

        loop.call_later(DELAY_TIME * 2, loop.stop)
        loop.run_forever()

        assert mock_func.call_count == 3
    finally:
        loop.close()

def test_scheduling_with_exception_raising_callback() -> None:
    loop = Loop()
    try:
        def raising_callback() -> None:
            raise ValueError("Test exception")

        mock_func = MagicMock(side_effect=raising_callback)

        loop.call_soon(mock_func)
        loop.call_later(DELAY_TIME, loop.stop)
        
        loop.run_forever()
    finally:
        loop.close()

def test_scheduling_with_context_propagation() -> None:
    loop = Loop()
    try:
        context_var = contextvars.ContextVar("test_var", default=None)
        context_var.set("initial_value")

        def check_context_callback() -> None:
            assert context_var.get() == "initial_value"

        mock_func = MagicMock(side_effect=check_context_callback)

        # Create a new context with the same value
        context = copy_context()
        context.run(context_var.set, "initial_value")

        loop.call_soon(mock_func, context=context)
        loop.call_later(DELAY_TIME, mock_func, context=context)
        loop.call_at(loop.time() + DELAY_TIME, mock_func, context=context)

        loop.call_later(DELAY_TIME * 2, loop.stop)
        loop.run_forever()

        assert mock_func.call_count == 3
    finally:
        loop.close()

def test_scheduling_with_error_handling() -> None:
    loop = Loop()
    try:
        # Different types of error-raising callbacks
        def value_error_callback() -> None:
            raise ValueError("Test value error")

        def type_error_callback() -> None:
            raise TypeError("Test type error")

        def zero_division_callback() -> None:
            x = 1 / 0  # Raises ZeroDivisionError
            _ = x

        def index_error_callback() -> None:
            lst: list[int] = []
            _ = lst[0]  # Raises IndexError

        # Mocked functions to track callback execution
        mock_value_error = MagicMock(side_effect=value_error_callback)
        mock_type_error = MagicMock(side_effect=type_error_callback)
        mock_zero_division = MagicMock(side_effect=zero_division_callback)
        mock_index_error = MagicMock(side_effect=index_error_callback)

        # Schedule callbacks with various errors
        loop.call_soon(mock_value_error)
        loop.call_later(DELAY_TIME, mock_type_error)
        loop.call_at(loop.time() + DELAY_TIME * 2, mock_zero_division)
        loop.call_soon(mock_index_error)

        # Stop the loop after a reasonable time
        loop.call_later(DELAY_TIME * 3, loop.stop)
        loop.run_forever()

        # Verify that all callbacks were attempted
        assert mock_value_error.call_count == 1
        assert mock_type_error.call_count == 1
        assert mock_zero_division.call_count == 1
        assert mock_index_error.call_count == 1
    finally:
        loop.close()

def test_scheduling_with_mixed_successful_and_error_callbacks() -> None:
    loop = Loop()
    try:
        # Successful callback
        def successful_callback(x: int) -> None:
            assert x > 0

        # Error-raising callbacks
        def error_callback(x: int) -> None:
            if x % 2 == 0:
                raise ValueError(f"Error for even number {x}")

        # Mocked functions
        mock_successful = MagicMock(side_effect=successful_callback)
        mock_error = MagicMock(side_effect=error_callback)

        # Schedule mixed callbacks
        for i in range(1, 6):
            loop.call_soon(mock_successful, i)
            loop.call_later(DELAY_TIME * i, mock_error, i)

        # Stop the loop after a reasonable time
        loop.call_later(DELAY_TIME * 6, loop.stop)
        loop.run_forever()

        # Verify callback execution
        assert mock_successful.call_count == 5
        assert mock_error.call_count == 5
    finally:
        loop.close()
