from leviathan import Loop

from typing import Callable
import pytest, os, signal


def test_add_and_remove_signal_handler() -> None:
    loop = Loop()

    try:
        callback_called = False

        def signal_handler() -> None:
            nonlocal callback_called
            callback_called = True
            loop.stop()

        # Add signal handler
        loop.add_signal_handler(signal.SIGUSR1, signal_handler)

        # Schedule sending the signal
        loop.call_later(0.1, os.kill, os.getpid(), signal.SIGUSR1)

        # Run the loop
        loop.run_forever()

        assert callback_called, "Signal handler was not called"

        # Remove signal handler
        loop.remove_signal_handler(signal.SIGUSR1)

        # Try to remove again, should return False
        assert not loop.remove_signal_handler(signal.SIGUSR1), (
            "Removing non-existent handler should return False"
        )

    finally:
        loop.close()


def test_remove_signal_handler_not_registered() -> None:
    loop = Loop()

    try:
        # Try to remove a signal handler that was never added
        assert not loop.remove_signal_handler(signal.SIGUSR2), (
            "Removing non-existent handler should return False"
        )

    finally:
        loop.close()


def test_add_signal_handler_invalid_signal() -> None:
    loop = Loop()

    try:
        with pytest.raises(ValueError):
            loop.add_signal_handler(-1, lambda: None)

    finally:
        loop.close()


def test_multiple_signal_handlers() -> None:
    loop = Loop()

    try:
        handlers_called = set()

        def make_handler(sig: signal.Signals) -> Callable[[], None]:
            def handler() -> None:
                handlers_called.add(sig)
                if len(handlers_called) == 2:
                    loop.stop()

            return handler

        # Add signal handlers
        loop.add_signal_handler(signal.SIGUSR1, make_handler(signal.SIGUSR1))
        loop.add_signal_handler(signal.SIGUSR2, make_handler(signal.SIGUSR2))

        # Schedule sending the signals
        loop.call_later(0.1, os.kill, os.getpid(), signal.SIGUSR1)
        loop.call_later(0.2, os.kill, os.getpid(), signal.SIGUSR2)

        # Run the loop
        loop.run_forever()

        assert handlers_called == {signal.SIGUSR1, signal.SIGUSR2}, (
            "Not all signal handlers were called"
        )

        # Remove signal handlers
        assert loop.remove_signal_handler(signal.SIGUSR1), (
            "Failed to remove SIGUSR1 handler"
        )
        assert loop.remove_signal_handler(signal.SIGUSR2), (
            "Failed to remove SIGUSR2 handler"
        )

    finally:
        loop.close()
