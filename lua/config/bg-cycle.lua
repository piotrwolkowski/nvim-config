-- Background color effects
-- Two modes: smooth cycle and heartbeat pulse
--
-- Cycle (gradual light/dark wave):
--   :BgCycleToggle            toggle on/off        <leader>uB
--   :BgCyclePeriod <secs>     full cycle duration   (default 60)
--   :BgCycleAmplitude <0-50>  lightness swing       (default 8)
--
-- Heartbeat (lub-dub pulse):
--   :BgHeartbeatToggle        toggle on/off         <leader>uH
--   :BgHeartbeatRate <secs>   beat interval          (default 2)
--   :BgHeartbeatAmplitude <0-50>  pulse strength     (default 6)

local M = {}

M.config = {
  cycle_period = 60, -- seconds for one full dark-to-light-to-dark cycle
  amplitude = 8, -- lightness variation on 0-100 scale
  update_interval = 200, -- ms between bg updates
  enabled = false,
}

M.heartbeat = {
  rate = 2, -- seconds per heartbeat
  amplitude = 10, -- lightness variation on 0-100 scale
  update_interval = 50, -- ms between updates (faster for snappy pulses)
  enabled = false,
}

local timer = nil
local hb_timer = nil
local base_hsl = nil
local start_time = nil
local original_bg_hex = nil
local base_normal_hl = nil
local last_applied_hex = nil
local hb_base_hsl = nil
local hb_start_time = nil
local hb_original_bg_hex = nil
local hb_base_normal_hl = nil
local hb_last_applied_hex = nil
local schedule_pending = false
local hb_schedule_pending = false

-- ── Color conversion helpers ──────────────────────────────────────

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function rgb_to_hsl(r, g, b)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2

  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h * 360, s * 100, l * 100
end

local function hue_to_rgb(p, q, t)
  if t < 0 then
    t = t + 1
  end
  if t > 1 then
    t = t - 1
  end
  if t < 1 / 6 then
    return p + (q - p) * 6 * t
  end
  if t < 1 / 2 then
    return q
  end
  if t < 2 / 3 then
    return p + (q - p) * (2 / 3 - t) * 6
  end
  return p
end

local function hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100

  if s == 0 then
    return l, l, l
  end

  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return hue_to_rgb(p, q, h + 1 / 3), hue_to_rgb(p, q, h), hue_to_rgb(p, q, h - 1 / 3)
end

local function rgb_to_hex(r, g, b)
  return string.format(
    "#%02x%02x%02x",
    math.floor(math.min(255, math.max(0, r * 255 + 0.5))),
    math.floor(math.min(255, math.max(0, g * 255 + 0.5))),
    math.floor(math.min(255, math.max(0, b * 255 + 0.5)))
  )
end

-- ── Core logic ────────────────────────────────────────────────────

local function get_normal_bg()
  local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  if hl.bg then
    return string.format("#%06x", hl.bg)
  end
  return nil
end

-- Apply bg only when the color actually changed (avoids needless redraws)
local function apply_bg(hex, cached_hl)
  local hl = vim.tbl_extend("force", cached_hl or {}, { bg = hex })
  vim.api.nvim_set_hl(0, "Normal", hl)
end

local function set_normal_bg(hex)
  local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  hl.bg = hex
  vim.api.nvim_set_hl(0, "Normal", hl)
end

local function update_bg()
  if not base_hsl or not start_time then
    return
  end
  if schedule_pending then
    return
  end

  local now = (vim.uv or vim.loop).now() / 1000
  local elapsed = now - start_time
  local phase = (elapsed % M.config.cycle_period) / M.config.cycle_period

  local offset = M.config.amplitude * math.cos(2 * math.pi * phase)

  local h, s, l = base_hsl[1], base_hsl[2], base_hsl[3]
  l = math.max(0, math.min(100, l + offset))

  local r, g, b = hsl_to_rgb(h, s, l)
  local hex = rgb_to_hex(r, g, b)

  if hex == last_applied_hex then
    return
  end

  schedule_pending = true
  vim.schedule(function()
    schedule_pending = false
    if M.config.enabled and hex ~= last_applied_hex then
      apply_bg(hex, base_normal_hl)
      last_applied_hex = hex
    end
  end)
end

-- ── Public API ────────────────────────────────────────────────────

function M.start()
  -- Stop heartbeat if running
  if M.heartbeat.enabled then
    M.heartbeat_stop()
  end
  if timer then
    M.stop()
  end

  local bg = get_normal_bg()
  if not bg then
    vim.notify("BgCycle: could not read Normal background color", vim.log.levels.WARN)
    return
  end

  original_bg_hex = bg
  base_normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  last_applied_hex = bg
  local r, g, b = hex_to_rgb(bg)
  local h, s, l = rgb_to_hsl(r, g, b)
  base_hsl = { h, s, l }
  start_time = (vim.uv or vim.loop).now() / 1000
  M.config.enabled = true

  timer = (vim.uv or vim.loop).new_timer()
  timer:start(0, M.config.update_interval, update_bg)

  vim.notify(string.format("BgCycle: ON  (period=%ds, amplitude=%d)", M.config.cycle_period, M.config.amplitude))
end

function M.stop()
  M.config.enabled = false

  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end

  if original_bg_hex then
    set_normal_bg(original_bg_hex)
    original_bg_hex = nil
  end
  base_hsl = nil
  base_normal_hl = nil
  last_applied_hex = nil
  start_time = nil

  vim.notify("BgCycle: OFF")
end

function M.toggle()
  if M.config.enabled then
    M.stop()
  else
    M.start()
  end
end

function M.set_period(seconds)
  M.config.cycle_period = seconds
  vim.notify("BgCycle: period = " .. seconds .. "s")
end

function M.set_amplitude(amp)
  M.config.amplitude = amp
  vim.notify("BgCycle: amplitude = " .. amp)
end

-- ── Heartbeat effect ──────────────────────────────────────────────

-- Raised-cosine pulse: smooth ease-in and ease-out with zero slope at edges
local function cos_pulse(t, center, half_width, amp)
  local x = math.abs(t - center) / half_width
  if x >= 1 then
    return 0
  end
  return amp * 0.5 * (1 + math.cos(math.pi * x))
end

-- Heartbeat envelope (flash + lub + dub + rest)
-- Returns 0..1 brightness bump for a given phase in [0, 1]
local function heartbeat_envelope(phase)
  -- Initial bright flash: quick, modest pop
  local flash = cos_pulse(phase, 0.04, 0.030, 0.45)
  -- Beat 1 (lub): main pulse, strong and smooth
  local lub = cos_pulse(phase, 0.13, 0.065, 1.0)
  -- Beat 2 (dub): longer, gentler pulse
  local dub = cos_pulse(phase, 0.30, 0.085, 0.70)

  return math.max(flash, lub, dub)
end

local function update_heartbeat()
  if not hb_base_hsl or not hb_start_time then
    return
  end
  if hb_schedule_pending then
    return
  end

  local now = (vim.uv or vim.loop).now() / 1000
  local elapsed = now - hb_start_time
  local phase = (elapsed % M.heartbeat.rate) / M.heartbeat.rate

  local offset = M.heartbeat.amplitude * heartbeat_envelope(phase)

  local h, s, l = hb_base_hsl[1], hb_base_hsl[2], hb_base_hsl[3]
  l = math.max(0, math.min(100, l + offset))

  local r, g, b = hsl_to_rgb(h, s, l)
  local hex = rgb_to_hex(r, g, b)

  if hex == hb_last_applied_hex then
    return
  end

  hb_schedule_pending = true
  vim.schedule(function()
    hb_schedule_pending = false
    if M.heartbeat.enabled and hex ~= hb_last_applied_hex then
      apply_bg(hex, hb_base_normal_hl)
      hb_last_applied_hex = hex
    end
  end)
end

function M.heartbeat_start()
  -- Stop cycle effect if running
  if M.config.enabled then
    M.stop()
  end
  if hb_timer then
    M.heartbeat_stop()
  end

  local bg = get_normal_bg()
  if not bg then
    vim.notify("BgHeartbeat: could not read Normal background color", vim.log.levels.WARN)
    return
  end

  hb_original_bg_hex = bg
  hb_base_normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  hb_last_applied_hex = bg
  local r, g, b = hex_to_rgb(bg)
  local h, s, l = rgb_to_hsl(r, g, b)
  hb_base_hsl = { h, s, l }
  hb_start_time = (vim.uv or vim.loop).now() / 1000
  M.heartbeat.enabled = true

  hb_timer = (vim.uv or vim.loop).new_timer()
  hb_timer:start(0, M.heartbeat.update_interval, update_heartbeat)

  vim.notify(string.format("BgHeartbeat: ON  (rate=%.1fs, amplitude=%d)", M.heartbeat.rate, M.heartbeat.amplitude))
end

function M.heartbeat_stop()
  M.heartbeat.enabled = false

  if hb_timer then
    hb_timer:stop()
    hb_timer:close()
    hb_timer = nil
  end

  if hb_original_bg_hex then
    set_normal_bg(hb_original_bg_hex)
    hb_original_bg_hex = nil
  end
  hb_base_hsl = nil
  hb_base_normal_hl = nil
  hb_last_applied_hex = nil
  hb_start_time = nil

  vim.notify("BgHeartbeat: OFF")
end

function M.heartbeat_toggle()
  if M.heartbeat.enabled then
    M.heartbeat_stop()
  else
    M.heartbeat_start()
  end
end

function M.set_heartbeat_rate(seconds)
  M.heartbeat.rate = seconds
  vim.notify("BgHeartbeat: rate = " .. seconds .. "s")
end

function M.set_heartbeat_amplitude(amp)
  M.heartbeat.amplitude = amp
  vim.notify("BgHeartbeat: amplitude = " .. amp)
end

-- ── Setup (commands + keymap) ─────────────────────────────────────

function M.setup()
  vim.api.nvim_create_user_command("BgCycleToggle", function()
    M.toggle()
  end, { desc = "Toggle background color cycling" })

  vim.api.nvim_create_user_command("BgCycleStart", function()
    M.start()
  end, { desc = "Start background color cycling" })

  vim.api.nvim_create_user_command("BgCycleStop", function()
    M.stop()
  end, { desc = "Stop background color cycling" })

  vim.api.nvim_create_user_command("BgCyclePeriod", function(opts)
    local secs = tonumber(opts.args)
    if secs and secs > 0 then
      M.set_period(secs)
    else
      vim.notify("Usage: :BgCyclePeriod <seconds>  (must be > 0)", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "Set cycle period in seconds" })

  vim.api.nvim_create_user_command("BgCycleAmplitude", function(opts)
    local amp = tonumber(opts.args)
    if amp and amp >= 0 and amp <= 50 then
      M.set_amplitude(amp)
    else
      vim.notify("Usage: :BgCycleAmplitude <0-50>", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "Set lightness swing (0-50)" })

  vim.keymap.set("n", "<leader>uB", function()
    M.toggle()
  end, { desc = "Toggle background cycling" })

  -- Heartbeat commands
  vim.api.nvim_create_user_command("BgHeartbeatToggle", function()
    M.heartbeat_toggle()
  end, { desc = "Toggle heartbeat background pulse" })

  vim.api.nvim_create_user_command("BgHeartbeatStart", function()
    M.heartbeat_start()
  end, { desc = "Start heartbeat background pulse" })

  vim.api.nvim_create_user_command("BgHeartbeatStop", function()
    M.heartbeat_stop()
  end, { desc = "Stop heartbeat background pulse" })

  vim.api.nvim_create_user_command("BgHeartbeatRate", function(opts)
    local secs = tonumber(opts.args)
    if secs and secs > 0 then
      M.set_heartbeat_rate(secs)
    else
      vim.notify("Usage: :BgHeartbeatRate <seconds>  (must be > 0)", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "Set heartbeat interval in seconds" })

  vim.api.nvim_create_user_command("BgHeartbeatAmplitude", function(opts)
    local amp = tonumber(opts.args)
    if amp and amp >= 0 and amp <= 50 then
      M.set_heartbeat_amplitude(amp)
    else
      vim.notify("Usage: :BgHeartbeatAmplitude <0-50>", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "Set heartbeat pulse strength (0-50)" })

  vim.keymap.set("n", "<leader>uH", function()
    M.heartbeat_toggle()
  end, { desc = "Toggle heartbeat background pulse" })
end

return M
