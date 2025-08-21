#!/bin/bash

kill -9 $(ps aux | grep geth | grep -v grep | awk '{print $2}')
kill -9 $(ps aux | grep beacon-chain | grep -v grep | awk '{print $2}')
kill -9 $(ps aux | grep validator | grep -v grep | awk '{print $2}')