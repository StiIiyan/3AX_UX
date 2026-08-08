-- Load all implementations

local foo_src = NFS.getDirectoryItems(SMODS.current_mod.path .. "implementations")
for _, file in ipairs(foo_src) do
    assert(SMODS.load_file("implementations/" .. file))()
end




SMODS.current_mod.config_tab = function()
  return {n=G.UIT.ROOT, config = {align = 'cm', padding = 0.05, r = 0.1, colour = G.C.CLEAR}, nodes = {
      create_option_cycle({w = 4, scale = 0.8, label = 'Card Cascade', options = {'No','Optimized','Yes'}, opt_callback = 'set_cascade', current_option = SMODS.Mods['3axux'].config.cascade or 3}),
      create_toggle({label = 'Gigachad', ref_table = SMODS.Mods['3axux'].config, ref_value = 'gigachad', current_option = SMODS.Mods['3axux'].config.gigachad or true}),
      create_toggle({label = 'Custom Cursor', ref_table = SMODS.Mods['3axux'].config, ref_value = 'custom_cursor', current_option = SMODS.Mods['3axux'].config.custom_cursor or true}),
      create_slider({label = 'Sensitivity', w = 4, h = 0.4, ref_table = SMODS.Mods['3axux'].config, ref_value = 'default_sensitivity', callback = 'reset_sensitivity', min = 0.5, max = 2, decimal_places = 2, current_option = SMODS.Mods['3axux'].config.default_sensitivity or 1}),
      create_option_cycle({w = 4, scale = 0.8, label = 'M1 Cursor', options = {'Four Fingers','Banner','Cloud 9','Arrowhead','Gros Michel','Bootstraps','Ceremonial Dagger','Rocket','Seltzer'}, opt_callback = 'set_m1_cursor', current_option = SMODS.Mods['3axux'].config.cursor_index or 1}),
      create_toggle({label = 'Held Cursor', ref_table = SMODS.Mods['3axux'].config, ref_value = 'is_m1_held', current_option = SMODS.Mods['3axux'].config.is_m1_held or true}),
      create_option_cycle({w = 4, scale = 0.8, label = 'Held Cursor', options = {'Fist','Bean','Egg','Oops','Bull','8 ball','Square','Delayed Grat'}, opt_callback = 'set_m1_held_cursor', current_option = SMODS.Mods['3axux'].config.held_cursor_index or 1}),
  }}
end