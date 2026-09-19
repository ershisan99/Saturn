-- Keyboard shortcuts: one key per setting toggles it on/off, plus a small
-- always-visible status strip in the left margin with hover tooltips.
-- Hooks Controller:key_press_update the same way Fantoms Preview does.
-- Key names follow LOVE key constants (e.g. "a", "n", "kp1" -> "1").

local function on_off(value)
  return value and "ON" or "OFF"
end

local function key_label(key)
  return string.upper(key or "?")
end

-- Definitions of the two toggles shown in the status strip.
local toggles = {
  {
    id = "remove_animations",
    title = "Skip animations",
    key = "keybind_anim",
  },
  {
    id = "enable_animation_skip_pause",
    title = "Pause after scoring",
    key = "keybind_pause",
  },
}

-- X offset that puts the strip in the letterbox margin left of the HUD.
-- G.ROOM.T.x is the width of that margin in room units.
local function status_ui_x()
  return -((G.ROOM and G.ROOM.T.x) or 0) + 0.1
end

-- Per-frame update for one status icon: recolour and refresh tooltip text.
G.FUNCS.saturn_status_icon = function(e)
  if Saturn.status_ui then
    Saturn.status_ui.alignment.offset.x = status_ui_x()
  end
  local t = e.config.ref_table
  local on = Saturn.config[t.id] and true or false
  e.config.colour = on and G.C.GREEN or darken(G.C.GREY, 0.3)
  e.config.on_demand_tooltip = e.config.on_demand_tooltip or {}
  e.config.on_demand_tooltip.title = t.title
  e.config.on_demand_tooltip.text = {
    "Currently " .. on_off(on),
    "Press " .. key_label(Saturn.config[t.key]) .. " to toggle",
  }
end

local function status_icon(t)
  return {
    n = G.UIT.C,
    config = {
      align = "cm",
      minw = 0.38,
      minh = 0.38,
      r = 0.08,
      padding = 0.02,
      colour = darken(G.C.GREY, 0.3),
      emboss = 0.04,
      hover = true,
      ref_table = t,
      func = "saturn_status_icon",
      on_demand_tooltip = { title = t.title, text = {} },
      saturn_status_icon = true,
    },
    nodes = {
      {
        n = G.UIT.T,
        config = {
          text = key_label(Saturn.config[t.key]),
          scale = 0.28,
          colour = G.C.UI.TEXT_LIGHT,
          shadow = true,
        },
      },
    },
  }
end

-- The icons sit at the window's left edge, so the default tooltip position
-- (centred above the element) would be half off screen. Open it to the
-- right instead, the same way Cartomancer positions its joker popups.
local ui_element_hover_ref = UIElement.hover
function UIElement:hover()
  if self.config and self.config.saturn_status_icon then
    self.config.h_popup =
      create_popup_UIBox_tooltip(self.config.on_demand_tooltip)
    self.config.h_popup_config = {
      align = "cr",
      offset = { x = 0.15, y = 0 },
      parent = self,
    }
    Node.hover(self)
    return
  end
  return ui_element_hover_ref(self)
end

function Saturn.create_status_ui()
  if Saturn.status_ui then
    Saturn.status_ui:remove()
    Saturn.status_ui = nil
  end
  if not G.HUD then
    return
  end
  local rows = {}
  for _, t in ipairs(toggles) do
    table.insert(rows, {
      n = G.UIT.R,
      config = { align = "cm", padding = 0.04 },
      nodes = { status_icon(t) },
    })
  end
  Saturn.status_ui = UIBox({
    definition = {
      n = G.UIT.ROOT,
      config = { align = "cm", padding = 0.02, colour = G.C.CLEAR },
      nodes = rows,
    },
    -- Vertically centred, in the margin between the window edge and the HUD.
    config = {
      align = "cli",
      offset = { x = status_ui_x(), y = 0 },
      major = G.ROOM_ATTACH,
      bond = "Weak",
    },
  })
end

local start_run_ref = Game.start_run
function Game:start_run(args)
  start_run_ref(self, args)
  Saturn.create_status_ui()
end

local function toggle_setting(id)
  Saturn.config[id] = not Saturn.config[id]
  Saturn.writeConfig()
  play_sound("button", 1, 0.2)
end

local key_press_update_ref = Controller.key_press_update
function Controller:key_press_update(key, dt)
  key_press_update_ref(self, key, dt)
  if self.locks.frame or self.text_input_hook then
    return
  end
  if G.SETTINGS.paused or G.OVERLAY_MENU then
    return
  end
  if string.sub(key, 1, 2) == "kp" then
    key = string.sub(key, 3)
  end
  for _, t in ipairs(toggles) do
    local bound = Saturn.config[t.key]
    if bound and bound ~= "" and key == string.lower(bound) then
      toggle_setting(t.id)
      return
    end
  end
end
