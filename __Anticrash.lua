local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
  -- defer by one OnUpdate tick so all other PLAYER_LOGOUT handlers fire first
  f.shutdownPending = true
end)

f:SetScript("OnUpdate", function()
  if not f.shutdownPending then return end
  f.shutdownPending = false
  local frame = EnumerateFrames()
  while frame do
    if frame.UnregisterAllEvents then
      frame:UnregisterAllEvents()
    end
    frame = EnumerateFrames(frame)
  end
end)