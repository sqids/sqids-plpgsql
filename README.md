# [Sqids PLpgSQL](https://sqids.org/plpgsql)

Sqids (pronounced "squids") is a small library that lets you generate YouTube-looking IDs from numbers. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

## Getting started

### Important notes

The install.sql file is idempotent but destructive. It will DROP SCHEMA sqids so be sure you aren't using a schema with that name!

The blocklist is stored in a table. If you need it to somehow be dynamic per-call, you can likely use transactions, but I have not tested it.

### Compatibility

Written & tested on Postgres 15.6. The functions used are pretty simple - it will likely work on 9+ (definitely not earlier). Be sure to install & run tests!

### Installation

Simply run install.sql on your database.

## Examples

After install, use encode & decode:

encode takes an array of BIGINT, an alphabet, and an optional minLength.

select sqids.encode(array[123, 456, 789], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 12);

EBDQWDLPCTHG

decode requires the id and alphabet. It returns an array of BIGINT.

select sqids.decode('EBDQWDLPCTHG', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

{123,456,789}

## Testing

Run the sql files in tests dir to install.
Then run:
select sqids.alphabet_test();
select sqids.blocklist_test();
select sqids.encoding_test();
select sqids.minlength_test();


## License

[MIT](LICENSE)
