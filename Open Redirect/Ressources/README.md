# Open Redirect

**One‑liner:** The redirect endpoint trusts the `site` parameter. By changing it to an arbitrary URL, the server performs an open redirect and returns the token.

---

## Where

* **URL:** `http://172.16.60.128/index.php?page=redirect&site={value}`
* **Param:** `site` (GET)
* **Auth:** none

The homepage footer links call this endpoint, e.g. `site=facebook`, `site=twitter`, or even a full URL like `site=https://www.google.fr`.

---

## How to reproduce

1. Visit the homepage and inspect the footer links.
2. Manually open:
   `http://127.0.0.1:8080/index.php?page=redirect&site=www.google.fr`
3. The application accepts the untrusted `site` value and processes the redirect.

**Observed:** the server returns the token

```
b9e775a0291fed784a2d9680fcfad7edd6b8cdf87648da647aaf4bba288bcab3
```

---

## Why this happens

* The server **uses a user‑controlled URL** for redirection without a strict allow‑list or canonicalization.
* No verification that `site` is one of the intended destinations; full/partial external URLs pass through.
* If other schemes are accepted (e.g., `javascript:`, `data:`), this can escalate to XSS or phishing.

---

## Impact

* **Open redirect:** attackers can craft trusted‑looking links on this domain that send users elsewhere (phishing, token theft, OAuth mischief).

**Severity:** High (no auth, easy to exploit, leads to sensitive token exposure and phishing risk).

---

## Fix (server‑side — mandatory)

1. **Allow‑list destinations.** Map a **short key** to a vetted URL on the server:

   * Accept only values like `facebook`, `twitter`, `school`.
   * On the server, `switch(key) → exact URL`. Reject anything else with `400` or redirect to a safe default.
2. **Prefer internal redirects.** If possible, only allow **relative paths** within the same site; block absolute URLs.
3. **Normalize and validate.** Canonicalize the URL, then check scheme and host strictly. **Block** `javascript:`, `data:`, `file:`, mixed/scheme‑relative URLs, and userinfo in URLs.
4. **Logging & rate limiting.** Log rejected attempts; throttle abuse.

---

## Client‑side hygiene (nice to have)

* Footer links can point directly to final URLs; avoid going through a redirector unless you truly need telemetry.

---

## References

* OWASP Cheat Sheet: **Unvalidated Redirects and Forwards**
* CWE‑601: **URL Redirection to Untrusted Site ('Open Redirect')**

--- 
## See also
**index** → [here](/README.md)