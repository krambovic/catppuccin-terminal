-- Catppuccin Terminal setup for Clink (CMD)
os.execute("@chcp 65001 >nul")
local home = os.getenv("USERPROFILE") or ""
local ompConfig = home .. "\\.config\\oh-my-posh\\catppuccin-mocha.omp.json"

-- Fastfetch banner on startup (for interactive CMD sessions)
local fastfetch_shown = false
if clink and clink.onbeginedit then
    clink.onbeginedit(function()
        if not fastfetch_shown and not os.getenv("CATPPUCCIN_CMD_FASTFETCH_SHOWN") then
            fastfetch_shown = true
            os.setenv("CATPPUCCIN_CMD_FASTFETCH_SHOWN", "1")
            os.execute("cls && fastfetch && echo.")
        end
    end)
end

-- Initialize Oh My Posh prompt
local cmd = 'oh-my-posh init cmd --config "' .. ompConfig .. '"'
local handle = io.popen(cmd)
if handle then
    local res = handle:read("*a")
    handle:close()
    if res and #res > 0 then
        load(res)()
    end
end