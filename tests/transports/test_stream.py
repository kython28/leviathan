from leviathan import StreamTransport
import leviathan

import asyncio, socket, os

class EchoProtocol(asyncio.Protocol):
    def __init__(self) -> None:
        loop = asyncio.get_running_loop()

        self.disconnected = loop.create_future()
        self.received = loop.create_future()

        self.pause_writing_fut = loop.create_future()
        self.resume_writing_fut = loop.create_future()

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
