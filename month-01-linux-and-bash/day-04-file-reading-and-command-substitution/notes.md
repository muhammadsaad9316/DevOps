# Day 04 Notes: Text Inspection Tools & Vim Survival

## 🔍 Text Viewing Comparison

| Utility | Best Used For | Memory Behavior | Key Shortcuts |
|---|---|---|---|
| `cat` | Short files (< 30 lines) or concatenating files. | Dumps entire file into buffer at once. | None (prints directly to stdout). |
| `less` | Long files (logs, large configs). | Pages file on demand (lightweight, doesn't load whole file). | `Space` / `b` (page forward/back), `/search` (find), `n` (next), `q` (quit). |
| `head` | Inspecting header lines or beginnings of files. | Reads first $N$ lines (default 10). | `head -n 20 file.txt` |
| `tail` | Inspecting recent entries at end of file. | Reads last $N$ lines (default 10). | `tail -n 20 file.txt` |
| `tail -f` | Real-time live log monitoring. | Keeps file descriptor open; prints new lines appended. | `Ctrl + C` to stop. |
| `wc` | Metric analysis on text files. | Counts lines (`-l`), words (`-w`), bytes (`-c`). | `wc -l /etc/passwd` |

---

## 🛑 Vim Survival Cheat Sheet

```text
               +-----------------------------+
               |        NORMAL MODE          |
               |  (Press ESC to return here) |
               +--------------+--------------+
                              |
                i (Insert)    |    : (Command)
                              v
    +-------------------------+-------------------------+
    |       INSERT MODE       |      COMMAND MODE       |
    |   Type text normally    |   :w   (save)           |
    |                         |   :q   (quit)           |
    |                         |   :wq  (save and quit)  |
    |                         |   :q!  (force quit)     |
    +-------------------------+-------------------------+
```
