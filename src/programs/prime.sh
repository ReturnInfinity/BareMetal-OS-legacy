#!/bin/bash

T1=$(date +%s)
./prime
T2=$(date +%s)
echo "Elapsed: $(( T2 - T1 ))"
