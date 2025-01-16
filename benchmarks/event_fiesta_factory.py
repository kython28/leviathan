from benchmarks import Benchmark
import asyncio
import random
from typing import Dict, Any

BENCHMARK = Benchmark(
    "Event fiesta factory",
    lambda loop, n: loop.run_until_complete(main(n)),
)

registered_users = {}
order_history = {}
data_store = {}

lock_users = asyncio.Lock()
lock_orders = asyncio.Lock()
lock_data = asyncio.Lock()


async def handle_user_signup(event_data: dict[str, Any]) -> None:
    user_id = event_data["user_id"]
    user_email = event_data["email"]

    async with lock_users:
        registered_users[user_id] = {"email": user_email, "status": "registered"}

    asyncio.create_task(notify_signup(user_id, user_email))
    asyncio.create_task(log_action("signup", user_id))


async def notify_signup(user_id: str, user_email: str) -> None:
    return


async def log_action(action: str, target_id: str) -> None:
    return


async def handle_order_placement(event_data: dict[str, Any]) -> None:
    order_id = event_data["order_id"]
    user_id = event_data["user_id"]
    items = event_data.get("items", [])

    if user_id not in registered_users:
        return

    order_history[order_id] = {
        "user_id": user_id,
        "items": items,
        "status": "processing",
    }

    asyncio.create_task(update_order_status(order_id, "completed"))
    asyncio.create_task(log_action("order_placed", order_id))


async def update_order_status(order_id: str, new_status: str) -> None:
    if order_id in order_history:
        order_history[order_id]["status"] = new_status


async def handle_data_processing(event_data: dict[str, Any]) -> None:
    data_id = event_data["data_id"]
    payload = event_data.get("payload", [])

    transformed = [str(x).upper() for x in payload]
    data_store[data_id] = transformed
    asyncio.create_task(log_action("data_processed", data_id))


async def process_event(event: Dict[str, Any]) -> None:
    match event.get("type"):
        case "user_signup":
            await handle_user_signup(event)
        case "order_placement":
            await handle_order_placement(event)
        case "data_processing":
            await handle_data_processing(event)


async def event_loop_simulator(events: list[dict[str, Any]]) -> None:
    tasks = [asyncio.create_task(process_event(evt)) for evt in events]
    await asyncio.gather(*tasks)


def generate_events(num_events: int) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    events_per_type = num_events // 3
    for i in range(events_per_type):
        events.append(
            {
                "type": "user_signup",
                "user_id": f"U{i:03}",
                "email": f"user{i}@example.com",
            }
        )
        events.append(
            {
                "type": "order_placement",
                "order_id": f"O{i:03}",
                "user_id": f"U{i % 10:03}",
                "items": [f"item{i}"],
            }
        )
        events.append(
            {
                "type": "data_processing",
                "data_id": f"D{i:03}",
                "payload": [random.randint(1, 100), "data", f"payload{i}"],
            }
        )

    return events


async def main(nevents: int) -> None:
    events = generate_events(nevents)
    await event_loop_simulator(events)

