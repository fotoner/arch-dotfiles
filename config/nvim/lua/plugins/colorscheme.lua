-- 데스크톱 테마(Catppuccin Mocha)와 색을 맞춘다. LazyVim 기본(tokyonight)으로 돌아가려면 이 파일을 지운다
return {
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
