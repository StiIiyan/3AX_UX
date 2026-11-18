
CASCADE_3AXUX = {
  JOKER_TABLE = {},
  JOKER_AMOUNT = 50, -- How many copies each joker will cascade into
  -- The entire cascade functionality
  jokers_cascade = function(self)
    self.JOKER_TABLE = {}

    -- Generate a cascade for each joker
    for index = 1, #G.jokers.cards do
      self:generate_individual_joker_cascade(index)
    end

    -- Setup a delay before emptying the cascade
    local delete_cascade_cards_delay = 4
    delay(delete_cascade_cards_delay)

    -- Empty the cascade
    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      func = function()
        self:empty_cascade()
        return true
      end
    }))
  end,
  -- Emptying the created objects at the end of the cascade
  empty_cascade = function(self)
    for i = #self.JOKER_TABLE, 1, -1 do
      local card = self.JOKER_TABLE[i]
      if card then
          card:remove()
      end
      self.JOKER_TABLE[i] = nil
    end
    for _, card in ipairs(G.jokers.cards) do
        card._3axux_fast_cascade = nil
    end
  end,
  fast_cascade_option = function(self)
    return SMODS.Mods['3axux'].config.cascade == 3
  end,
  enabled_cascade_option = function(self)
    return SMODS.Mods['3axux'].config.cascade > 1
  end,
  is_fast_cascade_active = function(self)
    -- Option is selected
    if not self:fast_cascade_option() then
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
  end,
  get_cascade_coord_table = function(self, index)
    local current_joker = G.jokers.cards[index]
    
    local result_table = {}
    local starting_pos = {x = current_joker.CT.x, y = current_joker.CT.y}
    result_table[#result_table + 1] = starting_pos
    
    local height = 9.6 -- pretty much set in stone
    local width = pseudorandom("",8, 20)
    local bounces = math.max(2, math.floor(width / 4 + pseudorandom("",-1.0, 1.0) + 0.5))
    local damping = pseudorandom("",0.3, 0.7) + (6 - bounces) * 0.45
    local dx = width / self.JOKER_AMOUNT
    local final_corner = { x = result_table[#result_table].x + width, y = result_table[#result_table].y + height }
    
    self:bounce_table(result_table, final_corner, height, bounces, damping, dx)

    return result_table
  end,
  generate_individual_joker_cascade = function(self, index)
    local joker = G.jokers.cards[index]
    local current_joker_center = joker.config.center
    local coord_table = self:get_cascade_coord_table(index)
    local card_to_card_delay = 0.01

    for i,coords in ipairs(coord_table) do
      delay(card_to_card_delay)
      G.E_MANAGER:add_event(Event({
        trigger = 'after',
        func = function()
          -- Make an exact copy of the card -- TODO perished cards? (X) (X) (X) (X)
          local card = Card(coords.x, coords.y, G.CARD_W, G.CARD_H, nil, current_joker_center)
          card.ability.eternal = joker.ability.eternal
          card.ability.rental = joker.ability.rental
          card.ability.perishable = joker.ability.perishable
          if joker.edition then
            card:set_edition("e_"..joker.edition.type,true,true)
          end

          -- Add the copy to the cascade table
          self:update_cascade_table(card)

          -- Sound effects when bouncing
          if coord_table[i+1] and coord_table[i+1].y < coords.y 
            and coord_table[i-1] and coord_table[i-1].y <= coords.y 
            or not coord_table[i+1] then
            play_sound('voice'..math.random(1, 11), G.SPEEDFACTOR*(math.random()*0.2+1), 0.5)
          end
          return true
        end
      }))
    end
  end,
  update_cascade_table = function(self, card)
    self.JOKER_TABLE[#self.JOKER_TABLE + 1] = card
  end,
  bounce_table = function(self, table, final_pos, amplitude, frequency, damping, dx)
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
  end,  
}

-- Cascade begins when the game is won
local old_win_game = win_game
function win_game()
  -- If cascade is enabled
  if CASCADE_3AXUX:enabled_cascade_option() then
    -- Fast cascade mode
    if CASCADE_3AXUX:fast_cascade_option() then
      -- Give jokers special flag
      for _, card in ipairs(G.jokers.cards) do
        card._3axux_fast_cascade = true  
      end
    end
    
    CASCADE_3AXUX:jokers_cascade()    
  end  

  G.E_MANAGER:add_event(Event({
  trigger = 'after',
  func = function()
    old_win_game()

    return true
  end
  }))
end

-- Speed up the game for a faster cascade
function event_manager_update(dt)
  G.E_MANAGER:update(dt)
  timer_checkpoint('e_manager', 'update')
end

local old_update = love.update
function love.update(dt)
    old_update(dt)

    if CASCADE_3AXUX:is_fast_cascade_active() then
      for i=1,7 do
        if not CASCADE_3AXUX:is_fast_cascade_active() then break end
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
      card._3axux_fast_cascade = nil
    end
    if CASCADE_3AXUX:is_fast_cascade_active() then -- TODO remove, for debugging
      
    end
  end
end

-- Functionality for the config tab 
function G.FUNCS.set_cascade(args)
    SMODS.Mods['3axux'].config.cascade = args.to_key
end