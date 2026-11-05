#!/usr/bin/env bash
# Run the test suite headlessly. Exit code 0 = all green.
# Each spec runs in its own Neovim instance (the harness quits nvim when done).
set -euo pipefail
cd "$(dirname "$0")/.."

run_spec() {
	# -es: silent ex-mode (prevents hanging on error). The spec is wrapped in
	# pcall so any failure — a crash mid-spec or failed assertions — is
	# printed to stdout and exits non-zero.
	nvim --headless -es --clean \
		-c 'lua vim.opt.rtp:append(".")' \
		-c "lua local ok, err = pcall(dofile, 'tests/$1'); if not ok then io.stdout:write('ERROR: ' .. tostring(err) .. '\n'); vim.cmd('cquit!') end" \
		-c 'qa'
}

run_spec codec_spec.lua
run_spec buffer_spec.lua
