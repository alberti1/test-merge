#!/bin/bash
# ===================================================================
# Custom Union Merge Strategy Script
# ===================================================================
# This script resolves merge conflicts for changelog.xml files by
# keeping both the current (%A) and other (%B) changes, preserving
# the line order, and removing duplicate lines.
#
# It also logs all merge actions to a dedicated log file.
#
# Parameters:
#   $1 = base version (%O)  -> common ancestor
#   $2 = current version (%A) -> current branch
#   $3 = other version (%B)   -> merging branch
# ===================================================================

# Determine the log file location (relative to the repository root)
LOG_FILE="$(git rev-parse --show-toplevel)/scripts/merge/strategies/logs/union-merge-strategy.log"

# Create a temporary file to store the merged result
TMPFILE=$(mktemp)

# ---------------------- Log Rotation -----------------------------
# Check if the log file exists and has more than 1MB.
# If so, keep only the last 50 lines. This is a more efficient
# way to prevent the log from growing indefinitely than counting lines.
MAX_SIZE_BYTES=1048576 # 1 MB in bytes

if [[ -f "$LOG_FILE" ]]; then
    # Use 'stat -f %z' to get the file size in bytes (macOS).
    file_size=$(stat -f %z "$LOG_FILE")
    # If the file size is greater than the limit, truncate it.
    if [[ "$file_size" -gt "$MAX_SIZE_BYTES" ]]; then
        # Use 'tail' to keep the last 50 lines to preserve recent history.
        tail -n 50 "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

# ---------------------- Get Commit Information ------------------------
# Get the hash and name of the commit being merged (from MERGE_HEAD).
# This is more reliable than trying to parse the branch name from the file paths.
OTHER_HASH=$(git rev-parse MERGE_HEAD)
OTHER_NAME=$(git log -1 --pretty=format:%s MERGE_HEAD)
OTHER_BRANCH=$(git rev-parse --abbrev-ref MERGE_HEAD)

# ---------------------- Logging Information ------------------------
echo "==============================================================" >> "$LOG_FILE"
echo "             CUSTOM UNION MERGE STRATEGY" >> "$LOG_FILE"
echo "Timestamp: $(date)" >> "$LOG_FILE"
echo "Base Version (%O): $1" >> "$LOG_FILE"
echo "Current Version (%A): $2" >> "$LOG_FILE"
echo "Other Version (%B): $3" >> "$LOG_FILE"
echo "Other Branch Name: $OTHER_BRANCH" >> "$LOG_FILE"
echo "Other Commit Hash: $OTHER_HASH" >> "$LOG_FILE"
echo "Other Commit Name: $OTHER_NAME" >> "$LOG_FILE"
echo "--------------------------------------------------------------" >> "$LOG_FILE"

# ---------------------- Merge Operation ---------------------------
# Combine lines from current and other versions.
# Preserve order and remove duplicates using awk.
# The `cat` command combines the current and other versions first,
# then `awk` removes duplicate lines and sends the output to a temporary file.
cat "$2" "$3" | awk '!seen[$0]++' > "$TMPFILE"

# ---------------------- Log the Merged Result ---------------------
echo "Merged Result (new lines added):" >> "$LOG_FILE"
echo "--------------------------------------------------------------" >> "$LOG_FILE"

# Compare the old file with the newly merged file to find only the added lines.
# Use 'diff' to compare the original file ($2) with the merged output ($TMPFILE).
# The 'grep' command then filters for lines that were added (prefixed with '> ').
# The 'sed' command removes the prefix, leaving only the added line.
diff "$2" "$TMPFILE" | grep '^> ' | sed 's/^> //g' >> "$LOG_FILE"

# Overwrite the current branch version with the merged result
mv "$TMPFILE" "$2"

echo "==============================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Exit successfully
exit 0