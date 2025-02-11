from leviathan import StreamTransport
import leviathan

import asyncio, socket, os
from typing import Any

class BufferedEchoProtocol(asyncio.BufferedProtocol):
    def __init__(self) -> None:
        loop = asyncio.get_running_loop()
        
        self.disconnected = loop.create_future()
        self.received = loop.create_future()
        self.buffer: bytearray|None = None
        
        self.pause_writing_fut = loop.create_future()
        self.resume_writing_fut = loop.create_future()
        self.eof_received_fut = loop.create_future()
        
        self.error: BaseException|None = None

    def get_buffer(self, sizehint: int) -> bytearray:
        self.buffer = bytearray(sizehint)
        return self.buffer

    def buffer_updated(self, nbytes: int) -> None:
        if self.buffer is not None:
            data = bytes(self.buffer[:nbytes])
            self.received.set_result(data)
            
            loop = asyncio.get_running_loop()
            self.received = loop.create_future()
            self.buffer = None

    def connection_lost(self, exc: BaseException|None) -> None:
        self.error = exc
        
        self.received.cancel()
        self.resume_writing_fut.cancel()
        self.pause_writing_fut.cancel()
        
        self.disconnected.set_result(None)

    def eof_received(self) -> bool | None:
        self.eof_received_fut.set_result(None)
        
        loop = asyncio.get_running_loop()
        self.eof_received_fut = loop.create_future()
        
        return None

    def pause_writing(self) -> None:
        self.pause_writing_fut.set_result(None)
        
        loop = asyncio.get_running_loop()
        self.pause_writing_fut = loop.create_future()

    def resume_writing(self) -> None:
        self.resume_writing_fut.set_result(None)
        
        loop = asyncio.get_running_loop()
        self.resume_writing_fut = loop.create_future()

class EchoProtocol(asyncio.Protocol):
    def __init__(self) -> None:
        loop = asyncio.get_running_loop()

        self.disconnected = loop.create_future()
        self.received = loop.create_future()

        self.pause_writing_fut = loop.create_future()
        self.resume_writing_fut = loop.create_future()
        self.eof_received_fut = loop.create_future()

        self.error: BaseException|None = None

    # def connection_made(self, transport):
    #     self.transport = transport
    #     self.connected.set_result(None)

    def data_received(self, data: bytes) -> None:
        self.received.set_result(data)

        loop = asyncio.get_running_loop()
        self.received = loop.create_future()

    def connection_lost(self, exc: BaseException|None) -> None:
        self.error = exc

        self.received.cancel()
        self.resume_writing_fut.cancel()
        self.pause_writing_fut.cancel()

        self.disconnected.set_result(None)

    def eof_received(self) -> bool | None:
        self.eof_received_fut.set_result(None)

        loop = asyncio.get_running_loop()
        self.eof_received_fut = loop.create_future()

        return None

    def pause_writing(self) -> None:
        self.pause_writing_fut.set_result(None)

        loop = asyncio.get_running_loop()
        self.pause_writing_fut = loop.create_future()

    def resume_writing(self) -> None:
        self.resume_writing_fut.set_result(None)
    
        loop = asyncio.get_running_loop()
        self.resume_writing_fut = loop.create_future()

async def _test_stream_transport_basics() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    try:
        # Test writing data
        test_data = b"Hello, World!"
        server_transport.write(test_data)
        
        # Wait for data to be received and echoed back
        received_data = await client_protocol.received
        assert received_data == test_data

        test_data2 = b"Thanks!!"
        client_transport.write(test_data2)
        
        received_data = await server_protocol.received
        assert received_data == test_data2
        
        # Close transport and wait for disconnection
        server_transport.close()
        await server_protocol.disconnected
        assert server_protocol.error is None  # Normal close
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_basics() -> None:
    leviathan.run(_test_stream_transport_basics())

async def _test_stream_transport_multiple_writes() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Test multiple writes from server to client
        messages = [b"Hello", b"World", b"Testing", b"Multiple", b"Writes"]
        
        for msg in messages:
            server_transport.write(msg)
            received = await client_protocol.received
            assert received == msg
            
        # Test multiple writes from client to server
        responses = [b"Response1", b"Response2", b"Response3", b"Final"]
        for msg in responses:
            client_transport.write(msg)
            received = await server_protocol.received
            assert received == msg
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_multiple_writes() -> None:
    leviathan.run(_test_stream_transport_multiple_writes())

async def _test_stream_transport_large_writes() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Test large write from server to client (1MB)
        large_data = os.urandom(1024 * 1024)  # 1MB of data
        server_transport.write(large_data)

        response = b""
        while len(response) < len(large_data):
            received = await asyncio.wait_for(client_protocol.received, 100)
            response += received

        assert response == large_data
        
        # Test large write from client to server (2MB)
        large_response = os.urandom(2 * 1024 * 1024)  # 2MB of data
        client_transport.write(large_response)

        response = b""
        while len(response) < len(large_response):
            received = await asyncio.wait_for(server_protocol.received, 1)
            response += received

        assert response == large_response
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_large_writes() -> None:
    leviathan.run(_test_stream_transport_large_writes())

async def _test_stream_transport_watermarks() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport with custom watermarks
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        server_transport.set_write_buffer_limits(10, 10)
        # Test writing data slightly below high watermark
        received_fut = client_protocol.received
        pause_writing = client_protocol.pause_writing_fut

        data_below = os.urandom(5) 
        server_transport.write(data_below)

        await asyncio.wait_for(received_fut, 1)
        assert not pause_writing.done()

        received_fut = client_protocol.received
        pause_writing = server_protocol.pause_writing_fut
        resume_writing = server_protocol.resume_writing_fut

        data_above = os.urandom(15)
        server_transport.write(data_above)

        await asyncio.wait_for(pause_writing, 1)
        await asyncio.wait_for(resume_writing, 1)
        await asyncio.wait_for(received_fut, 1)
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_watermarks() -> None:
    leviathan.run(_test_stream_transport_watermarks())

async def _test_stream_transport_eof() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Test EOF handling
        test_data = b"Last message before EOF"
        server_transport.write(test_data)
        
        # Wait for data to be received
        received_data = await asyncio.wait_for(client_protocol.received, 1)
        assert received_data == test_data

        # Close write end of the server socket to trigger EOF
        server_transport.write_eof()
        
        # Wait for EOF to be received by client
        await asyncio.wait_for(client_protocol.eof_received_fut, 1)
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_eof() -> None:
    leviathan.run(_test_stream_transport_eof())

async def _test_stream_transport_eof_with_pending_writes() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport with small buffer to ensure writes are pending
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        client_eof_fut = client_protocol.eof_received_fut

        # Write first two chunks of data
        data1 = b"First chunk of data"
        server_transport.write(data1)
        
        data2 = b"Second chunk of data"
        server_transport.write(data2)
        
        # Try to write EOF while writes are pending
        server_transport.write_eof()
        
        # Write third chunk of data after EOF
        data3 = b"Third chunk after attempted EOF"
        server_transport.write(data3)
        
        await asyncio.sleep(0.1)
        assert not client_eof_fut.done()
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_eof_with_pending_writes() -> None:
    leviathan.run(_test_stream_transport_eof_with_pending_writes())

async def _test_buffered_protocol_basics() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = BufferedEchoProtocol()
    client_protocol = BufferedEchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Test writing data
        test_data = b"Hello, Buffered World!"
        server_transport.write(test_data)
        
        # Wait for data to be received
        received_data = await client_protocol.received
        assert received_data == test_data

        # Test response
        response_data = b"Buffered Response!"
        client_transport.write(response_data)
        
        received_data = await server_protocol.received
        assert received_data == response_data
        
    finally:
        server_transport.close()
        client_transport.close()

def test_buffered_protocol_basics() -> None:
    leviathan.run(_test_buffered_protocol_basics())

async def _test_stream_transport_writelines() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Test writelines with a list of bytes
        messages = [b"First Line\n", b"Second Line\n", b"Third Line\n"]
        server_transport.writelines(messages)
        
        # Verify each line is received correctly
        total_length = sum(map(len, messages))
        data_received = b""
        while len(data_received) < total_length:
            received = await client_protocol.received
            data_received += received

        assert len(data_received) == total_length
        assert data_received.decode() == "".join(x.decode() for x in messages)
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_writelines() -> None:
    leviathan.run(_test_stream_transport_writelines())

async def _test_stream_transport_abort() -> None:
    loop = asyncio.get_running_loop()
    server_socket, client_socket = socket.socketpair()

    server_socket.setblocking(False)
    client_socket.setblocking(False)
    
    server_protocol = EchoProtocol()
    client_protocol = EchoProtocol()
    
    # Create transport
    server_transport = StreamTransport(server_socket.fileno(), server_protocol, loop)
    client_transport = StreamTransport(client_socket.fileno(), client_protocol, loop)
    
    try:
        # Send some data before abort
        test_data = b"Data before abort"
        server_transport.write(test_data)
        
        # Wait for data to be received
        received_data = await asyncio.wait_for(client_protocol.received, 1)
        assert received_data == test_data

        # Abort the server transport
        server_transport.abort()
        
        # Wait for disconnection and verify error
        await asyncio.wait_for(server_protocol.disconnected, 1)
        assert server_protocol.error is None
        
        # Try to write after abort - should not raise but data won't be sent
        server_transport.write(b"Data after abort")
        
        # Client should detect the connection was lost
        await asyncio.wait_for(client_protocol.disconnected, 1)
        assert isinstance(client_protocol.error, ConnectionResetError)
        
    finally:
        server_transport.close()
        client_transport.close()

def test_stream_transport_abort() -> None:
    leviathan.run(_test_stream_transport_abort())
