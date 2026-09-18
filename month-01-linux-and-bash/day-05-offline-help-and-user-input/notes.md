# Day 05 Notes: Manual Sections & Offline Discovery

## 📚 Linux Man Page Numbered Sections

Linux manuals are cataloged into standard numbered categories:

| Section | Category | Description | Example |
|:---:|---|---|---|
| **1** | **User Commands** | Executable programs or shell commands run by normal users. | `man 1 ls`, `man 1 passwd` |
| **2** | **System Calls** | Kernel functions and interfaces provided by the operating system. | `man 2 open`, `man 2 fork` |
| **3** | **Library Calls** | C standard library functions (e.g., libc). | `man 3 printf` |
| **4** | **Special Files** | Device nodes typically located under `/dev`. | `man 4 null`, `man 4 random` |
| **5** | **File Formats** | Syntax and layout of configuration files. | `man 5 passwd`, `man 5 crontab` |
| **6** | **Games** | Games and entertainment utilities. | `man 6 intro` |
| **7** | **Conventions / Misc** | Overviews, protocols, macro packages, standards. | `man 7 regex`, `man 7 ip` |
| **8** | **System Administration** | Commands reserved primarily for root/administrators. | `man 8 useradd`, `man 8 iptables` |

---

### Key Takeaway: `passwd(1)` vs `passwd(5)`
- `man 1 passwd` documents the command used to change user passwords.
- `man 5 passwd` documents the colon-separated password configuration file `/etc/passwd`.

---

## 🔎 Finding Commands with `apropos`
When you don't know the command name:
```bash
apropos "compress"
apropos "partition"
apropos "network interface"
```
*(Equivalent to `man -k <keyword>`)*


---

# Day 05 Challenge: 3 Tasks Solved Without Google

## Challenge 1: Find how to print lines that do NOT match a pattern
- **Discovery**: `man grep` -> Search with `/invert` or `/exclude`.
- **Finding**: The flag is `-v` (`--invert-match`).
- **Solution Command**: `grep -v "root" /etc/passwd`

---

## Challenge 2: Sort files by size in human-readable reverse order
- **Discovery**: `man ls` -> Search with `/sort` -> Found `-S` (sort by file size).
- **Finding**: Combined with `-h` (human-readable) and `-r` (reverse).
- **Solution Command**: `ls -lhSr`

---

## Challenge 3: Determine which man section documents the crontab configuration file
- **Discovery**: `man -k crontab` or `apropos crontab`.
- **Finding**: `crontab (1)` is the user program; `crontab (5)` is the file tables syntax.
- **Solution Command**: `man 5 crontab`
