#!/usr/bin/env bash
pgrep -f geth         | xargs -r kill -9
pgrep -f op-node | xargs -r kill -9
pgrep -f op-batcher    | xargs -r kill -9
pgrep -f op-proposer    | xargs -r kill -9
