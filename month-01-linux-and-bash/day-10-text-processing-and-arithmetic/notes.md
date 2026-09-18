# Text Processing Utilities Reference

## 🧰 Command Toolbox

| Tool | Core Strength | Example | Output |
|---|---|---|---|
| `cut` | Extracts columns delimited by a character. | `cut -d: -f1 /etc/passwd` | List of all system usernames |
| `tr` | Translates or deletes single characters. | `echo "devops" \| tr '[:lower:]' '[:upper:]'` | `DEVOPS` |
| `sort` | Orders lines alphabetically or numerically. | `sort -n` (numeric), `sort -r` (reverse) | Ordered list |
| `uniq` | Filters or counts adjacent duplicate lines. | `sort names.txt \| uniq -c` | Frequency count per name |
| `awk` | Field-based column processor and pattern engine. | `awk -F: '{print $1, $3}' /etc/passwd` | Username and UID |
| `sed` | Stream editor for filtering and transforming text. | `sed -i 's/DEBUG=True/DEBUG=False/g' config.py` | In-place file update |

---

## ⚠️ Why Does `uniq` Require Sorted Input?
`uniq` only compares **adjacent lines** as the stream passes through memory. If duplicate occurrences are separated by other lines, `uniq` cannot detect them. Hence, the universal pipeline idiom:
```bash
cat data.txt | sort | uniq
```

---

## 🏆 The Top 10 History Pipeline
```bash
history | awk '{print $2}' | sort | uniq -c | sort -nr | head -n 10
```
- `awk '{print $2}'`: Extracts the primary command name, ignoring the command history number.
- `sort`: Groups identical command names consecutively.
- `uniq -c`: Counts occurrences of each distinct command.
- `sort -nr`: Sorts numerically (`-n`) in descending/reverse (`-r`) order.
- `head -n 10`: Limits output to the top 10 most frequent commands.
