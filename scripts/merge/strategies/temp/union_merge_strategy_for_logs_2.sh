#!/bin/bash
# $1 = base (%O)
# $2 = current branch version (%A)
# $3 = other branch version (%B)

LOG_FILE="$(git rev-parse --show-toplevel)/add-line-log.log"

# Merge: combine both versions, sort and remove duplicates
tmpfile=$(mktemp)
cat "$2" "$3" | sort | uniq > "$tmpfile"

# Replace current branch version with merged content
mv "$tmpfile" "$2"

# Append merged result to the log
echo "=== Union Merge Result version 2 ===" >> "$LOG_FILE"
echo "Timestamp: $(date)" >> "$LOG_FILE"
cat "$2" >> "$LOG_FILE"
echo "=========================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
