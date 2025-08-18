Here is the information you provided, formatted for improved readability and clarity.

---

## **Custom Union Merge Strategy with Logging** 🚀

This feature provides an automated Git merge strategy specifically designed for `changelog.xml` files. It resolves merge conflicts by combining changes from both the current and merging branches, ensuring a clean, conflict-free result while providing detailed logging for traceability.

---

### **Key Features** ✨

* **Custom Merge Strategy:** Merges `changelog.xml` files by combining lines from both branches, preserving order, and automatically eliminating duplicates.
* **Detailed Logging:** Records every merge operation, including a timestamp, commit details, and the new lines that were added. Logs are stored in a dedicated file.
* **Log Rotation:** Prevents the log file from growing indefinitely by limiting its size to 1MB and retaining only the 50 most recent lines.
* **GitHub Actions Integration:** Automatically sets up the custom merge driver for pull requests targeting the `master` branch.

---

### **File Structure** 📂

* `.github/workflows/union-merge.yml`: A GitHub Actions workflow that handles the automatic setup of the merge driver.
* `scripts/merge/strategies/union-merge-strategy.sh`: The core Bash script that implements the custom merge strategy and logging.
* `.gitconfig`: Configures the custom Git merge driver, naming it `customunion`.
* `.gitattributes`: Applies the `customunion` merge strategy to `changelog.xml` and `**/2nd_line_changelog.xml` files.

---

### **Usage and Workflow** ⚙️

The merge strategy is automatically triggered on pull requests that target the `master` branch.

1.  **Merge Process:** The script combines lines from the current (`%A`) and merging (`%B`) versions of the `changelog.xml` file. It then uses `awk` to remove any duplicate lines while preserving the original order. The final, merged content is written back to the file on the current branch.

2.  **Logging:** All merge details are saved to `scripts/merge/strategies/logs/union-merge-strategy.log`. Each log entry includes the timestamp, file paths, the merging branch name and commit hash, and the new lines that were added. The log file is truncated to the last 50 lines if it exceeds 1MB.

---

### **Setup via GitHub Actions** 🛠️

The `union-merge.yml` workflow automates the entire setup process by:
* Checking out the repository.
* Ensuring the merge script is executable.
* Creating a log directory with the necessary write permissions.
* Configuring the `customunion` Git merge driver.
* Verifying that the driver is properly set up.

---

### **Limitations & Debugging** ⚠️

* **Limitations:** This strategy is designed specifically for XML-based changelog files and may not be suitable for other file types.
* **Debugging:**
    * To inspect merge details, check the log file at `scripts/merge/strategies/logs/union-merge-strategy.log`.
    * You can verify the merge driver configuration by running `git config --get-regexp 'merge\.customunion\.*'`.

---

### **License** 📜

This project is licensed under the **MIT License**. For more information, please see the `LICENSE` file.