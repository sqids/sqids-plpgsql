CREATE OR REPLACE FUNCTION sqids.encoding_test() RETURNS VOID AS $$
DECLARE
  id_pairs json;
  id_pair record;
  id TEXT;
  numbers BIGINT[];
BEGIN
  RAISE NOTICE 'sqids.encoding_test';
  RAISE NOTICE 'simple';
  numbers := array[1, 2, 3];
  id := '86Rf07';

  RAISE NOTICE 'expect.soft(sqids.encode(%)).toBe(%);', numbers, id;
  IF sqids.encode(numbers) = id THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'expect.soft(sqids.decode(%)).toEqual(%);', id, numbers;
  IF sqids.decode(id) = numbers THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'different inputs';
  numbers := array[0, 0, 0, 1, 2, 3, 100, 1000, 100000, 1000000, 9007199254740991];
	
  RAISE NOTICE 'expect.soft(sqids.decode(sqids.encode(%))).toEqual(%);', numbers, numbers;
  IF sqids.decode(sqids.encode(numbers)) = numbers THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'incremental numbers';
  id_pairs := '{"bM": [0], "Uk": [1], "gb": [2], "Ef": [3], "Vq": [4], "uw": [5], "OI": [6], "AX": [7], "p6": [8], "nJ": [9]}'::json;

  FOR id_pair IN SELECT * FROM json_each(id_pairs) LOOP
    id := id_pair.key;
    numbers := ARRAY(SELECT value::integer FROM json_array_elements_text(id_pair.value) AS value);

    RAISE NOTICE 'Key: %, Value: %', id, numbers;
    RAISE NOTICE 'expect.soft(sqids.encode(%)).toBe(%);', numbers, id;
    IF sqids.encode(numbers) = id THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;

    RAISE NOTICE 'expect.soft(sqids.decode(%)).toEqual(%);', id, numbers;
    IF sqids.decode(id) = numbers THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;
  END LOOP;

  RAISE NOTICE 'incremental numbers, same index 0';
  id_pairs := '{"SvIz": [0, 0], "n3qa": [0, 1], "tryF": [0, 2], "eg6q": [0, 3], "rSCF": [0, 4], "sR8x": [0, 5], "uY2M": [0, 6], "74dI": [0, 7], "30WX": [0, 8], "moxr": [0, 9]}'::json;

  FOR id_pair IN SELECT * FROM json_each(id_pairs) LOOP
    id := id_pair.key;
    numbers := ARRAY(SELECT value::integer FROM json_array_elements_text(id_pair.value) AS value);

    RAISE NOTICE 'Key: %, Value: %', id, numbers;
    RAISE NOTICE 'expect.soft(sqids.encode(%)).toBe(%);', numbers, id;
    IF sqids.encode(numbers) = id THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;

    RAISE NOTICE 'expect.soft(sqids.decode(%)).toEqual(%);', id, numbers;
    IF sqids.decode(id) = numbers THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;
  END LOOP;

  RAISE NOTICE 'incremental numbers, same index 1';
  id_pairs := '{"SvIz": [0, 0], "nWqP": [1, 0], "tSyw": [2, 0], "eX68": [3, 0], "rxCY": [4, 0], "sV8a": [5, 0], "uf2K": [6, 0], "7Cdk": [7, 0], "3aWP": [8, 0], "m2xn": [9, 0]}'::json;

  FOR id_pair IN SELECT * FROM json_each(id_pairs) LOOP
    id := id_pair.key;
    numbers := ARRAY(SELECT value::integer FROM json_array_elements_text(id_pair.value) AS value);

    RAISE NOTICE 'Key: %, Value: %', id, numbers;
    RAISE NOTICE 'expect.soft(sqids.encode(%)).toBe(%);', numbers, id;
    IF sqids.encode(numbers) = id THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;

    RAISE NOTICE 'expect.soft(sqids.decode(%)).toEqual(%);', id, numbers;
    IF sqids.decode(id) = numbers THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;
  END LOOP;

  RAISE NOTICE 'multi input';
   numbers := array[
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
		26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
		50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
		74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
		98, 99
	];
  
  RAISE NOTICE 'expect.soft(sqids.decode(sqids.encode(%))).toEqual(%);', numbers, numbers;
  IF sqids.decode(sqids.encode(numbers)) = numbers THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'encoding no numbers';
  RAISE NOTICE 'expect.soft(sqids.encode([])).toBe('''');';
  IF sqids.encode(ARRAY[]::BIGINT[]) = '' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'decoding empty string';
  RAISE NOTICE 'expect.soft(sqids.decode('')).toEqual([]);';
  IF sqids.decode('') = ARRAY[]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'decoding an ID with an invalid character';
  RAISE NOTICE 'expect.soft(sqids.decode(''*'')).toBe([]);';
  IF sqids.decode('*') = ARRAY[]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

END
$$ LANGUAGE plpgsql;