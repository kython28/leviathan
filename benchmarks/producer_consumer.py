from benchmarks import Benchmark
from typing import List, Awaitable
import random, asyncio

BENCHMARK = Benchmark(
    "Producer-Consumer",
    lambda loop, n: loop.run_until_complete(
        execute_producers(n)
    ),
)

async def producer(producer_id: int) -> str:
    loop = asyncio.get_event_loop()
    fut = loop.create_future()
    asyncio.create_task(consumer(fut, producer_id))
    result = await fut
    await asyncio.sleep(0.05)
    return result

async def consumer(fut: asyncio.Future[str], producer_id: int) -> None:
    delay = 0.3
    await asyncio.sleep(delay)
    random_value = round(random.random(), 3)
    fut.set_result(f"Value {random_value} after {delay:.2f}s (prod {producer_id})")

async def execute_producers(num_producers: int) -> None:
    tasks: List[Awaitable[str]] = [producer(i) for i in range(num_producers)]
    await asyncio.gather(*tasks)

