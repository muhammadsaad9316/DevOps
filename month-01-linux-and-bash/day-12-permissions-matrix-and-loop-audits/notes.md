# The Unix Permissions Matrix Architecture

```text
- r w x r - x r - -
┬ └───┬───┘ └───┬───┘ └───┬───┘
│     │         │         └── Others (World) Permissions: r-- (Read Only)
│     │         └─────────── Group Permissions: r-x (Read & Execute)
│     └───────────────────── User (Owner) Permissions: rwx (Read, Write & Execute)
└─────────────────────────── File Type: - (Regular File), d (Directory), l (Symlink)
```

---

## 🧮 Octal Values
- **Read (`r`)** = `4` (Binary `100`)
- **Write (`w`)** = `2` (Binary `010`)
- **Execute (`x`)** = `1` (Binary `001`)

```text
r w x  = 4 + 2 + 1 = 7
r - x  = 4 + 0 + 1 = 5
r - -  = 4 + 0 + 0 = 4
- - -  = 0 + 0 + 0 = 0
```

---

## 📁 Files vs. Directories: The Crucial Difference

| Permission | Effect on a Regular File | Effect on a Directory |
|:---:|---|---|
| **`r` (Read)** | View/read contents of file (`cat`, `less`). | List files inside directory (`ls`). |
| **`w` (Write)** | Modify or overwrite file content. | Create, delete, or rename files inside directory. |
| **`x` (Execute)**| Run file as a binary program or script. | **Traverse/Enter** the directory (`cd`) or access inodes inside. |

> [!IMPORTANT]
> If a directory has `r` but lacks `x`, you can list the names of files inside, but you **cannot `cd` into it** or read any file contents!

---

## 🔒 Standard Production Presets
- Private keys (`id_rsa`, `.env`): `chmod 600` (`-rw-------`)
- Regular web / config files: `chmod 644` (`-rw-r--r--`)
- Executable scripts / binaries: `chmod 755` (`-rwxr-xr-x`)
- Secure directories: `chmod 700` (`drwx------`)
