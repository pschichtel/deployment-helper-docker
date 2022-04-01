#!/usr/bin/env sh

md5sum < "${1?no input file}" | cut -d' ' -f1
