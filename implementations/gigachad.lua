-- Add sprites for Hanging Chad retriggers
SMODS.Atlas{
    key = "j_chads",
    path = "chads.png",
    px = 71,
    py = 95
}

SMODS.Joker:take_ownership('hanging_chad',
{
    no_mod_badges = true,
    key = "hanging_chad",
    atlas = 'j_chads',
    pos = {x = 0, y = 0},
    config = { extra = 2, sprite_pos = 0 },
})

function TryChangeChadSprite(joker_card)
    if not joker_card or not joker_card.ability or joker_card.ability.name ~= "Hanging Chad" then return end
    
    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
    G.E_MANAGER:add_event(Event({
        trigger = 'before',
        delay = 0.0,
        func = (function()
            joker_card.ability.sprite_pos = (joker_card.ability.sprite_pos + 1) % 4
            local sprite_id
            if joker_card.ability.sprite_pos % 2 == 0 then 
                    sprite_id = 0
            else
                    sprite_id = math.floor(1 + joker_card.ability.sprite_pos / 2)
            end
            joker_card.children.center:set_sprite_pos({x = sprite_id, y = 0})
            return true
        end)
    }))
end

local old_calc_individ_effect = SMODS.calculate_individual_effect
function SMODS.calculate_individual_effect(effect, scored_card, key, amount, from_edition)
    TryChangeChadSprite(effect.card)
    
    return old_calc_individ_effect(effect, scored_card, key, amount, from_edition)
end