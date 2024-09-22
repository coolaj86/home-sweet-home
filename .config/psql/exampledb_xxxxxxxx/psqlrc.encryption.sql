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
    plain_original,
    -- pgp_sym_decrypt(msg bytea, psw text [, options text ]) returns text
    -- pgp_sym_decrypt_bytea(msg bytea, psw text [, options text ]) returns bytea
    pgp_sym_decrypt(
        "pgp_enc_column"::bytea,
        current_setting('my.pgp_password')::text,
        'cipher-algo=aes128, unicode-mode=1'::text
    )::text AS "plain_decrypted",
    "pgp_enc_column"
FROM
    "pgp_example_table_cte" \gx

-- raw encrypt / decrypt example
-- https://www.postgresql.org/docs/current/pgcrypto.html#PGCRYPTO-RAW-ENC-FUNCS

-- convenience functions to reduce boilerplate within queries themselves
CREATE OR REPLACE FUNCTION encrypt_aes_cbc(plain_text text, aes_key_hex text)
RETURNS bytea
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
	-- encrypt(data bytea, key bytea, type text) returns bytea
	-- encrypt_iv(data bytea, key bytea, iv bytea, type text) returns bytea
    -- default 'type' is 'aes-cbc/pad:pkcs'
    SELECT encrypt(convert_to(plain_text, 'UTF8'), aes_key_hex, 'aes')
$$;

CREATE OR REPLACE FUNCTION decrypt_aes_cbc(encrypted_data bytea, aes_key_hex text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
	-- decrypt(data bytea, key bytea, type text) returns bytea
	-- decrypt_iv(data bytea, key bytea, iv bytea, type text) returns bytea
    -- default 'type' is 'aes-cbc/pad:pkcs'
    SELECT convert_from(decrypt(encrypted_data, aes_key_hex, 'aes'), 'UTF8')
$$;

WITH "raw_example_table_cte" AS (
    SELECT
        'sensitive data (raw)' AS "plain_original",
        encrypt_aes_cbc(
			'sensitive data (raw)',
			current_setting('my.aes_128_key')
		) AS "raw_enc_column"
)
SELECT
	-- session_decrypt(raw_enc_column::bytea) AS plain_text,
    plain_original,
	decrypt_aes_cbc(
		raw_enc_column,
		current_setting('my.aes_128_key')
	) AS "plain_decrypted",
    "raw_enc_column"
FROM
    "raw_example_table_cte" \gx

\echo ''
\echo '===================================================='
\echo '=                  End of Example                  ='
\echo '===================================================='
\echo ''

\pset pager on
\unset QUIET
