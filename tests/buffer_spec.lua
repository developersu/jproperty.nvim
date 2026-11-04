-- Buffer-level tests for jproperty (M.decode / M.encode).
-- Run via tests/run.sh (headless Neovim, repo root as cwd).

local T = dofile('tests/harness.lua')
local jproperty = require('jproperty')

local function is_ascii(s)
	return s:find('[\128-\255]') == nil
end

local function transform(lines, fn)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	fn(buf)
	local out = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	vim.api.nvim_buf_delete(buf, {force = true})
	return out
end

-- === encode: output must be pure ASCII, round-trip must be identity ===

local sample = {
	'a=ç',                 -- 2-byte character
	'b=€',                 -- 3-byte character
	'c=😀',                -- 4-byte character
	'd=ç€😀 mixed',        -- mixed
}

local enc = transform(sample, jproperty.encode)
for i, line in ipairs(enc) do
	T.ok(is_ascii(line), 'encode: output line ' .. i .. ' is pure ASCII (' .. line .. ')')
end
T.eq(enc[1], 'a=\\u00E7', 'encode: buffer U+00E7 escaped')
T.eq(enc[3], 'c=\\uD83D\\uDE00', 'encode: buffer supplementary as surrogate pair')

local back = transform(enc, jproperty.decode)
for i = 1, #sample do
	T.eq(back[i], sample[i], 'buffer round-trip line ' .. i)
end

-- === decode: escapes to characters, lone surrogates preserved ===

local escaped = {
	'a=\\u00E7',
	'b=\\u20AC',
	'c=\\uD83D\\uDE00',
	'd=\\ud800',
	'e=plain',
}
local dec = transform(escaped, jproperty.decode)
T.eq(dec[1], 'a=ç', 'decode: buffer escaped character')
T.eq(dec[2], 'b=€', 'decode: buffer escaped BMP character')
T.eq(dec[3], 'c=😀', 'decode: buffer escaped surrogate pair')
T.eq(dec[4], 'd=\\ud800', 'decode: buffer lone surrogate preserved')
T.eq(dec[5], 'e=plain', 'decode: buffer ASCII unchanged')

-- === testdata: real .properties file (already in escaped form) ===

local data = vim.fn.readfile('/tests/testdata/test.properties')

-- Encoding an already-escaped file must be a no-op (pure ASCII in/out).
local enc2 = transform(data, jproperty.encode)
T.eq(#enc2, #data, 'testdata: line count preserved')
for i = 1, #data do
	T.eq(enc2[i], data[i], 'testdata: encode is idempotent on line ' .. i)
end

-- decode(encode(decoded)) must reproduce the original escaped form.
local dec2 = transform(data, jproperty.decode)
T.ok(not is_ascii(dec2[1]), 'testdata: decode actually produces non-ASCII')
local reenc = transform(dec2, jproperty.encode)
for i = 1, #data do
	T.eq(reenc[i], data[i], 'testdata: encode(decode(line ' .. i .. ')) == original')
end

T.finish()
