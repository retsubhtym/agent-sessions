#!/usr/bin/env python3
import sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = f.read()
# Replace all leading 'pick ' with 'reword ' to re-edit messages for commits in range
data = data.replace('pick ', 'reword ')
with open(path, 'w', encoding='utf-8') as f:
    f.write(data)

