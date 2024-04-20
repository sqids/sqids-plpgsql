CREATE OR REPLACE FUNCTION sqids.minlength_test() RETURNS void AS $$
DECLARE
  default_alphabet TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  numbers BIGINT[];
  id TEXT;
  map JSON;
  id_pair RECORD;
  rec_json json;
  i INT;
BEGIN
  RAISE NOTICE 'tsids.minlength_test';
  RAISE NOTICE 'simple';
  numbers := array[1, 2, 3];
  id := '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM';
  IF sqids.encode(numbers, default_alphabet, LENGTH(default_alphabet)) = id THEN
    RAISE NOTICE '  PASSED';
  ELSE
    RAISE NOTICE '  FAILED';
  END IF;

  RAISE NOTICE 'incremental';
  map := '{"6": "86Rf07", "7": "86Rf07x", "8": "86Rf07xd", "9": "86Rf07xd4", "10": "86Rf07xd4z", "11": "86Rf07xd4zB", "12": "86Rf07xd4zBm", "13": "86Rf07xd4zBmi", "62": "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM", "63": "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy", "64": "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf", "65": "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1"}'::json;
  FOR id_pair IN SELECT * FROM json_each_text(map) LOOP
    i := id_pair.key::INT;
    id := id_pair.value;

    IF sqids.encode(array[1, 2, 3], default_alphabet, i) = id THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;
  END LOOP;

  RAISE NOTICE 'incremental numbers';
  map := '{"SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu": [0, 0],
    "n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc": [0, 1],
    "tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ": [0, 2],
    "eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE": [0, 3],
    "rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX": [0, 4],
    "sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2": [0, 5],
    "uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0": [0, 6],
    "74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy": [0, 7],
    "30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS": [0, 8],
    "moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin": [0, 9]}'::json;
  FOR id_pair IN SELECT * FROM json_each(map) LOOP
    id := id_pair.key;
    numbers := ARRAY(SELECT value::integer FROM json_array_elements_text(id_pair.value) AS value);
    raise notice 'decode %', id;
    IF sqids.decode(id, default_alphabet) = numbers THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;

    raise notice 'encode %', numbers;
    IF sqids.encode(numbers, default_alphabet, LENGTH(default_alphabet)) = id THEN
      RAISE NOTICE '  PASSED';
    ELSE
      RAISE NOTICE '  FAILED';
    END IF;
  END LOOP;

  RAISE NOTICE 'min lengths';
  map := '[[0], [0, 0, 0, 0, 0], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [100, 200, 300], [1000, 2000, 3000], [1000000], [9007199254740991]]'::json;
  FOREACH i IN ARRAY ARRAY[0, 1, 5, 10, LENGTH(default_alphabet)] LOOP
    FOR rec_json IN SELECT * FROM json_array_elements_text(map) LOOP
      numbers := ARRAY(SELECT value::BIGINT FROM json_array_elements_text(rec_json) AS value);

      RAISE NOTICE 'minLength: %, numbers: %', i, numbers;
      RAISE NOTICE 'expect.soft(sqids.encode(%)).toBe(%);', numbers, id;
      IF LENGTH(sqids.encode(numbers, default_alphabet, i)) >= i THEN
        RAISE NOTICE '  PASSED';
      ELSE
        RAISE NOTICE '  FAILED';
      END IF;

      IF sqids.decode(sqids.encode(numbers, default_alphabet, i), default_alphabet) = numbers THEN
        RAISE NOTICE '  PASSED';
      ELSE
        RAISE NOTICE '  FAILED';
      END IF;
    END LOOP;
 
  END LOOP;
  
END
$$ LANGUAGE plpgsql;