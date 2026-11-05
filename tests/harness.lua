-- Minimal zero-dependency test harness for headless Neovim.
-- Each spec file does: local T = dofile('tests/harness.lua')
-- and ends with: T.finish()
--
-- Exit code is handled by tests/run.sh (pcall wrapper + :cquit on failure).

local T = {}
T.passed = 0
T.failed = 0
T.failures = {}

function T.eq(actual, expected, msg)
	if actual == expected then
		T.passed = T.passed + 1
	else
		T.failed = T.failed + 1
		T.failures[#T.failures + 1] = string.format(
			'%s\n    expected: %s\n    actual:   %s',
			msg, vim.inspect(expected), vim.inspect(actual)
		)
	end
end

function T.ok(cond, msg)
	if cond then
		T.passed = T.passed + 1
	else
		T.failed = T.failed + 1
		T.failures[#T.failures + 1] = 'not ok: ' .. msg
	end
end

local function out(s)
	io.stdout:write(s, '\n')
end

-- Prints the result. The runner (tests/run.sh) wraps the whole spec in
-- pcall, so quitting/exit-codes are handled there, not here.
function T.finish()
	out(string.format('%d passed, %d failed', T.passed, T.failed))
	for _, f in ipairs(T.failures) do
		out('FAIL: ' .. f)
	end
	if T.failed > 0 then
		error(string.format('%d test(s) failed', T.failed), 0)
	end
end

return T
