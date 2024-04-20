CREATE OR REPLACE FUNCTION sqids.alphabet_test() RETURNS VOID AS $$
BEGIN
  RAISE NOTICE 'sqids.alphabet_test';
  RAISE NOTICE 'simple encode';
  IF sqids.encode(array[1, 2, 3], '0123456789abcdef') = '489158' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'simple decode';
  IF sqids.decode('489158', '0123456789abcdef') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'short alphabet encode/decode';
  IF sqids.decode(sqids.encode(array[1, 2, 3], 'abc'), 'abc') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'long alphabet encode/decode';
  IF sqids.decode(sqids.encode(array[1, 2, 3], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\''"/?.>,<`~'), 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\''"/?.>,<`~') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'test multibyte characters';
  BEGIN
    PERFORM sqids.checkAlphabet('ë1092');
    RAISE NOTICE '  FAILED';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  PASSED';
  END;

  RAISE NOTICE 'repeating alphabet characters';
  BEGIN
    PERFORM sqids.checkAlphabet('aabcdefg');
    RAISE NOTICE '  FAILED';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  PASSED';
  END;

  RAISE NOTICE 'too short alphabet';
  BEGIN
    PERFORM sqids.checkAlphabet('ab');
    RAISE NOTICE '  FAILED';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  PASSED';
  END;
END
$$ LANGUAGE plpgsql;