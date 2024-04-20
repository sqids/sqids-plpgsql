CREATE OR REPLACE FUNCTION sqids.blocklist_test() RETURNS VOID AS $$
DECLARE
  i RECORD;
BEGIN
  RAISE NOTICE 'sqids.blocklist_test';
  RAISE NOTICE 'use default blocklist';
  PERFORM sqids.defaultBlocklist();
  
  RAISE NOTICE 'expect.soft(sqids.decode(''aho1e'')).toEqual([4572721]);';
  IF sqids.decode('aho1e') = array[4572721]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
  
  RAISE NOTICE 'expect.soft(sqids.encode([4572721])).toBe(''JExTR'');';
  IF sqids.encode(array[4572721]) = 'JExTR' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; got %', sqids.encode(array[4572721]);
  END IF;
  
  RAISE NOTICE 'if blocklist is empty, don''t use any blocklist';
  DELETE FROM sqids.blocklist;
  
  RAISE NOTICE 'expect.soft(sqids.decode(''aho1e'')).toEqual([4572721]);';
  IF sqids.decode('aho1e') = array[4572721]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'expect.soft(sqids.encode([4572721])).toBe(''aho1e'');';
  IF sqids.encode(array[4572721]) = 'aho1e' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'if a non-empty blocklist param passed, use only that';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES ('ArUO');
  
  RAISE NOTICE 'expect.soft(sqids.decode(''aho1e'')).toEqual([4572721]);';
  IF sqids.decode('aho1e') = array[4572721]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
  
  RAISE NOTICE 'expect.soft(sqids.encode([4572721])).toBe(''aho1e'');';
  IF sqids.encode(array[4572721]) = 'aho1e' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
  
  RAISE NOTICE 'expect.soft(sqids.decode(''ArUO'')).toEqual([100000]);';
  IF sqids.decode('ArUO') = array[100000]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
  
  RAISE NOTICE 'expect.soft(sqids.encode([100000])).toBe(''QyG4'');';
  IF sqids.encode(array[100000]) = 'QyG4' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED; got %', sqids.encode(array[100000]);
  END IF;
  
  RAISE NOTICE 'expect.soft(sqids.decode(''QyG4'')).toEqual([100000]);';
  IF sqids.decode('QyG4') = array[100000]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'custom blocklist';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES
  ('JSwXFaosAN'), --normal result of 1st encoding, let's block that word on purpose
  ('OCjV9JK64o'), --result of 2nd encoding
  ('rBHf'), --result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
  ('79SM'), --result of 4th encoding is `dyhgw479SM`, let's block the postfix
  ('7tE6'); --result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
  
  RAISE NOTICE 'expect.soft(sqids.encode([1000000, 2000000])).toBe(''1aYeB7bRUt'');';
  IF sqids.encode(array[1000000, 2000000]) = '1aYeB7bRUt' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
	
  RAISE NOTICE 'expect.soft(sqids.decode(''1aYeB7bRUt'')).toEqual([1_000_000, 2_000_000]);';
  IF sqids.decode('1aYeB7bRUt') = array[1000000, 2000000]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'decoding blocklist words should still work';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES
  ('86Rf07'),
  ('se8ojk'),
  ('ARsz1p'),
  ('Q8AI49'),
  ('5sQRZO');
	
  RAISE NOTICE 'expect.soft(sqids.decode(''86Rf07'')).toEqual([1, 2, 3]);';
  IF sqids.decode('86Rf07') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
	
  RAISE NOTICE 'expect.soft(sqids.decode(''se8ojk'')).toEqual([1, 2, 3]);';
  IF sqids.decode('se8ojk') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
	
  RAISE NOTICE 'expect.soft(sqids.decode(''ARsz1p'')).toEqual([1, 2, 3]);';
  IF sqids.decode('ARsz1p') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
	
  RAISE NOTICE 'expect.soft(sqids.decode(''Q8AI49'')).toEqual([1, 2, 3]);';
  IF sqids.decode('Q8AI49') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;
	
  RAISE NOTICE 'expect.soft(sqids.decode(''5sQRZO'')).toEqual([1, 2, 3]);';
  IF sqids.decode('5sQRZO') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'match against a short blocklist word';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES ('pnd');
  
  RAISE NOTICE 'expect.soft(sqids.decode(sqids.encode([1000]))).toEqual([1000]);';
  IF sqids.decode(sqids.encode(array[1000])) = array[1000]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'blocklist filtering in constructor';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES ('sxnzkl'); --lowercase blocklist in only-uppercase alphabet

  RAISE NOTICE 'expect.soft(id).toEqual(''IBSHOZ''); // without blocklist, would''ve been "SXNZKL"';
  IF sqids.encode(array[1, 2, 3], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') = 'IBSHOZ' THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'expect.soft(numbers).toEqual([1, 2, 3]);';
  IF sqids.decode('IBSHOZ', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') = array[1, 2, 3]::BIGINT[] THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'max encoding attempts';
  DELETE FROM sqids.blocklist;
  INSERT INTO sqids.blocklist (str) VALUES ('cab'), ('abc'), ('bca');
  BEGIN
    PERFORM sqids.encode(array[0], 'abc', 3);
    RAISE NOTICE '  FAILED';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  PASSED';
  END;

END
$$ LANGUAGE plpgsql;