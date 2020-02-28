#!/bin/bash
./build/bin/fluent-bit -i dummy -F lua -p script=./conf/test.lua -p call=cb_print -m '*' -o null

