local CASCADE_JOKER_TABLE = {}

local JOKER_AMOUNT = 50

function jokers_cascade()
  for index = 1, #G.jokers.cards do
    generate_individual_joker_cascade(index)
  end

  local delete_cascade_cards_delay = 4
  delay(delete_cascade_cards_delay)

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
end

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

        --sounds
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

  if SMODS.Mods['3axux'].config.cascade == 2 then
    if #CASCADE_JOKER_TABLE > JOKER_AMOUNT then
      CASCADE_JOKER_TABLE[#CASCADE_JOKER_TABLE - JOKER_AMOUNT]:remove()
    end
  end
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
  if SMODS.Mods['3axux'].config.cascade ~= 1 then
    jokers_cascade()
  end
    
  old_win_game()
end

function G.FUNCS.set_cascade(args)
    SMODS.Mods['3axux'].config.cascade = args.to_key
end