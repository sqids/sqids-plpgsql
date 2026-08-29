CREATE OR REPLACE FUNCTION sqids.assert_volatility(fn_name TEXT, identity_args TEXT, expected CHAR) RETURNS BOOLEAN AS $$
DECLARE
  actual CHAR;
BEGIN
  SELECT p.provolatile INTO actual
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'sqids'
    AND p.proname = fn_name
    AND pg_get_function_identity_arguments(p.oid) = identity_args;

  IF actual IS NULL THEN
    RAISE NOTICE '  FAILED; missing sqids.%(%)', fn_name, identity_args;
    RETURN FALSE;
  END IF;

  IF actual IS DISTINCT FROM expected THEN
    RAISE NOTICE '  FAILED; %(%) is % expected %', fn_name, identity_args, actual, expected;
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sqids.immutable_test() RETURNS VOID AS $$
DECLARE
  got TEXT;
  ext TEXT;
  ok BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE 'sqids.immutable_test';
  PERFORM sqids.defaultBlocklist();

  RAISE NOTICE 'function volatility';
  ok := sqids.assert_volatility('shuffle', 'alphabet text', 'i')
    AND sqids.assert_volatility('checkalphabet', 'alphabet text', 'i')
    AND sqids.assert_volatility('toid', 'num bigint, alphabet text', 'i')
    AND sqids.assert_volatility('tonumber', 'id text, alphabet text', 'i')
    AND sqids.assert_volatility('decode', 'id text, alphabet text', 'i')
    AND sqids.assert_volatility('defaultblocklistwords', '', 'i')
    AND sqids.assert_volatility('isblockedid', 'id text, blocklist text[]', 'i')
    AND sqids.assert_volatility('encodenumbers', 'numbers bigint[], alphabet text, minlength integer, increment integer, blocklist text[]', 'i')
    AND sqids.assert_volatility('encodeimmutable', 'numbers bigint[], alphabet text, minlength integer, blocklist text[]', 'i')
    AND sqids.assert_volatility('encodeimmutable', 'numbers bigint[], alphabet text, minlength integer', 'i')
    AND sqids.assert_volatility('encodeimmutable', 'numbers bigint[], minlength integer', 'i')
    AND sqids.assert_volatility('isblockedid', 'id text', 's')
    AND sqids.assert_volatility('encodenumbers', 'numbers bigint[], alphabet text, minlength integer, increment integer', 's')
    AND sqids.assert_volatility('encode', 'numbers bigint[], alphabet text, minlength integer', 's')
    AND sqids.assert_volatility('encode', 'numbers bigint[], minlength integer', 's')
    AND sqids.assert_volatility('defaultblocklist', '', 'v');
  IF ok THEN
    RAISE NOTICE '  PASSED';
  END IF;

  RAISE NOTICE 'encodeImmutable matches encode with the default blocklist';
  IF sqids.encodeImmutable(array[1, 2, 3]) = sqids.encode(array[1, 2, 3])
     AND sqids.encodeImmutable(array[4572721]) = sqids.encode(array[4572721]) THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'encodeImmutable matches encode with a custom alphabet';
  IF sqids.encodeImmutable(array[123, 456, 789], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 12)
       = sqids.encode(array[123, 456, 789], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 12) THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'encodeImmutable ignores table blocklist changes';
  DELETE FROM sqids.blocklist;
  IF sqids.encode(array[4572721]) = 'aho1e'
     AND sqids.encodeImmutable(array[4572721]) = 'JExTR' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; encode=% encodeImmutable=%', sqids.encode(array[4572721]), sqids.encodeImmutable(array[4572721]);
  END IF;
  PERFORM sqids.defaultBlocklist();

  RAISE NOTICE 'encodeImmutable ignores extra table blocklist rows';
  INSERT INTO sqids.blocklist (str) VALUES ('86Rf07');
  IF sqids.encode(array[1, 2, 3]) <> '86Rf07'
     AND sqids.encodeImmutable(array[1, 2, 3]) = '86Rf07' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; encode=% encodeImmutable=%', sqids.encode(array[1, 2, 3]), sqids.encodeImmutable(array[1, 2, 3]);
  END IF;
  PERFORM sqids.defaultBlocklist();

  RAISE NOTICE 'encodeImmutable with an explicit blocklist';
  got := sqids.encodeImmutable(array[1, 2, 3], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 0, ARRAY['86Rf07']::TEXT[]);
  IF got <> '86Rf07' AND sqids.decode(got) = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; got=%', got;
  END IF;

  RAISE NOTICE 'encodeImmutable is allowed in a generated column';
  DROP TABLE IF EXISTS sqids.immutable_gen_test;
  CREATE TABLE sqids.immutable_gen_test (
    id integer PRIMARY KEY,
    external_id text GENERATED ALWAYS AS (
      sqids.encodeImmutable(ARRAY[id]::BIGINT[], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 5)
    ) STORED,
    short_id text GENERATED ALWAYS AS (
      sqids.encodeImmutable(ARRAY[id]::BIGINT[])
    ) STORED
  );
  INSERT INTO sqids.immutable_gen_test(id) VALUES (1);
  SELECT external_id INTO ext FROM sqids.immutable_gen_test WHERE id = 1;
  got := sqids.encodeImmutable(ARRAY[1]::BIGINT[], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 5);
  IF ext = got AND LENGTH(ext) >= 5 THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; generated=% expected=%', ext, got;
  END IF;
  DROP TABLE sqids.immutable_gen_test;

  RAISE NOTICE 'encodeImmutable with a literal blocklist is allowed in a generated column';
  DROP TABLE IF EXISTS sqids.immutable_gen_custom_test;
  CREATE TABLE sqids.immutable_gen_custom_test (
    id integer PRIMARY KEY,
    external_id text GENERATED ALWAYS AS (
      sqids.encodeImmutable(ARRAY[id]::BIGINT[], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 0, ARRAY['Uk']::TEXT[])
    ) STORED
  );
  INSERT INTO sqids.immutable_gen_custom_test(id) VALUES (1);
  SELECT external_id INTO ext FROM sqids.immutable_gen_custom_test WHERE id = 1;
  IF ext <> 'Uk' AND sqids.decode(ext) = ARRAY[1]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; generated=%', ext;
  END IF;
  DROP TABLE sqids.immutable_gen_custom_test;

  RAISE NOTICE 'table-backed encode is rejected in a generated column';
  BEGIN
    CREATE TABLE sqids.volatile_gen_test (
      id integer PRIMARY KEY,
      external_id text GENERATED ALWAYS AS (sqids.encode(ARRAY[id]::BIGINT[])) STORED
    );
    RAISE NOTICE '  FAILED';
    DROP TABLE IF EXISTS sqids.volatile_gen_test;
  EXCEPTION WHEN invalid_object_definition THEN
    RAISE NOTICE '  PASSED';
  END;

  RAISE NOTICE 'encodeImmutable rejects negative numbers';
  BEGIN
    PERFORM sqids.encodeImmutable(array[-1]);
    RAISE NOTICE '  FAILED';
  EXCEPTION WHEN others THEN
    IF SQLERRM LIKE 'Sqids: numbers must be non-negative%' THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED; %', SQLERRM;
    END IF;
  END;
END
$$ LANGUAGE plpgsql;
