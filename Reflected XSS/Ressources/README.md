# Reflected XSS (feedback)

**One‑liner:** The feedback form reflects user input without proper server‑side encoding. Sending the keyword `script` (or an actual XSS payload) triggers the vulnerable path and the app returns a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/index.php?page=feedback`
* **Params (POST):** `txtName`, `mtxtMessage`, `btnSign`
* **Auth:** none

Client‑side constraints (`maxlength`, `validate_form()`, `checkForm()`) exist but are **bypassable**. Security must be server‑side.

---

## How to reproduce (simple)

**In the form:**

* Put **`script`** in either `Name` or `Message`, submit.

**Observed:** the application returns the flag

```
0fbb54bbf7d099713ca4be297e1bc7da0173d8b3c21c1811b916a3a86652724e
```

> Note: Trying real XSS probes (e.g., `"<button onclick="alert('hello')">button</button>`) typically demonstrates the same root cause when the page reflects the data unsafely.

---

## Impact

* **Reflected XSS:** Attacker‑controlled HTML/JS can execute in victims’ browsers (session theft, CSRF, phishing).
* In this lab, sending `script` directly reveals a **token**.

**Severity:** High (no auth, trivial trigger, potential arbitrary JS execution).

---

## Fix (server‑side — mandatory)

1. **Encode output** according to context:

   * HTML text → HTML‑encode (`& < > " '`).
   * Inside attributes → attribute‑encode; avoid unquoted attributes.
   * Inside JavaScript → JavaScript‑encode or avoid inline JS entirely.
2. **Use safe templating** (auto‑escaping by default) and avoid concatenating raw input into HTML.
3. **Validate input** (length, charset) but do **not** rely on blacklists like the literal word `script`.
4. **Add a Content Security Policy (CSP)** to reduce impact (`script-src 'self'; object-src 'none'`; avoid `unsafe-inline`).
5. **Disable inline event handlers** (`onclick`, etc.) and inline `<script>` in templates.

---

## References

* OWASP Cheat Sheet: **XSS Prevention**
* CWE‑79: **Cross‑Site Scripting (XSS)**

--- 
## See also
**index** → [here](/README.md)