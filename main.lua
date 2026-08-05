-- Load all implementations

local foo_src = NFS.getDirectoryItems(SMODS.current_mod.path .. "implementations")
for _, file in ipairs(foo_src) do
    assert(SMODS.load_file("implementations/" .. file))()
end