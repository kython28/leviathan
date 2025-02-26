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
