#!/bin/bash
# Custom Git union merge strategy for changelog files
#
# Arguments from Git:
#   $1 = base   (%O)
#   $2 = current (%A, ours)
#   $3 = other   (%B, theirs)
#
# Behavior:
#   - Merge ours + theirs, removing duplicates
#   - Normalize all entries to uppercase
#   - Ensure version format: CODE-NUMBER[-A..Z]
#   - Keep only the latest version (highest letter) for each CODE-NUMBER
#   - Log the resolution into log/union_merge_strategy_log.log

set -euo pipefail

# --------------------------
# Setup paths
# --------------------------
LOG_DIR="$(git rev-parse --show-toplevel)/log"
LOG_FILE="$LOG_DIR/union_merge_strategy_log.log"

mkdir -p "$LOG_DIR"
TMP_MERGE=$(mktemp)
TMP_FILTERED=$(mktemp)

# --------------------------
# Start logging
# --------------------------
{
  echo "=== Custom union merge ==="
  echo "Timestamp: $(date)"
  echo "Current (%A): $2"
  echo "Other (%B): $3"
} >> "$LOG_FILE"

# --------------------------
# Step 1: merge OURS + THEIRS
# - Convert to uppercase
# - Remove duplicates
# --------------------------
awk '{print toupper($0)}' "$2" "$3" | awk '!seen[$0]++' > "$TMP_MERGE"

# --------------------------
# Step 2: keep only highest version (A..Z)
# --------------------------
awk '
  BEGIN {
    # Explain data structures:
    # latest[key] = latest version letter seen for CODE-NUMBER
    # line_for_key[key] = full line corresponding to that version
    # passthrough[] = lines that don’t match the CODE-NUMBER-VERSION pattern
  }

  # Compare version letters: A < B < C … < Z
  function compare_versions(v1, v2) {
    if (v1 == v2) return 0
    if (v1 < v2)  return -1
    return 1
  }

  # Case 1: line matches CODE-NUMBER[-VERSION]
  match($0, /^((INSV|VSW)-[0-9]+)(-([A-Z]))?$/, arr) {
    code_number = arr[1]                 # INSV-12345
    version     = (arr[4] ? arr[4] : "A") # default version = A if missing

    # If first time we see this key, store it
    if (!(code_number in latest)) {
      latest[code_number]     = version
      line_for_key[code_number] = code_number "-" version
    }
    # If already seen, keep only the highest version
    else if (compare_versions(latest[code_number], version) < 0) {
      latest[code_number]       = version
      line_for_key[code_number] = code_number "-" version
    }

    next
  }

  # Case 2: line does not match the pattern → passthrough
  {
    passthrough[++n] = $0
    next
  }

  END {
    # Print passthrough lines first
    for (i = 1; i <= n; i++) {
      print passthrough[i] >> "'"$TMP_FILTERED"'"
    }

    # Then print only the highest version for each CODE-NUMBER
    for (key in line_for_key) {
      print line_for_key[key] >> "'"$TMP_FILTERED"'"
    }
  }
' "$TMP_MERGE"

# --------------------------
# Step 3: replace merged file with cleaned result
# --------------------------
mv "$TMP_FILTERED" "$2"

# --------------------------
# Step 4: append result to log
# --------------------------
{
  echo "--- Latest merged result ---"
  cat "$2"
  echo "====================="
  echo
} >> "$LOG_FILE"

exit 0