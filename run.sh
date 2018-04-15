#!/bin/sh -e

for PAGE in {1..10}; do
  export PAGE
  ./update.sh
done
