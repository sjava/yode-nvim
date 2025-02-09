local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local R = require('yode-nvim.deps.lamda.dist.lamda')

local getFileBufferName = function(fileBufferId, seditorBufferId)
    local ext = vim.fn.expand('#' .. fileBufferId .. ':e')
    if ext ~= '' then
        ext = '.' .. ext
    end
    return vim.fn.bufname(fileBufferId) .. ':' .. seditorBufferId .. ext .. '*.yode'
end

local createSeditor = function(opts)
    local log = logging.create('createSeditor')

    local fileBufferId = vim.fn.bufnr('%')
    local text = vim.api.nvim_buf_get_lines(fileBufferId, opts.firstline - 1, opts.lastline, true)
    log.debug(fileBufferId, #text, text[1])
    local startLine = opts.firstline - 1
    local indentCount = h.getIndentCount(text)
    local cleanedText = h.map(R.drop(indentCount), text)

    --vim.cmd("call neomake#log#debug('## before creating buffer " .. vim.fn.bufnr('%') .. "')")
    local seditorBufferId = vim.api.nvim_create_buf(true, false)
    seditors.actions.initSeditor({
        seditorBufferId = seditorBufferId,
        data = {
            fileBufferId = fileBufferId,
            startLine = startLine,
            indentCount = indentCount,
        },
    })
    --vim.cmd("call neomake#log#debug('## after creating buffer " .. vim.fn.bufnr('%') .. "')")
    vim.bo[seditorBufferId].ft = vim.bo[fileBufferId].ft
    vim.bo[seditorBufferId].buftype = 'acwrite'
    -- TODO workaround! it seems this isn't set by my editorconfig plugin for
    -- these buffers. seditors get inserted instead of spaces in seditors. In
    -- normal file buffers it spaces get inserted.
    vim.bo[seditorBufferId].expandtab = true

    vim.api.nvim_buf_set_lines(seditorBufferId, 0, -1, true, cleanedText)
    vim.bo[seditorBufferId].modified = false

    local name = getFileBufferName(fileBufferId, seditorBufferId)
    vim.api.nvim_buf_call(seditorBufferId, function()
        vim.cmd('file ' .. name)
        vim.cmd([[
            nmap <buffer> <leader>bll :YodeGoToAlternateBuffer<cr>
            imap <buffer> <leader>bll <esc>:YodeGoToAlternateBuffer<cr>
            nmap <buffer> <leader>blt :YodeGoToAlternateBuffer t<cr>
            imap <buffer> <leader>blt <esc>:YodeGoToAlternateBuffer t<cr>
            nmap <buffer> <leader>blz :YodeGoToAlternateBuffer z<cr>
            imap <buffer> <leader>blz <esc>:YodeGoToAlternateBuffer z<cr>
            nmap <buffer> <leader>blb :YodeGoToAlternateBuffer b<cr>
            imap <buffer> <leader>blb <esc>:YodeGoToAlternateBuffer b<cr>
        ]])
    end)
    return seditorBufferId
end

return createSeditor
