# Directory Listing → Sensitive Files Exposed (`/.hidden/`)

**One‑liner:** The web server exposes directory indexes. A hidden folder `/.hidden/` is browsable and contains nested subfolders with a `README` revealing a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/.hidden/`
* **Behavior:** Server returns an **auto‑generated index** ("Index of /.hidden/") listing subdirectories/files.
* **Auth:** none

---

## How to reproduce (simple (it's not))

1. Open `http://127.0.0.1:8080/.hidden/` in the browser.
2. Browse the subfolders until you find the right `README` file.
3. Open the right `README` → it contains the flag.

**Observed flag (example path):**

```
.../.hidden/whtccjokayshttvxycsvykxcfm/igeemtxnvexvxezqwntmzjltkt/lmpanswobhwcozdqixbowvbrhw/README
Hey, here is your flag : d5eec3ec36cf80dce44a896f961c1831a05526ec215693c8f2c39543497d4466
```

---

## How to reproduce (script)

> Use `wget` to recursively download the hidden directory and `grep` to find the flag.

```bash
#!/usr/bin/env bash
set -euo pipefail
BASE="http://127.0.0.1:8080/.hidden/"
OUT="${1:-./hidden-dl}"

mkdir -p "$OUT"
wget -r -np -nH --cut-dirs=1 -e robots=off -P "$OUT" "$BASE"

grep -R --text "flag" "$OUT" || true
```

**Output:**

```
./hidden-dl/.../README:Hey, here is your flag : d5eec3ec36cf80dce44a896f961c1831a05526ec215693c8f2c39543497d4466
```

---

## Impact

* **Information disclosure:** Access to internal files, notes, backups, or config placed under web root.
* **Recon pivot:** Directory trees often reveal app structure or credentials.

**Severity:** High (no auth, trivial discovery, direct secret exposure).

---

## Fix (server‑side — mandatory)

1. **Disable directory indexes.**

   * Apache: in vhost or `.htaccess` → `Options -Indexes`.
   * Nginx: `autoindex off;` in the relevant `location`.
2. **Move sensitive content out of web root.** Keep secrets one level above and expose only what must be public.
3. **Access control:** If a directory must exist, protect with auth and deny direct listing (`IndexOptions -Indexes`).
4. **Inventory & CI checks:** Add a test that fails the build if autoindex is detected or if `/.hidden/` exists.
5. **Don’t rely on `robots.txt`.** It is advisory, not a security control.

---

## References

* OWASP **A05:2021 – Security Misconfiguration**
* CWE‑548: **Information Exposure Through Directory Listing**
* CWE‑200: **Exposure of Sensitive Information to an Unauthorized Actor**

--- 
## See also
**index** → [here](/README.md)