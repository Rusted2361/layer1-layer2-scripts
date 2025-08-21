#!/usr/bin/env bash
pgrep -f geth         | xargs -r kill -9
pgrep -f beacon-chain | xargs -r kill -9
pgrep -f validator    | xargs -r kill -9