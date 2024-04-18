DROP SCHEMA IF EXISTS sqids CASCADE;
CREATE SCHEMA sqids;

CREATE TABLE sqids.blocklist(
  str TEXT PRIMARY KEY
);

CREATE OR REPLACE FUNCTION sqids.shuffle(alphabet TEXT) RETURNS TEXT AS $$
DECLARE
  chars TEXT[];
  i BIGINT;
  j BIGINT;
  r BIGINT;
  temp TEXT;
BEGIN
  chars := regexp_split_to_array(alphabet, '');
  i := 0;
  j := array_length(chars, 1) - 1;

  WHILE j > 0 LOOP
    r := (i * j + ascii(chars[i + 1]) + ascii(chars[j + 1])) % array_length(chars, 1);
    
    temp := chars[i + 1];
    chars[i + 1] := chars[r + 1];
    chars[r + 1] := temp;

    i := i + 1;
    j := j - 1;
  END LOOP;

  --raise notICE 'Shuffled alphabet: %', array_to_string(chars, '');
  RETURN array_to_string(chars, '');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sqids.isBlockedId(id TEXT) RETURNS BOOLEAN AS $$
DECLARE
  word TEXT;
BEGIN
  FOR word IN SELECT str FROM sqids.blocklist LOOP
    IF LENGTH(word) <= LENGTH(id) THEN
      IF LENGTH(id) <= 3 OR LENGTH(word) <= 3 THEN
        IF id = word THEN
          RETURN TRUE;
        END IF;
      ELSIF POSITION('\d' IN word) > 0 THEN
        IF id LIKE word || '%' OR id LIKE '%' || word THEN
          RETURN TRUE;
        END IF;
      ELSIF POSITION(word IN id) > 0 THEN
        RETURN TRUE;
      END IF;
    END IF;
  END LOOP;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sqids.toId(num BIGINT, alphabet TEXT) RETURNS TEXT AS $$
DECLARE
  id TEXT[];
  chars TEXT[];
  result BIGINT;
BEGIN
  id := ARRAY[]::TEXT[];
  chars := regexp_split_to_array(alphabet, '');
  result := num;

  WHILE result > 0 LOOP
    id := array_prepend(chars[(result % array_length(chars, 1)) + 1], id);
    result := (result / array_length(chars, 1))::BIGINT;
  END LOOP;

  RETURN array_to_string(id, '');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sqids.toNumber(id TEXT, alphabet TEXT) RETURNS BIGINT AS $$
DECLARE
  chars TEXT[];
  result BIGINT := 0;
  char TEXT;
  a BIGINT;
  v BIGINT;
BEGIN
  --raise notice 'id: %', id;
  --raise notice 'alphabet: %', alphabet;
  chars := regexp_split_to_array(alphabet, '');
  

  FOR i IN 1..length(id) LOOP
    char := substring(id from i for 1);
    --raise notice 'char: %', char;
    --raise notice 'result: %', result;
    --raise notice 'array_length(chars, 1): %', array_length(chars, 1);
    --raise notice 'array_position(chars, char): %', array_position(chars, char);
    result := result * array_length(chars, 1) + (array_position(chars, char) - 1);
  END LOOP;

  --raise notice 'tonumber result: %', result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sqids.encodeNumbers(numbers BIGINT[], alphabet TEXT, minLength INT, increment INT DEFAULT 0) RETURNS TEXT AS $$
DECLARE
  offset_var INT;
  arr_alphabet TEXT[];
  prefix TEXT;
  ret TEXT[];
  a BIGINT;
  v BIGINT;
  i BIGINT;
  num BIGINT;
  id TEXT;
  m BIGINT;
BEGIN
  IF increment > array_length(regexp_split_to_array(alphabet, ''), 1) THEN
    RAISE EXCEPTION 'Reached max attempts to re-generate the ID';
  END IF;

  IF increment = 0 THEN
    alphabet := sqids.shuffle(alphabet);
  END IF;
  arr_alphabet := regexp_split_to_array(alphabet, '');

  --raise notice 'arr_alphabet: %', arr_alphabet;
  a := array_length(numbers, 1);
  --raise notice 'Offset start: %', a;
  FOR i IN 0..(array_length(numbers, 1) - 1) LOOP
    v:= numbers[i + 1];
    --raise notice 'avi: % % %', a, v, i;
    m := v % array_length(arr_alphabet, 1);
    --raise notice 'm: %', m;
    a:= ascii(arr_alphabet[m + 1]) + i + a;
    --raise notice 'a: %', a;
  END LOOP;
  offset_var := a % array_length(arr_alphabet, 1);
    
  --raise notice 'Offset 1: %', offset_var;



  offset_var := (offset_var + increment) % array_length(arr_alphabet, 1);
  --raise notice 'Offset 2: %', offset_var;

  arr_alphabet := arr_alphabet[offset_var + 1:] || arr_alphabet[1:offset_var];
  --raise notice 'Sliced Alphabet: %', arr_alphabet;
  prefix := arr_alphabet[1];
  alphabet := array_to_string(arr_alphabet, '');
  alphabet := reverse(alphabet);
  arr_alphabet := regexp_split_to_array(alphabet, '');
  ret := ARRAY[prefix];

  --raise notice 'Alphabet: %', alphabet;
  --raise notice 'Prefix: %', prefix;
  --raise notice 'Ret: %', ret;

  FOR i IN 1..array_length(numbers, 1) LOOP
    num := numbers[i];
    ret := array_append(ret, sqids.toId(num, substring(alphabet FROM 2 FOR LENGTH(alphabet) - 1)));

    --raise notice 'ret: %', ret;

    IF i < array_length(numbers, 1) THEN
      ret := array_append(ret, substring(alphabet FROM 1 FOR 1));
      alphabet := sqids.shuffle(alphabet);
    END IF;
  END LOOP;

  id := array_to_string(ret, '');

  IF LENGTH(id) < minLength THEN
    id := id || substring(alphabet FROM 1 FOR 1);

    WHILE minLength - LENGTH(id) > 0 LOOP
      alphabet := sqids.shuffle(alphabet);
      id := id || substring(alphabet FROM 1 FOR LEAST(minLength - LENGTH(id), LENGTH(alphabet)));
    END LOOP;
  END IF;

  IF sqids.isBlockedId(id) THEN
    id := sqids.encodeNumbers(numbers, increment + 1, alphabet);
  END IF;

  RETURN id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sqids.decode(id TEXT, alphabet TEXT) RETURNS BIGINT[] AS $$
DECLARE
  ret BIGINT[];
  prefix TEXT;
  offset_var INT;
  i BIGINT;
  c TEXT;
  separator TEXT;
  chunks TEXT[];
  slicedId TEXT;
  num BIGINT;
BEGIN
  IF id = '' THEN
    RETURN ret;
  END IF;

  FOR i IN 1..LENGTH(id) LOOP
    c := substring(id FROM i FOR 1);
    IF POSITION(c IN alphabet) = 0 THEN
      RETURN ret;
    END IF;
  END LOOP;

  alphabet := sqids.shuffle(alphabet);

  prefix := substring(id FROM 1 FOR 1);
  offset_var := POSITION(prefix IN alphabet) - 1;

  --raise notice 'prefix: %', prefix;
  --raise notice 'offset_var: %', offset_var;

  alphabet := substring(alphabet FROM offset_var + 1 FOR LENGTH(alphabet) - offset_var) || substring(alphabet FROM 1 FOR offset_var);

  alphabet := reverse(alphabet);
  --raise notice 'Alphabet: %', alphabet;
  slicedId := substring(id FROM 2);

  --raise notice 'Sliced ID: %', slicedId;

  WHILE LENGTH(slicedId) > 0 LOOP
    separator := substring(alphabet FROM 1 FOR 1);
    --raise notice 'Separator: %', separator;
    chunks := regexp_split_to_array(slicedId, separator);
    --raise notice 'Chunks: %', chunks;

    IF array_length(chunks, 1) > 0 THEN
      IF chunks[1] = '' THEN
        RETURN ret;
      END IF;

      num := sqids.toNumber(chunks[1], substring(alphabet FROM 2 FOR LENGTH(alphabet) - 1));
      ret := array_append(ret, num);

      IF array_length(chunks, 1) > 1 THEN
        alphabet := sqids.shuffle(alphabet);
      END IF;
    END IF;

    slicedId := array_to_string(chunks[2:], separator);
  END LOOP;

  RETURN ret;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sqids.encode(numbers BIGINT[], alphabet TEXT, minLength INT DEFAULT 0) RETURNS TEXT AS $$
DECLARE
  id TEXT; 
BEGIN
  id := sqids.encodeNumbers(numbers, alphabet, minLength);
  RETURN id;
END;
$$ LANGUAGE plpgsql;

DELETE FROM sqids.blocklist;
INSERT INTO sqids.blocklist (str) VALUES
('0rgasm'),('1d10t'),('1d1ot'),('1di0t'),('1diot'),('1eccacu10'),('1eccacu1o'),('1eccacul0'),('1eccaculo'),('1mbec11e'),('1mbec1le'),('1mbeci1e'),('1mbecile'),('a11upat0'),('a11upato'),('a1lupat0'),('a1lupato'),('aand'),('ah01e'),('ah0le'),('aho1e'),('ahole'),('al1upat0'),('al1upato'),('allupat0'),('allupato'),('ana1'),('ana1e'),('anal'),('anale'),('anus'),('arrapat0'),('arrapato'),('arsch'),('arse'),('ass'),('b00b'),('b00be'),('b01ata'),('b0ceta'),('b0iata'),('b0ob'),('b0obe'),('b0sta'),('b1tch'),('b1te'),('b1tte'),('ba1atkar'),('balatkar'),('bastard0'),('bastardo'),('batt0na'),('battona'),('bitch'),('bite'),('bitte'),('bo0b'),('bo0be'),('bo1ata'),('boceta'),('boiata'),('boob'),('boobe'),('bosta'),('bran1age'),('bran1er'),('bran1ette'),('bran1eur'),('bran1euse'),('branlage'),('branler'),('branlette'),('branleur'),('branleuse'),('c0ck'),('c0g110ne'),('c0g11one'),('c0g1i0ne'),('c0g1ione'),('c0gl10ne'),('c0gl1one'),('c0gli0ne'),('c0glione'),('c0na'),('c0nnard'),('c0nnasse'),('c0nne'),('c0u111es'),('c0u11les'),('c0u1l1es'),('c0u1lles'),('c0ui11es'),('c0ui1les'),('c0uil1es'),('c0uilles'),('c11t'),('c11t0'),('c11to'),('c1it'),('c1it0'),('c1ito'),('cabr0n'),('cabra0'),('cabrao'),('cabron'),('caca'),('cacca'),('cacete'),('cagante'),('cagar'),('cagare'),('cagna'),('cara1h0'),('cara1ho'),('caracu10'),('caracu1o'),('caracul0'),('caraculo'),('caralh0'),('caralho'),('cazz0'),('cazz1mma'),('cazzata'),('cazzimma'),('cazzo'),('ch00t1a'),('ch00t1ya'),('ch00tia'),('ch00tiya'),('ch0d'),('ch0ot1a'),('ch0ot1ya'),('ch0otia'),('ch0otiya'),('ch1asse'),('ch1avata'),('ch1er'),('ch1ng0'),('ch1ngadaz0s'),('ch1ngadazos'),('ch1ngader1ta'),('ch1ngaderita'),('ch1ngar'),('ch1ngo'),('ch1ngues'),('ch1nk'),('chatte'),('chiasse'),('chiavata'),('chier'),('ching0'),('chingadaz0s'),('chingadazos'),('chingader1ta'),('chingaderita'),('chingar'),('chingo'),('chingues'),('chink'),('cho0t1a'),('cho0t1ya'),('cho0tia'),('cho0tiya'),('chod'),('choot1a'),('choot1ya'),('chootia'),('chootiya'),('cl1t'),('cl1t0'),('cl1to'),('clit'),('clit0'),('clito'),('cock'),('cog110ne'),('cog11one'),('cog1i0ne'),('cog1ione'),('cogl10ne'),('cogl1one'),('cogli0ne'),('coglione'),('cona'),('connard'),('connasse'),('conne'),('cou111es'),('cou11les'),('cou1l1es'),('cou1lles'),('coui11es'),('coui1les'),('couil1es'),('couilles'),('cracker'),('crap'),('cu10'),('cu1att0ne'),('cu1attone'),('cu1er0'),('cu1ero'),('cu1o'),('cul0'),('culatt0ne'),('culattone'),('culer0'),('culero'),('culo'),('cum'),('cunt'),('d11d0'),('d11do'),('d1ck'),('d1ld0'),('d1ldo'),('damn'),('de1ch'),('deich'),('depp'),('di1d0'),('di1do'),('dick'),('dild0'),('dildo'),('dyke'),('encu1e'),('encule'),('enema'),('enf01re'),('enf0ire'),('enfo1re'),('enfoire'),('estup1d0'),('estup1do'),('estupid0'),('estupido'),('etr0n'),('etron'),('f0da'),('f0der'),('f0ttere'),('f0tters1'),('f0ttersi'),('f0tze'),('f0utre'),('f1ca'),('f1cker'),('f1ga'),('fag'),('fica'),('ficker'),('figa'),('foda'),('foder'),('fottere'),('fotters1'),('fottersi'),('fotze'),('foutre'),('fr0c10'),('fr0c1o'),('fr0ci0'),('fr0cio'),('fr0sc10'),('fr0sc1o'),('fr0sci0'),('fr0scio'),('froc10'),('froc1o'),('froci0'),('frocio'),('frosc10'),('frosc1o'),('frosci0'),('froscio'),('fuck'),('g00'),('g0o'),('g0u1ne'),('g0uine'),('gandu'),('go0'),('goo'),('gou1ne'),('gouine'),('gr0gnasse'),('grognasse'),('haram1'),('harami'),('haramzade'),('hund1n'),('hundin'),('id10t'),('id1ot'),('idi0t'),('idiot'),('imbec11e'),('imbec1le'),('imbeci1e'),('imbecile'),('j1zz'),('jerk'),('jizz'),('k1ke'),('kam1ne'),('kamine'),('kike'),('leccacu10'),('leccacu1o'),('leccacul0'),('leccaculo'),('m1erda'),('m1gn0tta'),('m1gnotta'),('m1nch1a'),('m1nchia'),('m1st'),('mam0n'),('mamahuev0'),('mamahuevo'),('mamon'),('masturbat10n'),('masturbat1on'),('masturbate'),('masturbati0n'),('masturbation'),('merd0s0'),('merd0so'),('merda'),('merde'),('merdos0'),('merdoso'),('mierda'),('mign0tta'),('mignotta'),('minch1a'),('minchia'),('mist'),('musch1'),('muschi'),('n1gger'),('neger'),('negr0'),('negre'),('negro'),('nerch1a'),('nerchia'),('nigger'),('orgasm'),('p00p'),('p011a'),('p01la'),('p0l1a'),('p0lla'),('p0mp1n0'),('p0mp1no'),('p0mpin0'),('p0mpino'),('p0op'),('p0rca'),('p0rn'),('p0rra'),('p0uff1asse'),('p0uffiasse'),('p1p1'),('p1pi'),('p1r1a'),('p1rla'),('p1sc10'),('p1sc1o'),('p1sci0'),('p1scio'),('p1sser'),('pa11e'),('pa1le'),('pal1e'),('palle'),('pane1e1r0'),('pane1e1ro'),('pane1eir0'),('pane1eiro'),('panele1r0'),('panele1ro'),('paneleir0'),('paneleiro'),('patakha'),('pec0r1na'),('pec0rina'),('pecor1na'),('pecorina'),('pen1s'),('pendej0'),('pendejo'),('penis'),('pip1'),('pipi'),('pir1a'),('pirla'),('pisc10'),('pisc1o'),('pisci0'),('piscio'),('pisser'),('po0p'),('po11a'),('po1la'),('pol1a'),('polla'),('pomp1n0'),('pomp1no'),('pompin0'),('pompino'),('poop'),('porca'),('porn'),('porra'),('pouff1asse'),('pouffiasse'),('pr1ck'),('prick'),('pussy'),('put1za'),('puta'),('puta1n'),('putain'),('pute'),('putiza'),('puttana'),('queca'),('r0mp1ba11e'),('r0mp1ba1le'),('r0mp1bal1e'),('r0mp1balle'),('r0mpiba11e'),('r0mpiba1le'),('r0mpibal1e'),('r0mpiballe'),('rand1'),('randi'),('rape'),('recch10ne'),('recch1one'),('recchi0ne'),('recchione'),('retard'),('romp1ba11e'),('romp1ba1le'),('romp1bal1e'),('romp1balle'),('rompiba11e'),('rompiba1le'),('rompibal1e'),('rompiballe'),('ruff1an0'),('ruff1ano'),('ruffian0'),('ruffiano'),('s1ut'),('sa10pe'),('sa1aud'),('sa1ope'),('sacanagem'),('sal0pe'),('salaud'),('salope'),('saugnapf'),('sb0rr0ne'),('sb0rra'),('sb0rrone'),('sbattere'),('sbatters1'),('sbattersi'),('sborr0ne'),('sborra'),('sborrone'),('sc0pare'),('sc0pata'),('sch1ampe'),('sche1se'),('sche1sse'),('scheise'),('scheisse'),('schlampe'),('schwachs1nn1g'),('schwachs1nnig'),('schwachsinn1g'),('schwachsinnig'),('schwanz'),('scopare'),('scopata'),('sexy'),('sh1t'),('shit'),('slut'),('sp0mp1nare'),('sp0mpinare'),('spomp1nare'),('spompinare'),('str0nz0'),('str0nza'),('str0nzo'),('stronz0'),('stronza'),('stronzo'),('stup1d'),('stupid'),('succh1am1'),('succh1ami'),('succhiam1'),('succhiami'),('sucker'),('t0pa'),('tapette'),('test1c1e'),('test1cle'),('testic1e'),('testicle'),('tette'),('topa'),('tr01a'),('tr0ia'),('tr0mbare'),('tr1ng1er'),('tr1ngler'),('tring1er'),('tringler'),('tro1a'),('troia'),('trombare'),('turd'),('twat'),('vaffancu10'),('vaffancu1o'),('vaffancul0'),('vaffanculo'),('vag1na'),('vagina'),('verdammt'),('verga'),('w1chsen'),('wank'),('wichsen'),('x0ch0ta'),('x0chota'),('xana'),('xoch0ta'),('xochota'),('z0cc01a'),('z0cc0la'),('z0cco1a'),('z0ccola'),('z1z1'),('z1zi'),('ziz1'),('zizi'),('zocc01a'),('zocc0la'),('zocco1a'),('zoccola');