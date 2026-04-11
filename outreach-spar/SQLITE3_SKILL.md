# TSV editing with sqlite3

TSV (IANA text/tab-separated-values) has no quoting mechanism. Most SQL-over-file tools (trdsql, q, csvq) treat TSV as "CSV with tabs" and re-quote fields containing `"` on output — data corruption. sqlite3 `.mode tabs` is a true literal-delimiter mode. UPDATE also avoids enumerating columns — a SELECT rewrite silently drops any column the author forgets.

## Read

```bash
sqlite3 :memory: <<'EOF'
.mode tabs
.import file.tsv tbl
SELECT contact_name, email FROM tbl WHERE email = '';
EOF
```

## Write

```bash
sqlite3 :memory: <<'EOF'
.mode tabs
.import file.tsv tbl
UPDATE tbl SET email='new@example.com' WHERE contact_name='Name';
.headers on
.output /tmp/out.tsv
SELECT * FROM tbl;
EOF
mv /tmp/out.tsv file.tsv
```

For concurrent access (worker scripts), wrap with `flock -x`.
