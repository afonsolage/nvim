return {
  "j-hui/fidget.nvim",
  opts = {
    progress = {
        ignore_done_already = true,
        ignore = { "null-ls" },
        display = {
          progress_ttl = 60,
          render_limit = 10,
        },
    },
    notification = {
        override_vim_notify = true,
    },
  },
}
