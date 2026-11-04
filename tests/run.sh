#!/usr/bin/env bash
# Run the test suite headlessly. Exit code 0 = all green.
# Each spec runs in its own Neovim instance (the harness quits nvim when done).
set -euo pipefail
cd "$(dirname "$0")/.."

run_spec() {
	# -es: silent ex-mode, so a lua error exits non-zero instead of hanging.
	nvim --headless -es --clean \
		-c 'lua vim.opt.rtp:append(".")' \
		-c "luafile tests/$1" \
		-c 'qa'
}

run_spec codec_spec.lua
run_spec buffer_spec.lua
