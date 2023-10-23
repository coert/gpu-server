#!/bin/bash
poetry run python3 -c '
import torch
print(f"{torch.__version__=}")
assert torch.cuda.is_available(), f"GPU(s) unavailable for Torch"
print(torch.sum(torch.randn(1000, 1000).cuda()))'