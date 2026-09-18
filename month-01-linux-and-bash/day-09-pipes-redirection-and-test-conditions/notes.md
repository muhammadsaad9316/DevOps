# Standard Streams & I/O Redirection Architecture

## 🔌 Standard File Descriptors

Every process started in Linux automatically inherits three standard file descriptors:

| Descriptor | Name | Default Device | Redirection Operator |
|:---:|---|---|---|
| **`0`** | `stdin` (Standard Input) | Keyboard | `<` (read from file) |
| **`1`** | `stdout` (Standard Output) | Terminal Screen | `>`, `>>` |
| **`2`** | `stderr` (Standard Error) | Terminal Screen | `2>`, `2>>` |

---

## 🔄 Redirection Operators

```bash
# 1. Overwrite stdout
echo "version 1.0" > app.log

# 2. Append to stdout
echo "version 1.1" >> app.log

# 3. Redirect stderr only
ls /nonexistent 2> errors.log

# 4. Redirect stdout and stderr to separate files
command > output.log 2> errors.log

# 5. Combine stdout and stderr into one destination
command > combined.log 2>&1
# (Modern Bash shortcut):
command &> combined.log

# 6. Discard all output completely into the virtual bit-bucket
command > /dev/null 2>&1
```

---

## 🚰 Multiplexing with `tee`
```text
           [ Process stdout ]
                   |
                [ tee ]
               /       \
              v         v
     [ Terminal Screen ]  [ logfile.txt ]
```
```bash
echo "Deployment started" | tee -a deployment.log
```
