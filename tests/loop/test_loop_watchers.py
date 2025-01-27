from leviathan import Loop
import pytest, os

def test_add_and_remove_reader() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_called = False
        def reader_callback() -> None:
            nonlocal callback_called
            callback_called = True
            loop.stop()

        # Add reader
        loop.add_reader(r, reader_callback)

        # Trigger the callback
        loop.call_soon(lambda: os.write(w, b"data"))
        loop.run_forever()

        assert callback_called, "Reader callback was not called"

        # Remove reader
        assert loop.remove_reader(r), "Failed to remove reader"

        # Try to remove again, should return False
        assert not loop.remove_reader(r), "Removing non-existent reader should return False"

    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_add_and_remove_writer() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_called = False
        def writer_callback() -> None:
            nonlocal callback_called
            callback_called = True
            loop.stop()

        # Add writer
        loop.add_writer(w, writer_callback)

        # Run the loop
        loop.call_soon(loop.stop)
        loop.run_forever()

        assert callback_called, "Writer callback was not called"

        # Remove writer
        assert loop.remove_writer(w), "Failed to remove writer"

        # Try to remove again, should return False
        assert not loop.remove_writer(w), "Removing non-existent writer should return False"
    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_add_reader_invalid_fd() -> None:
    loop = Loop()
    try:
        with pytest.raises(ValueError):
            loop.add_reader(-1, lambda: None)
    finally:
        loop.close()

def test_add_writer_invalid_fd() -> None:
    loop = Loop()
    try:
        with pytest.raises(ValueError):
            loop.add_writer(-1, lambda: None)
    finally:
        loop.close()

def test_remove_reader_not_registered() -> None:
    loop = Loop()
    try:
        assert not loop.remove_reader(10), "Removing non-existent reader should return False"
    finally:
        loop.close()

def test_remove_writer_not_registered() -> None:
    loop = Loop()
    try:
        assert not loop.remove_writer(10), "Removing non-existent writer should return False"
    finally:
        loop.close()

def test_rewrite_reader() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_count = 0
        def reader_callback1() -> None:
            nonlocal callback_count
            callback_count += 1
            if callback_count == 1:
                loop.stop()

        def reader_callback2() -> None:
            nonlocal callback_count
            callback_count += 10
            loop.stop()

        # Add first reader
        loop.add_reader(r, reader_callback1)

        # Overwrite with second reader
        loop.add_reader(r, reader_callback2)

        # Trigger the callback
        loop.call_soon(lambda: os.write(w, b"data"))
        loop.run_forever()

        assert callback_count == 10, "Second reader callback was not called"
    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_rewrite_writer() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_count = 0
        def writer_callback1() -> None:
            nonlocal callback_count
            callback_count += 1
            if callback_count == 1:
                loop.stop()

        def writer_callback2() -> None:
            nonlocal callback_count
            callback_count += 10
            loop.stop()

        # Add first writer
        loop.add_writer(w, writer_callback1)

        # Overwrite with second writer
        loop.add_writer(w, writer_callback2)

        # Run the loop
        loop.call_soon(loop.stop)
        loop.run_forever()

        assert callback_count == 10, "Second writer callback was not called"
    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_remove_reader_then_add() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_called = False
        def reader_callback() -> None:
            nonlocal callback_called
            callback_called = True
            loop.stop()

        # Add reader
        loop.add_reader(r, reader_callback)

        # Remove reader
        assert loop.remove_reader(r), "Failed to remove reader"

        # Add reader again
        loop.add_reader(r, reader_callback)

        # Trigger the callback
        loop.call_soon(lambda: os.write(w, b"data"))
        loop.run_forever()

        assert callback_called, "Reader callback was not called after re-adding"
    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_remove_writer_then_add() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        callback_called = False
        def writer_callback() -> None:
            nonlocal callback_called
            callback_called = True
            loop.stop()

        # Add writer
        loop.add_writer(w, writer_callback)

        # Remove writer
        assert loop.remove_writer(w), "Failed to remove writer"

        # Add writer again
        loop.add_writer(w, writer_callback)

        # Run the loop
        loop.call_soon(loop.stop)
        loop.run_forever()

        assert callback_called, "Writer callback was not called after re-adding"
    finally:
        loop.close()
        os.close(w)
        os.close(r)

def test_add_reader_remove_writer() -> None:
    loop = Loop()
    r, w = os.pipe2(os.O_NONBLOCK)
    try:
        def reader_callback() -> None:
            pass

        def writer_callback() -> None:
            pass

        # Add reader and writer
        loop.add_reader(r, reader_callback)
        loop.add_writer(w, writer_callback)

        # Remove writer
        assert loop.remove_writer(w), "Failed to remove writer"

        # Reader should still be present
        assert loop.remove_reader(r), "Reader was unexpectedly removed"
    finally:
        loop.close()
        os.close(w)
        os.close(r)
