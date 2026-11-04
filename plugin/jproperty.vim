" jproperty.vim -- Java .properties Unicode escape encoder/decoder
"
" Provides two commands:
"   :DecodeJavaProps  – replace \uXXXX escapes with actual characters
"   :EncodeJavaProps  – replace non-Latin-1 characters with \uXXXX escapes
"
" Both operations act on the current buffer and are undoable with 'u'.

command! DecodeJavaProps
			\ lua require('jproperty').decode(vim.api.nvim_get_current_buf())

command! EncodeJavaProps
			\ lua require('jproperty').encode(vim.api.nvim_get_current_buf())
