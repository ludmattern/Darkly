# Insecure Admin Cookie (MD5)

**One-liner:** Admin status is decided by a client-controlled cookie `i_am_admin` that the server compares to `md5("true")`. We can set that value and become admin, leaking a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/` (homepage or any page that checks admin)
* **Cookie:** `i_am_admin`
* **Auth:** none

**Initial state (from browser DevTools → Application → Cookies):**

```
Name        Value
----------- --------------------------------
i_am_admin  68934a3e9455fa72420237eb05902327
```

This hash is `MD5("false")`.

---

## How to reproduce

1. Compute `MD5("true")` → `b326b5062b2f0e69046810717534cb09` (no salt).
2. Edit the cookie value to that MD5.

   * In DevTools: double‑click the `Value` of `i_am_admin` and paste `b326b5062b2f0e69046810717534cb09`.
   * Or with cURL:

     ```bash
     curl -i 'http://127.0.0.1:8080/' \
       -H 'Cookie: i_am_admin=b326b5062b2f0e69046810717534cb09'
     ```
3. Refresh the page that checks the cookie.

**Observed:** the server treats you as admin and returns the flag

```
df2eb4ba34ed059a1e3e89ff4dfc13445f104a1a52295214def1c4fb1693a5c3
```

---

## Why this happens

* **Trusting client‑side state:** The app relies on a **client‑modifiable cookie** to assert admin status.
* **No integrity protection:** The cookie is not signed/MACed; the server simply compares hashes.
* **Weak crypto choice:** `MD5` is broken and fast to brute force; here it’s just a static `md5("true")` vs `md5("false")` check.

---

## Impact

* **Privilege escalation:** Any user can become admin by setting the right cookie value.
* **Data exposure / admin actions:** Access to admin‑only functions or secrets (here, a flag).

**Severity:** High → trivial, no auth required, full privilege gain.

---

## Fix (server‑side — mandatory)

1. **Do not store authorization in client cookies.** Keep roles in a **server‑side session** (e.g., session ID → role in DB/cache).
2. If you must put data in a cookie, use a **signed, tamper‑evident** format (e.g., HMAC‑SHA256 with a server secret). Reject on bad signature.
3. **Never use MD5** for security decisions. Prefer modern primitives (HMAC‑SHA256 for signatures; Argon2/BCrypt for passwords).
4. **Enforce authorization** on each protected route server‑side (check session role, not a cookie flag).
5. **Set cookie flags** for session cookies: `HttpOnly`, `Secure`, `SameSite=Lax/Strict`, short TTL, rotation on privilege change.

---

## Client‑side hygiene (nice to have)

* Don’t expose booleans like `i_am_admin` to the client. UI should reflect server decisions, not drive them.

---

## References

* OWASP Cheat Sheet: **Session Management**, **Authentication**, **Cryptographic Storage**
* CWE‑565: **Reliance on Cookies without Validation and Integrity Checking**
* CWE‑327: **Use of a Broken or Risky Cryptographic Algorithm (MD5)**
* CWE‑285/287: **Improper Authorization/Authentication** (context)
