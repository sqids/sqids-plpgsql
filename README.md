# [Sqids PLpgSQL](https://sqids.org/plpgsql)

Sqids (pronounced "squids") is a small library that lets you generate YouTube-looking IDs from numbers. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

## Getting started

### Important note

The install.sql file is idempotent but destructive. It will DROP SCHEMA sqids so be sure you aren't using a schema with that name!

### Installation

Simply run install.sql on your database.

## Examples

After install, use encode & decode:

encode takes an array of BIGINT, an alphabet, and an optional minLength.

postgres=# select sqids.encode(array[123, 456, 789], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 12);
    encode    
--------------
 EBDQWDLPCTHG
(1 row)

decode requires the id and alphabet. It returns an array of BIGINT.

postgres=# select sqids.decode('EBDQWDLPCTHG', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    decode     
---------------
 {123,456,789}
(1 row)


## License

[MIT](LICENSE)
