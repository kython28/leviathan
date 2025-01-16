from benchmarks import Benchmark
import asyncio
import random
from typing import Dict, Any

BENCHMARK = Benchmark(
    "Food Delivery",
    lambda loop, n: loop.run_until_complete(main(n)),
)

class FoodDeliverySystem:
    def __init__(self) -> None:
        self.restaurants: Dict[str, bool] = {}
        self.orders: Dict[str, dict[str, Any]] = {}
        self.riders: Dict[str, bool] = {}
        self._lock = asyncio.Lock()

    async def handle_event(self, event: Dict[str, Any]) -> None:
        match event.get("type"):
            case "restaurant_open":
                await self.restaurant_open(event["restaurant_id"])
            case "restaurant_closed":
                await self.restaurant_closed(event["restaurant_id"])
            case "new_order":
                await self.new_order(
                    event["order_id"], event["restaurant_id"], event.get("items", [])
                )
            case "assign_rider":
                await self.assign_rider(event["order_id"], event["rider_id"])
            case "order_delivered":
                await self.order_delivered(event["order_id"])
            case "rider_status":
                await self.update_rider_status(event["rider_id"], event["is_available"])

    async def restaurant_open(self, restaurant_id: str) -> None:
        async with self._lock:
            self.restaurants[restaurant_id] = True

    async def restaurant_closed(self, restaurant_id: str) -> None:
        async with self._lock:
            self.restaurants[restaurant_id] = False

    async def new_order(
        self, order_id: str, restaurant_id: str, items: list[dict[str, Any]]
    ) -> None:
        await asyncio.sleep(0.1)
        async with self._lock:
            if not self.restaurants.get(restaurant_id, False):
                return

            self.orders[order_id] = {
                "status": "pending",
                "restaurant": restaurant_id,
                "items": items,
                "rider_assigned": None,
            }

        await self.notify_user(order_id, "Order created and pending assignment.")

    async def assign_rider(self, order_id: str, rider_id: str) -> None:
        await asyncio.sleep(0.1)
        async with self._lock:
            order = self.orders.get(order_id)
            if not order or order["status"] != "pending":
                return

            if not self.riders.get(rider_id, False):
                return

            order["status"] = "in_progress"
            order["rider_assigned"] = rider_id
            self.riders[rider_id] = False

        await asyncio.gather(
            self.notify_user(
                order_id, f"Order in progress. Rider '{rider_id}' assigned."
            ),
            self.log_event("assign_rider", order_id, rider_id)
        )

    async def order_delivered(self, order_id: str) -> None:
        await asyncio.sleep(0.1)
        async with self._lock:
            order = self.orders.get(order_id)
            if not order:
                return

            rider_id = order["rider_assigned"]
            if rider_id:
                self.riders[rider_id] = True
            order["status"] = "delivered"

        await asyncio.gather(
            self.notify_user(order_id, "Order delivered!"),
            self.log_event("order_delivered", order_id, rider_id),
        )

    async def update_rider_status(self, rider_id: str, is_available: bool) -> None:
        async with self._lock:
            self.riders[rider_id] = is_available

    async def notify_user(self, order_id: str, message: str) -> None:
        await asyncio.sleep(0.1)

    async def log_event(self, action: str, order_id: str, rider_id: str) -> None:
        await asyncio.sleep(0.05)


async def generate_events(num_events: int) -> list[dict[str, Any]]:
    event_types = [
        "restaurant_open",
        "restaurant_closed",
        "new_order",
        "assign_rider",
        "order_delivered",
        "rider_status",
    ]
    events: list[dict[str, Any]] = []

    for i in range(num_events):
        event_type = random.choice(event_types)
        if event_type == "restaurant_open":
            events.append({"type": "restaurant_open", "restaurant_id": f"R{i % 5:03}"})
        elif event_type == "restaurant_closed":
            events.append(
                {"type": "restaurant_closed", "restaurant_id": f"R{i % 5:03}"}
            )
        elif event_type == "new_order":
            events.append(
                {
                    "type": "new_order",
                    "order_id": f"O{i:03}",
                    "restaurant_id": f"R{i % 5:03}",
                    "items": ["item1", "item2"],
                }
            )
        elif event_type == "assign_rider":
            events.append(
                {
                    "type": "assign_rider",
                    "order_id": f"O{i % 10:03}",
                    "rider_id": f"RD{i % 3:02}",
                }
            )
        elif event_type == "order_delivered":
            events.append({"type": "order_delivered", "order_id": f"O{i % 10:03}"})
        elif event_type == "rider_status":
            events.append(
                {
                    "type": "rider_status",
                    "rider_id": f"RD{i % 3:02}",
                    "is_available": random.choice([True, False]),
                }
            )

    return events


async def main(orders: int) -> None:
    fds = FoodDeliverySystem()
    events = await generate_events(orders)
    tasks = [fds.handle_event(evt) for evt in events]
    await asyncio.gather(*tasks)

