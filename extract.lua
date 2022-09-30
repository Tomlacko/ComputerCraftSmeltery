--Pastebin: VrirajFj

os.loadAPI("Utils")
os.loadAPI("Modem")

local modem = Modem.Init("right")
local rSide = "bottom"
local gSide = "back"
local allSide = "top"
local liquidPath = "liquids.cfg"

local msgPort = 50000
local cmdPort = 50001


local liquidList = Utils.ParseFile(liquidPath)

local liquids = {}
for i=1,#liquidList do
  liquids[liquidList[i].name] = {cable=liquidList[i].cable, subgr=liquidList[i].subgr}
end

---------------------------

local function GetExtractionTime(amount)
  return math.max(0.1, math.floor(amount/40 + 0.5)/20)
end

local function PulseBundledCable(cable, length)
  rs.setBundledOutput(rSide, colors[cable])
  sleep(length)
  rs.setBundledOutput(rSide, 0)
end

local function SetActiveSubgroup(g)
  if g == 0 then
    rs.setBundledOutput(gSide, 0)
  else
    rs.setBundledOutput(gSide, 2^(g-1))
  end
  sleep(0.1)
end

local function PullAllLiquid(cable)
  rs.setBundledOutput(rSide, colors[cable])
  sleep(1)
  while rs.getInput(allSide) do
    os.pullEvent("redstone")
  end
  rs.setBundledOutput(rSide, 0)
  sleep(0.1)
end

---------------------------

rs.setBundledOutput(rSide, 0)
sleep(0.1)
rs.setBundledOutput(gSide, 0)

while true do
  local msg, stamp = modem:Receive(cmdPort)
  if msg.action == "request_liquid" then
    if msg.amount == "ALL" then
      modem:Send(msgPort, {action="request_liquid_ack", wait=-1}, stamp)
      
      print("Pulling all "..msg.liquid.."...")
      SetActiveSubgroup(liquids[msg.liquid].subgr)
      PullAllLiquid(liquids[msg.liquid].cable)
    else
      local length = GetExtractionTime(msg.amount)
      modem:Send(msgPort, {action="request_liquid_ack", wait=length+0.2}, stamp)
      
      print("Pulling " .. tostring(msg.amount) .. "mB of " .. msg.liquid .. "...")
      SetActiveSubgroup(liquids[msg.liquid].subgr)
      PulseBundledCable(liquids[msg.liquid].cable, length)
    end
    sleep(0.1)
    
    modem:Send(msgPort, {action="request_liquid_done"}, stamp)
    print("Done!")
    print("----------")
  end
end
