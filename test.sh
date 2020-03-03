#!/bin/bash
./build/bin/fluent-bit -i dummy -F lua -p script=./filter.lua -p call=do_filter -m '*' -o null

