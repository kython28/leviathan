from typing import Callable, List, Tuple, Dict, TypedDict
from prettytable import PrettyTable
from benchmarks import Benchmark

import dataclasses
import uvloop, asyncio, time, leviathan
import matplotlib.pyplot as plt
import sys, os, statistics
import matplotlib
import statistics

from benchmarks import (
    event_fiesta_factory,
    producer_consumer,
    food_delivery,
    task_workflow,
    chat,
)

BENCHMARKS: List[Benchmark] = [
    event_fiesta_factory.BENCHMARK,
    producer_consumer.BENCHMARK,
    food_delivery.BENCHMARK,
    task_workflow.BENCHMARK,
    chat.BENCHMARK,
]

matplotlib.use("QtAgg")

try:
    os.nice(-20)
except IOError as e:
    print(
        f"({e}):",
        "Couldn't set nice, running with default level",
        file=sys.stderr,
    )

N: int = 11
ITERATIONS = 5

M_INITIAL: int = 1024
M_MULTIPLIER: int = 2

LOOPS: List[Tuple[str, Callable[[], asyncio.AbstractEventLoop]]] = [
    ("asyncio", asyncio.new_event_loop),
    ("uvloop", uvloop.new_event_loop),
    ("leviathan", leviathan.Loop),
    ("leviathan (Thread-safe)", leviathan.ThreadSafeLoop),
]

@dataclasses.dataclass
class TimeMetrics:
    min: float
    max: float
    avg: float
    stdev: float
    
    dict = dataclasses.asdict
    
    def __init__(self, times: List[float]):
        self.min = min(times)
        self.max = max(times)
        self.avg, self.stdev = statistics._mean_stdev(
            times
        )

def benchmark_with_event_loops(
    loops: List[Tuple[str, Callable[[], asyncio.AbstractEventLoop]]],
    function: Callable[[asyncio.AbstractEventLoop, int], None],
) -> Dict[str, List[Tuple[int, TimeMetrics]]]:
    results: Dict[str, List[Tuple[int, TimeMetrics]]] = {}
    for loop_name, loop_creator in loops:
        results[loop_name] = []
        m: int = M_INITIAL

        print("Starting benchmark with loop:", loop_name)
        loop = loop_creator()
        try:
            while m <= M_INITIAL * (2 ** (N - 1)):
                times: list[float] = []
                for _ in range(ITERATIONS):
                    start: float = time.perf_counter()
                    function(loop, m)
                    end: float = time.perf_counter()
                    times.append(end - start)
                metrics = TimeMetrics(times)
                print(" - ".join((
                    loop_name,
                    str(m),
                    ", ".join(
                        f"{key}: {value:.6f} s"
                        for key, value
                        in metrics.dict().items()
                    )
                )))
                results[loop_name].append((m, metrics))
                m *= M_MULTIPLIER
        finally:
            loop.run_until_complete(loop.shutdown_asyncgens())
            loop.close()

        print("-" * 50)

    return results


def create_comparison_table(
    results: Dict[str, List[Tuple[int, TimeMetrics]]],
) -> None:
    table: PrettyTable = PrettyTable()
    table.field_names = [
        "Loop",
        "M",
        *(
            f"{field.capitalize()} (s)"
            for field in TimeMetrics.__annotations__
        ),
        "Diff (s)",
        "Relative Speed",
    ]

    base_loop_results = results["asyncio"]
    for loop_name, loop_results in results.items():
        for i, (m, time) in enumerate(loop_results):
            base_time: float = base_loop_results[i][1].avg
            relative_time: float = base_time / time.avg
            diff = time.avg - base_time
            table.add_row([
                loop_name,
                m,
                *[
                    f"{value:.6f}"
                    for value
                    in list(time.dict().values()) + [diff, relative_time]
                ],
            ])

    print(table)


def plot_results(
    results: Dict[str, List[Tuple[int, TimeMetrics]]],
    name: str
) -> None:
    plt.figure(figsize=(10, 6))

    for loop_name, loop_results in results.items():
        x: List[int] = [m for m, _ in loop_results]
        y: List[float] = [time.avg for _, time in loop_results]
        lows: List[float] = [time.avg - time.min for _, time in loop_results]
        highs: List[float] = [time.max - time.avg for _, time in loop_results]
        # stdevs: List[float] = [time.stdev for _, time in loop_results]
        # plt.errorbar(x, y, stdevs, marker="o")
        plt.errorbar(x, y, [lows, highs], marker="o", label=loop_name, capsize=5)

    plt.xscale("log", base=2)
    plt.yscale("log")
    plt.xlabel("M (log scale)")
    plt.ylabel("Time (s, log scale)")
    plt.title(f"Benchmark Comparison Across Event Loops ({name}. Less is better)")
    plt.legend()
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    for benchmark in BENCHMARKS:
        print("Starting test for function:", benchmark.name)
        benchmark_results = benchmark_with_event_loops(
            LOOPS,
            benchmark.function
        )
        create_comparison_table(benchmark_results)
        plot_results(benchmark_results, benchmark.name)
        print("-" * 50)
        print()
