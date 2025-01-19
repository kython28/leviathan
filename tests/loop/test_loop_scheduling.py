from leviathan import Loop

from contextvars import copy_context
from unittest.mock import MagicMock

import random

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
            <= DELAY_TIME * (calls_num + 2)
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
            <= DELAY_TIME * (calls_num + 2)
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
            <= DELAY_TIME * (calls_num + 2)
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
            <= DELAY_TIME * (calls_num + 2)
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
            <= DELAY_TIME * (calls_num + 2)
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
            <= DELAY_TIME * (calls_num + 2)
        )

        expected_calls = [((i,),) for i in range(calls_num)]
        assert mock_func.call_args_list == expected_calls
    finally:
        loop.close()
