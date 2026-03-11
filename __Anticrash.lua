local PREFIX = "|cffff0000!!|r|cffaa00ffAnticrash|r"
local DEBUG_FRAMES = true
local TOP_N = 20

Anticrash_SavedData = Anticrash_SavedData or {}

local function CountFrames()
  local count = 0
  local unnamed = 0
  local prefixcounts = {}
  local frame = EnumerateFrames()
  while frame do
    count = count + 1
    local name = frame:GetName()
    if name then
      local prefix = strsub(name, 1, 6)
      prefixcounts[prefix] = (prefixcounts[prefix] or 0) + 1
    else
      unnamed = unnamed + 1
    end
    frame = EnumerateFrames(frame)
  end
  return count, unnamed, prefixcounts
end

local function SortTable(t)
  local sorted = {}
  for k, n in pairs(t) do
    sorted[table.getn(sorted) + 1] = {key=k, n=n}
  end
  table.sort(sorted, function(a, b) return a.n > b.n end)
  return sorted
end

local function PrintReport(label, count, unnamed, prefixcounts)
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffff0000" .. label .. ": " .. count .. " TOTAL FRAMES|r")
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffaaaaaa-- TOP " .. TOP_N .. " PREFIXES --|r")
  local sorted = SortTable(prefixcounts)
  for i = 1, table.getn(sorted) do
    if i > TOP_N then break end
    local entry = sorted[i]
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffcccccc" .. entry.key .. "|r |cffffffff" .. entry.n .. "|r")
  end
  if unnamed > 0 then
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffcccccc(unnamed)|r |cffffffff" .. unnamed .. "|r")
  end
end

local function SaveSnapshot(label, count, unnamed, prefixcounts)
  local snapshot = {
    label = label, count = count, unnamed = unnamed, prefixes = {},
    time = date("%H:%M:%S"),
  }
  for k, n in pairs(prefixcounts) do snapshot.prefixes[k] = n end
  Anticrash_SavedData.last = snapshot
end

local function DoShutdown()
  local count, unnamed, prefixcounts = CountFrames()
  local frame = EnumerateFrames()
  while frame do
    if frame.UnregisterAllEvents then
      frame:UnregisterAllEvents()
    end
    frame = EnumerateFrames(frame)
  end
  if DEBUG_FRAMES then
    PrintReport("LOGOUT", count, unnamed, prefixcounts)
    SaveSnapshot("LOGOUT", count, unnamed, prefixcounts)
  else
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffff0000UNREGISTERED " .. count .. " FRAMES BEFORE LOGOUT|r")
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  if event == "PLAYER_LOGOUT" then
    -- defer by one OnUpdate tick so all other PLAYER_LOGOUT handlers fire first
    f.shutdownPending = true

  elseif event == "PLAYER_LOGIN" then
    if DEBUG_FRAMES and Anticrash_SavedData and Anticrash_SavedData.last then
      f.loginTimer = 0
      f.showSnapshot = true
    end
  end
end)

f:SetScript("OnUpdate", function()
  -- deferred shutdown: runs after all PLAYER_LOGOUT handlers have fired
  if f.shutdownPending then
    f.shutdownPending = false
    DoShutdown()
    return
  end

  -- show login snapshot after 2s delay
  if not f.showSnapshot then return end
  f.loginTimer = (f.loginTimer or 0) + arg1
  if f.loginTimer < 2 then return end
  f.showSnapshot = false

  local snap = Anticrash_SavedData.last
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffaaaaaa-- Last " .. snap.label .. " at " .. (snap.time or "?") .. " --|r")
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffff0000" .. snap.label .. ": " .. snap.count .. " TOTAL FRAMES|r")
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffaaaaaa-- TOP " .. TOP_N .. " PREFIXES --|r")
  local sorted = SortTable(snap.prefixes)
  for i = 1, table.getn(sorted) do
    if i > TOP_N then break end
    local entry = sorted[i]
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffcccccc" .. entry.key .. "|r |cffffffff" .. entry.n .. "|r")
  end
  if snap.unnamed and snap.unnamed > 0 then
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffcccccc(unnamed)|r |cffffffff" .. snap.unnamed .. "|r")
  end
end)