-- Unit tests for jproperty.codec (pure line-level functions).
-- Run via tests/run.sh (headless Neovim, repo root as cwd).

local T = dofile('tests/harness.lua')
local codec = require('jproperty.codec')

-- === decode_line ===

T.eq(codec.decode_line('\\u0131'), 'ı', 'decode: single escape \\u0131')
T.eq(codec.decode_line('a\\u00E7b'), 'açb', 'decode: escape inside text')
T.eq(codec.decode_line('\\ud83d\\ude00'), '😀', 'decode: valid surrogate pair')
T.eq(codec.decode_line('\\ud800'), '\\ud800', 'decode: lone high surrogate untouched')
T.eq(codec.decode_line('\\udc00'), '\\udc00', 'decode: lone low surrogate untouched')
T.eq(codec.decode_line('\\ud800\\ud800'), '\\ud800\\ud800', 'decode: two high surrogates untouched')
T.eq(codec.decode_line('\\uG131'), '\\uG131', 'decode: invalid hex untouched')
T.eq(codec.decode_line('\\U0131'), '\\U0131', 'decode: uppercase \\U untouched')
T.eq(codec.decode_line('a\\nb'), 'a\\nb', 'decode: backslash-n untouched')
T.eq(codec.decode_line('x\\'), 'x\\', 'decode: trailing backslash untouched')
T.eq(codec.decode_line('plain'), 'plain', 'decode: plain text unchanged')
T.eq(codec.decode_line(''), '', 'decode: empty line')

-- === encode_line ===

T.eq(codec.encode_line('abc'), 'abc', 'encode: ASCII passthrough')
T.eq(codec.encode_line('ç'), '\\u00E7', 'encode: U+00E7 (0x80-0xFF range) escaped')
T.eq(codec.encode_line('€'), '\\u20AC', 'encode: BMP character escaped')
T.eq(codec.encode_line('😀'), '\\uD83D\\uDE00', 'encode: supplementary character as surrogate pair')
T.eq(codec.encode_line('a\xC3'), 'a\\u00C3', 'encode: malformed trailing byte escaped as-is')
T.eq(codec.encode_line('\xC3'), '\\u00C3', 'encode: lone 2-byte lead byte escaped as-is')
T.eq(codec.encode_line('\x80'), '\\u0080', 'encode: lone continuation byte escaped as-is')
T.eq(codec.encode_line(''), '', 'encode: empty line')

-- === round-trip ===

local rt = 'ç€😀'
T.eq(codec.decode_line(codec.encode_line(rt)), rt, 'round-trip: decode(encode(line)) == line for cp > 0x7F')

T.finish()
