# Hidden Field Tampering

**One‑liner:** The page trusts a client‑side *hidden* field (`mail`) to drive password recovery. We can change it and the backend accepts it, leaking a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=recover`
* **Param:** `mail` (POST), rendered as `<input type="hidden" ...>`
* **Auth:** none

---

## How to reproduce

1. Open the page in a browser.
2. In DevTools → Elements, edit the hidden input `value` (replace `webmaster@borntosec.com`).
3. Submit the form.

**Observed:** server returns the flag

```
1d4855f7337c0c14b6f44946872c4eb33853f40b2d54393fbe94f49f1e19bbb0
```

> You can also POST directly (example probe):
>
> ```bash
> curl -i -X POST 'http://172.16.60.128/?page=recover' \
>   -d 'mail="/><h1>probe</h1>&Submit=Submit'
> ```

---

## Why this happens

* Hidden fields are **not** a security control; the client can change them.
* The server **uses the posted `mail` as is**, instead of deriving/validating it server‑side.
* If that value is later concatenated into HTML/SQL/email templates without encoding/parameterization, it becomes injection‑prone.

---

## Impact

* Anyone can alter the target of password recovery or trigger backend logic to leak data.
* Potential injection path (HTML/SQL) depending on how `mail` is used.

**Severity:** High (easy, no auth, sensitive outcome).

---

## Fix (server‑side — mandatory)

1. **Do not trust `mail` from the client.** Derive the recovery recipient on the server (from session). If unauthenticated, accept a user‑typed email but treat it as untrusted input.
2. **Validate and normalize:** strict email regex, server‑side length checks; reject control chars.
3. **Safe sinks:**

   * Database → use prepared statements.
   * HTML/Email → context‑aware output encoding; never inject raw values.
4. **Harden the flow:** generic responses ("If an account exists…"), single‑use time‑bound tokens, rate‑limit/CAPTCHA, CSRF token on the form.

---

## Client‑side hygiene (nice to have)

* Don’t store security‑relevant data in hidden inputs.
* `maxlength` on the client does not protect the server; enforce on the server.

---

## References

* OWASP: Parameter Tampering; Forgot Password Cheat Sheet.
* CWE‑642: External Control of Critical State Data.