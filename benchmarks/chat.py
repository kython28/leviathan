from benchmarks import Benchmark
import asyncio
import random
from typing import Dict, List, Any

BENCHMARK = Benchmark(
    "Chat",
    lambda loop, n: loop.run_until_complete(main(n)),
)

class ChatServer:
    def __init__(self) -> None:
        self.users: Dict[str, bool] = {}
        self.message_log: List[str] = []
        self._lock = asyncio.Lock()

    async def handle_event(self, event: dict[str, Any]) -> None:
        match event.get("type"):
            case "login":
                await self.login_user(event["username"])
            case "message":
                await self.broadcast_message(event["username"], event["content"])
            case "logout":
                await self.logout_user(event["username"])

    async def login_user(self, username: str) -> None:
        async with self._lock:
            self.users[username] = True

    async def logout_user(self, username: str) -> None:
        async with self._lock:
            if username in self.users and self.users[username]:
                self.users[username] = False

    async def broadcast_message(self, username: str, content: str) -> None:
        await asyncio.sleep(random.uniform(0.05, 0.1))
        async with self._lock:
            msg = f"{username}: {content}"
            self.message_log.append(msg)

async def simulate_user_life(server: ChatServer, username: str) -> None:
    await server.handle_event({"type": "login", "username": username})
    num_messages = random.randint(2, 5)
    for i in range(num_messages):
        await asyncio.sleep(0.1)
        content = f"Hello, i am {username}, message {i+1}"
        await server.handle_event({"type": "message", "username": username, "content": content})
    await asyncio.sleep(0.3)
    await server.handle_event({"type": "logout", "username": username})

async def main(nusers: int) -> None:
    server = ChatServer()
    user_list = [f"user{i}" for i in range(nusers)]
    tasks = [asyncio.create_task(simulate_user_life(server, user)) for user in user_list]
    await asyncio.gather(*tasks)

