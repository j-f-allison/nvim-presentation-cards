if vim.g.loaded_nvim_presenter then
  return
end
vim.g.loaded_nvim_presenter = true

vim.api.nvim_create_user_command('PresenterStart', function()
  require('nvim-presenter').start()
end, {
  desc = 'Start (or reopen) the speaker-notes presenter view for the current buffer',
})

vim.api.nvim_create_user_command('PresenterStop', function()
  require('nvim-presenter').stop()
end, {
  desc = 'Stop the presenter server',
})
