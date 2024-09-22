--
-- Custom Parameters: https://www.postgresql.org/docs/current/runtime-config-custom.html
--
--   - Bound to the CURRENT LOGIN SESSION only
--   - Can be used as a VALUE, anywhere - such as in FUNCTIONS and VIEWS
--   - Must must be scoped "extension"."var", where "extension" is arbitrary
--     (conventionally "my", but can be anything that isn't already a schema)
--   - Can also be used programmatically by clients
--

-- ex: add conventional "my" extension with client params for pgp and raw encryption
SET SESSION "my"."client_id" = '12345678';
SET SESSION "my"."aes_128_key" = E'\\xdeadbeefbadc0ffee0ddf00dcafebabe';
SET SESSION "my"."pgp_password" = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo right';

-- ex: add arbitrary "foo" extension params for various debug and audit parameters
SET SESSION "foo"."test_user_id" = '0192183e-b61-77c5-aeea-2d735b0f0881';
SET SESSION "foo"."test_timezone" = 'America/New_York';
SET SESSION "foo"."role" = 'read-only-user';

-- ex: use anywhere that you can select
--
-- SELECT
--     current_setting('my.client_id') AS client_id,
--     current_setting('my.test_user_id') AS user_id,
--     current_setting('my.test_timezone') AS timezone;
--
-- SELECT * FROM "customers" WHERE "user_id" = current_setting('my.test_user_id');
