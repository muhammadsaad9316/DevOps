# Linux Ownership, umask & Special Bits Reference

## 🎭 The `umask` Formula

When a process creates a file or folder, the kernel applies `umask` (User Mask) to strip away specified permission bits:

- **Base Directory Permissions**: `0777` (`rwxrwxrwx`)
- **Base File Permissions**: `0666` (`rw-rw-rw-`) *(Linux never assigns executable bits by default for security)*

### Calculation with Default Ubuntu Umask (`0022`):
```text
Directories:
    0777 (rwxrwxrwx)
  - 0022 (----w--w-)
  ------------------
    0755 (rwxr-xr-x)

Files:
    0666 (rw-rw-rw-)
  - 0022 (----w--w-)
  ------------------
    0644 (rw-r--r--)
```

---

## 💎 Special Permission Bits

| Bit | Octal | Name | Appearance in `ls -l` | Effect |
|:---:|:---:|---|:---:|---|
| **SUID** | `4000` | Set User ID | `-rwsr-xr-x` | Process executes with permissions of the file owner (e.g. `/usr/bin/passwd`). |
| **SGID** | `2000` | Set Group ID | `drwxrwsr-x` | **On Directories**: Any file created inside inherits the directory's group automatically. |
| **Sticky**| `1000` | Sticky Bit | `drwxrwxrwt` | **On Directories (`/tmp`)**: Only the file owner or root can delete or rename files inside. |

---

## 👥 Configuring a Shared Team Directory
```bash
# 1. Create team folder
sudo mkdir -p /var/shared_projects

# 2. Assign group
sudo chown :devops /var/shared_projects

# 3. Apply Group Read/Write + SetGID bit (2775)
sudo chmod 2775 /var/shared_projects
```
Now, any file created by any user in `devops` will automatically belong to group `devops`.
