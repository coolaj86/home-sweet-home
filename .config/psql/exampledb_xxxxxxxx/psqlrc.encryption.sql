-- custom parameters https://www.postgresql.org/docs/current/runtime-config-custom.html
-- (these must be scoped "extension"."var", where "extension" doesn't exist as a schema)

\set QUIET on
\pset pager off

-- ex: add "my" extension params to test pgp and raw encryption
SET SESSION "my"."aes_128_key" = E'\\xdeadbeefbadc0ffee0ddf00dcafebabe';
SET SESSION "my"."pgp_password" = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo right';

\echo ''
\echo '===================================================='
\echo '= Example: Using session parameters for encryption ='
\echo '===================================================='
\echo ''

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- pgp_sym encrypt / decrypt example
-- https://www.postgresql.org/docs/current/pgcrypto.html#PGCRYPTO-PGP-ENC-FUNCS
WITH "pgp_example_table_cte" AS (
    -- pgp_sym_encrypt(data text, psw text [, options text ]) returns bytea
    -- pgp_sym_encrypt_bytea(data bytea, psw text [, options text ]) returns bytea
    SELECT
        'sensitive data (pgp)' AS "plain_original",
        pgp_sym_encrypt(
            'sensitive data (pgp)',
            current_setting('my.pgp_password'),
            'cipher-algo=aes128, unicode-mode=1'
        ) AS "pgp_enc_column"
)
SELECT
    "plain_original",
    -- pgp_sym_decrypt(msg bytea, psw text [, options text ]) returns text
    -- pgp_sym_decrypt_bytea(msg bytea, psw text [, options text ]) returns bytea
    pgp_sym_decrypt(
        "pgp_enc_column",
        current_setting('my.pgp_password'),
        'cipher-algo=aes128, unicode-mode=1'
    ) AS "plain_decrypted",
    "pgp_enc_column"
FROM
    "pgp_example_table_cte" \gx

-- raw encrypt / decrypt example
-- https://www.postgresql.org/docs/current/pgcrypto.html#PGCRYPTO-RAW-ENC-FUNCS

WITH "aes_key_cte" AS (
    SELECT
        current_setting('my.aes_128_key')::bytea AS "aes_key",
        'sensitive data (raw)' AS "plain_original"
),
"raw_example_table_cte" AS (
    SELECT
        "aes_key",
        "plain_original",
        encrypt(convert_to("plain_original", 'UTF8'), "aes_key", 'aes') AS "raw_enc_column"
    FROM
        "aes_key_cte"
)
SELECT
    "plain_original",
    "raw_enc_column",
    convert_from(decrypt("raw_enc_column", "aes_key", 'aes'), 'UTF8') AS "plain_decrypted"
FROM
    "raw_example_table_cte"
\gx


-- convenience functions to reduce boilerplate within queries themselves
-- note: these are all temporary, but they could all be permanent

-- DROP FUNCTION IF EXISTS "pg_encrypt_text" (text,bytea);
CREATE OR REPLACE FUNCTION "pg_temp".pg_encrypt_text(plain_text text, aes_key bytea)
RETURNS bytea
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    -- encrypt(data bytea, key bytea, type text) returns bytea
    -- encrypt_iv(data bytea, key bytea, iv bytea, type text) returns bytea
    -- default 'type' is 'aes-cbc/pad:pkcs'
    SELECT encrypt(convert_to(plain_text, 'UTF8'), aes_key, 'aes')
$$;

-- DROP FUNCTION IF EXISTS "pg_decrypt_text" (bytea,bytea);
CREATE OR REPLACE FUNCTION "pg_temp".pg_decrypt_text(encrypted_data bytea, aes_key bytea)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    -- decrypt(data bytea, key bytea, type text) returns bytea
    -- decrypt_iv(data bytea, key bytea, iv bytea, type text) returns bytea
    -- default 'type' is 'aes-cbc/pad:pkcs'
    SELECT convert_from(decrypt(encrypted_data, aes_key, 'aes'), 'UTF8')
$$;

-- wraps the key in a function so that the ::bytea cast only happens once per query
-- DROP FUNCTION IF EXISTS "my_key" ();
CREATE OR REPLACE FUNCTION "pg_temp".my_key()
RETURNS bytea
LANGUAGE sql
STABLE -- relies on GUC (the key is different between client sessions), per per-query permanent
PARALLEL SAFE
AS $$
    -- the ::bytea cast breaks the STABLE caching of current_setting('my.foo')
    SELECT current_setting('my.aes_128_key')::bytea
$$;

-- conveniently wraps the key and encryption to be efficient across whole queries
-- DROP FUNCTION IF EXISTS "my_encrypt" (text);
CREATE OR REPLACE FUNCTION "pg_temp".my_encrypt(text)
RETURNS bytea
LANGUAGE sql
STABLE -- uses my_key() (GUC), but optimizes away the ::bytea cast per query
PARALLEL SAFE
AS $$
    SELECT encrypt(convert_to($1, 'UTF8'), "pg_temp".my_key(), 'aes')
$$;

-- conveniently wraps the key and decryption to be efficient across whole queries
-- DROP FUNCTION IF EXISTS "my_decrypt" (text);
CREATE OR REPLACE FUNCTION "pg_temp".my_decrypt(bytea)
RETURNS text
LANGUAGE sql
STABLE -- uses my_key() (GUC), but optimizes away the ::bytea cast per query
PARALLEL SAFE
AS $$
    SELECT convert_from(decrypt($1, "pg_temp".my_key(), 'aes'), 'UTF8')
$$;

--
-- Examples Using the Convenience Functions and Views
--

CREATE TEMPORARY TABLE IF NOT EXISTS "encrypted_pii_table" (
    "number" SERIAL PRIMARY KEY,
    "first_name" VARCHAR(255),
    "$last_name" BYTEA
);
INSERT INTO "encrypted_pii_table" ("first_name", "$last_name")
VALUES
    ('John', session_encrypt('Doe')),
    ('Jane', session_encrypt('Doe')),
    ('Bob', session_encrypt('Ross'));

CREATE OR REPLACE TEMPORARY VIEW "decrypted_pii_view" AS
WITH "aes_key" AS (
    -- just to show the use of a CTE for the key, the optimizations of my_key()
    -- and my_encrypt() should be the same once query-planned
    SELECT current_setting('my.aes_128_key')::bytea AS "aes_key"
)
SELECT
    "number",
    "first_name",
    "pg_temp".pg_decrypt_text("$last_name", "aes_key") AS "last_name"
FROM
    "encrypted_pii_table"
    CROSS JOIN "aes_key"
;

SELECT * FROM "encrypted_pii_table";
SELECT * FROM "decrypted_pii_view";

\echo '==================================================='
\echo '=              Try it for yourself!               ='
\echo '==================================================='
\echo ''
\echo 'SELECT * FROM "encrypted_pii_table";'
\echo 'SELECT * FROM "decrypted_pii_view";'
\echo 'SELECT "first_name", pg_temp.my_decrypt("$last_name") AS "last_name" FROM "encrypted_pii_table";'
\echo ''

\echo ''
\echo '===================================================='
\echo '=                  End of Example                  ='
\echo '===================================================='
\echo ''

\pset pager on
\unset QUIET
