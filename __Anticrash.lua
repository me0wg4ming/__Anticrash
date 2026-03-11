local PREFIX = "|cffff0000__|r|cffaa00ffAnticrash|r"

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
  -- defer by one OnUpdate tick so all other PLAYER_LOGOUT handlers fire first
  f.shutdownPending = true
end)

f:SetScript("OnUpdate", function()
  if not f.shutdownPending then return end
  f.shutdownPending = false
  local count = 0
  local frame = EnumerateFrames()
  while frame do
    if frame.UnregisterAllEvents then
      frame:UnregisterAllEvents()
      count = count + 1
    end
    frame = EnumerateFrames(frame)
  end
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " |cffff0000UNREGISTERED " .. count .. " FRAMES BEFORE LOGOUT|r")
end)