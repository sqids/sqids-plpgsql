# [Sqids PLpgSQL](https://sqids.org/plpgsql)

[Sqids](https://sqids.org/plpgsql) (pronounced "squids") is a small library that lets you **generate unique IDs from numbers**. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [40+ programming languages](https://sqids.org/)

## 🧰 Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

## 🚀 Getting started

### Important notes

> **Note**
> 🚧 The `src/install.sql` file is idempotent but destructive. It will `DROP SCHEMA sqids` so be sure you aren't using a schema with that name!

The blocklist is stored in a table. If you need it to somehow be dynamic per-call, you can likely use transactions, but I have not tested it.

### Compatibility

Written & tested on Postgres 15.6. The functions used are pretty simple - it will likely work on 9+ (definitely not earlier). Be sure to install & run tests!

### Installation

Simply run `src/install.sql` on your database.

## 👩‍💻 Examples

After install, use encode & decode:

encode takes an array of BIGINT, an alphabet, and an optional minLength.

```sql
select sqids.encode(array[123, 456, 789], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 12); -- EBDQWDLPCTHG
```

decode requires the id and alphabet. It returns an array of BIGINT.

```sql
select sqids.decode('EBDQWDLPCTHG', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'); -- {123,456,789}
```

## 🧪 Testing

Run the sql files in tests dir to install.

Then run:

```sql
select sqids.alphabet_test();
select sqids.blocklist_test();
select sqids.encoding_test();
select sqids.minlength_test();
```

## 📝 License

[MIT](LICENSE)