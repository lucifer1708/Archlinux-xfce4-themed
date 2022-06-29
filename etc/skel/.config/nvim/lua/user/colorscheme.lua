vim.cmd([[
try
  colorscheme onedarkpro
catch /^Vim\%((\a\+)\)\=:E185/
   " colorscheme default
  set background=dark
  highlight Normal guibg=black guifg=white
endtry
]])
-- This is a comment
