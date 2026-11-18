local CASCADE_JOKER_TABLE = {}

-- How many copies each joker will make
local JOKER_AMOUNT = 50

function jokers_cascade()
  -- Generate a cascade for each joker
  for index = 1, #G.jokers.cards do
    generate_individual_joker_cascade(index)
  end

  -- Setup a delay before emptying the cascade
  local delete_cascade_cards_delay = 4
  delay(delete_cascade_cards_delay)

  -- Empty the cascade
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    func = function()
      empty_cascade()
      return true
    end
  }))
end

function empty_cascade()
  for i = #CASCADE_JOKER_TABLE, 1, -1 do
    CASCADE_JOKER_TABLE[i]:remove()
  end
  for _, card in ipairs(G.jokers.cards) do
      card._3axux_fast_cascade = false
  end
end

-- Make a cascade for an indexed joker
function generate_individual_joker_cascade(index)
  local joker = G.jokers.cards[index]
  local current_joker_center = joker.config.center
  local coord_table = get_cascade_coord_table(index)
  local card_to_card_delay = 0.01

  for i,coords in ipairs(coord_table) do
    delay(card_to_card_delay)
    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      func = function()
        local card = Card(coords.x, coords.y, G.CARD_W, G.CARD_H, nil, current_joker_center)
        card.ability.eternal = joker.ability.eternal
        card.ability.rental = joker.ability.rental
        card.ability.perishable = joker.ability.perishable
        if joker.edition then
          card:set_edition("e_"..joker.edition.type,true,true)
        end

        update_cascade_table(card)

        -- Sound effects
        if coord_table[i+1] and coord_table[i+1].y < coords.y 
           and coord_table[i-1] and coord_table[i-1].y <= coords.y 
           or not coord_table[i+1] then
          play_sound('voice'..math.random(1, 11), G.SPEEDFACTOR*(math.random()*0.2+1), 0.5)
        end
        return true
      end
    }))
  end
end

function update_cascade_table(card)
  CASCADE_JOKER_TABLE[#CASCADE_JOKER_TABLE + 1] = card
end

function get_cascade_coord_table(index)
  local current_joker = G.jokers.cards[index]
  
  local result_table = {}
  local starting_pos = {x = current_joker.CT.x, y = current_joker.CT.y}
  result_table[#result_table + 1] = starting_pos
  
  local height = 9.6 -- pretty much set in stone
  local width = pseudorandom("",8, 20)
  local bounces = math.max(2, math.floor(width / 4 + pseudorandom("",-1.0, 1.0) + 0.5))
  local damping = pseudorandom("",0.3, 0.7) + (6 - bounces) * 0.45
  local dx = width / JOKER_AMOUNT
  local final_corner = { x = result_table[#result_table].x + width, y = result_table[#result_table].y + height }
  
  bounce_table(result_table, final_corner, height, bounces, damping, dx)

  return result_table
end

function bounce_table(table, final_pos, amplitude, frequency, damping, dx)
    local p0 = table[#table]
    local p1 = final_pos
    
    local H = p1.y - p0.y
    local W = p1.x - p0.x
 
    local n = math.max(1, math.ceil(math.abs(W) / dx))
    local falling_down = true

    for i = 1, n do
        local t = i / n
        local x = p0.x + W * t

        local y = p1.y - H
                  * math.exp(-damping * t)
                  * math.abs(math.cos((frequency + 0.5) * math.pi * t))

        table[#table+1] = { x = x, y = y }

        -- make all bottom cards line up
        if table[#table].y < table[#table - 1].y and falling_down then
          falling_down = false
          table[#table - 1].y = p1.y
        elseif table[#table].y > table[#table - 1].y then
          falling_down = true
        end
    end

    table[#table].x = p1.x
    table[#table].y = p1.y

    return table
end


local old_win_game = win_game
function win_game()
  -- If cascade is enabled
  if SMODS.Mods['3axux'].config.cascade ~= 1 then
    -- Fast cascade mode
    if SMODS.Mods['3axux'].config.cascade == 3 then
      -- make jokers cascadely
      for _, card in ipairs(G.jokers.cards) do
        card._3axux_fast_cascade = true  
      end
    end
    
    jokers_cascade()    
  end  

  G.E_MANAGER:add_event(Event({
  trigger = 'after',
  func = function()
    old_win_game()

    return true
  end
  }))
end

local function is_fast_cascade_active()
  -- Option is selected
  if not SMODS.Mods['3axux'].config.cascade == 3 then
    return false
  end

  -- During game
  if not G or not G.jokers or not G.jokers.cards then
    return false
  end

  -- Jokers have that property - cannot jump from one game to the other
  for _, card in ipairs(G.jokers.cards) do
    if card._3axux_fast_cascade then
      return true
    end
  end

  return false
end

-- Speed up the game for a faster cascade
function event_manager_update(dt)
  G.E_MANAGER:update(dt)
  timer_checkpoint('e_manager', 'update')
end

local old_update = love.update
function love.update(dt)
    old_update(dt)

    if is_fast_cascade_active() then
      for i=1,7 do
        if not is_fast_cascade_active() then break end
        event_manager_update(dt)
      end
    end
end

-- Cashout button now turns off joker's custom fast ability
local old_cash_out = G.FUNCS.cash_out
function G.FUNCS.cash_out(e)
  old_cash_out(e)

  if G and G.jokers and G.jokers.cards then
    for _, card in ipairs(G.jokers.cards) do
      card._3axux_fast_cascade = false
    end
  end
end

-- Functionality for the config tab 
function G.FUNCS.set_cascade(args)
    SMODS.Mods['3axux'].config.cascade = args.to_key
end