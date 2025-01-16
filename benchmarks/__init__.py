from asyncio import AbstractEventLoop
from typing import Callable
import dataclasses

@dataclasses.dataclass
class Benchmark:
	name: str
	function: Callable[[AbstractEventLoop, int], None]

