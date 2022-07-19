--- Floating Health Mod
--- Uses locale floating-health.cfg
--- @usage require('modules/floating-health')
--- @author Denis Zholob (DDDGamer)
--- @see github: https://github.com/deniszholob/factorio-mod-floating-health
--- ======================================================================== ---

--- Dependencies ---
--- ======================================================================== ---
-- stdlib
local Event = require('__stdlib__/stdlib/event/event')
-- util
local Colors = require('util/Colors')

--- Constants --
--- ======================================================================== ---
DDD_Floating_Health = {
  HP_LOW = 30,
  HP_MID = 50,
  HP_HIGH = 80,

  -- REFRESH_PERIOD = 2, -- seconds
  REFRESH_PERIOD = settings.global['ddd_floating_health_settings_refresh_period'].value,
}

--- Event Functions ---
--- ======================================================================== ---

--- When a player changes mod settings
--- @param event EventData.on_runtime_mod_setting_changed defines.events.on_runtime_mod_setting_changed
function DDD_Floating_Health.on_runtime_mod_setting_changed(event)
  local player = game.players[event.player_index]

  if (event.setting == 'ddd_floating_health_settings_refresh_period') then
    DDD_Floating_Health.REFRESH_PERIOD = settings.global[event.setting].value
  end
end

--- On tick go through all the players and see if need to display health text
--- @param event EventData.on_tick defines.events.on_tick
function DDD_Floating_Health.on_tick(event)
  -- Show every half second
  if game.tick % DDD_Floating_Health.REFRESH_PERIOD ~= 0 then
    return
  end

  -- For every player thats online...
  for i, player in pairs(game.connected_players) do
    if player.character then
      -- Exit if player character doesnt have health
      if player.character.health == nil then
        return
      end
      local health = math.ceil(player.character.health)
      -- Set up global health var if doesnt exist
      if global.player_health == nil then
        global.player_health = {}
      end
      if global.player_health[player.name] == nil then
        global.player_health[player.name] = health
      end
      -- If mismatch b/w global and current hp, display hp text
      if global.player_health[player.name] ~= health then
        global.player_health[player.name] = health
        DDD_Floating_Health.showPlayerHealth(player, health)
      end
    end
  end
end

--- Event Registration --
--- ======================================================================== ---
Event.register(
  defines.events.on_runtime_mod_setting_changed,
  DDD_Floating_Health.on_runtime_mod_setting_changed
)
Event.register(defines.events.on_tick, DDD_Floating_Health.on_tick)

--- Helper Functions --
--- ======================================================================== ---

--- Draws different color health # above the player based on HP value
--- @param player LuaPlayer
--- @param health integer
function DDD_Floating_Health.showPlayerHealth(player, health)
  local max_hp = player.character.prototype.max_health -- or MAX_PLAYER_HP
  if health <= DDD_Floating_Health.percentToHp(DDD_Floating_Health.HP_LOW, max_hp) then
    DDD_Floating_Health.drawFlyingText(
      player, Colors.red,
      DDD_Floating_Health.hpToPercent(health, max_hp) .. '%'
    )
  elseif health <= DDD_Floating_Health.percentToHp(DDD_Floating_Health.HP_MID, max_hp) then
    DDD_Floating_Health.drawFlyingText(
      player, Colors.yellow,
      DDD_Floating_Health.hpToPercent(health, max_hp) .. '%'
    )
  elseif health <= DDD_Floating_Health.percentToHp(DDD_Floating_Health.HP_HIGH, max_hp) then
    DDD_Floating_Health.drawFlyingText(
      player, Colors.green,
      DDD_Floating_Health.hpToPercent(health, max_hp) .. '%'
    )
  end
end

--- Draws text above the player
--- @param player LuaPlayer
--- @param color Color text color (rgb)
--- @param text string text to display
function DDD_Floating_Health.drawFlyingText(player, color, text)
  player.surface.create_entity {
    name = 'flying-text',
    color = color,
    text = text,
    position = { player.position.x, player.position.y - 2 }
  }
end

--- Returns an HP value from apercentage
--- @param val integer - HP number to convert to Percentage
--- @param max_hp integer - Maximum Hp to calc percentage of
function DDD_Floating_Health.hpToPercent(val, max_hp)
  return math.ceil(100 / max_hp * val)
end

--- Returns HP as a percentage instead of raw number
--- @param val integer - Percentage number to convert to HP
--- @param max_hp integer - Maximum Hp to calc percentage of
function DDD_Floating_Health.percentToHp(val, max_hp)
  return math.ceil(max_hp / 100 * val)
end
