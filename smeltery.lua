--pastebin: s4aBwPWr

os.loadAPI("Utils")
os.loadAPI("UI")
os.loadAPI("Modem")

local rsSide = "left"
local wSide = "bottom"
local mSide = "top"
local mScale = 2

local liquidPath = "smeltery/liquids.cfg"
local alloyPath = "smeltery/alloys.cfg"

local msgPort = 50000
local cmdPort = 50001

local liquidList = Utils.ParseFile(liquidPath)
local alloyList = Utils.ParseFile(alloyPath)
local alloyDict = {}
for i=1,#alloyList do
  alloyDict[alloyList[i].name] = {step=alloyList[i].step, liquids=alloyList[i].liquids}
end

local unitList = {
--{name="emeralds", text="Emeralds", value=640},
  {name="nuggets",  text="Nuggets",  value=16},
  {name="ingots",   text="Ingots",   value=144},
  {name="blocks",   text="Blocks",   value=1296},
  {name="mb",       text="mB",       value=1}
}
local unitDict = {}
for i=1,#unitList do
  unitDict[unitList[i].name] = unitList[i].value
end

local formList = {
  {name="custom", text="Custom"},
  {name="nugget", text="Nuggets"},
  {name="ingot", text="Ingots"},
  {name="block", text="Blocks"}
}

local tabList = {
  {name="request", text="Request"},
  {name="alloying", text="Alloying"},
  {name="cast", text="Cast"}
}

local actionList = {
  {name="flush", text="FLUSH", width=9},
  {name="start", text="START", width=-1}
}

local layoutTxtColor = "white"
local layoutBgrColor = "black"

--------------------------------------------------

local modem = Modem.Init(wSide)

local m = peripheral.wrap(mSide)
m.setTextScale(mScale)
local w, h = m.getSize()
m.setTextColor(colors.white)
m.setBackgroundColor(colors.black)
m.clear()

local top = 2
local bottom = h-1


local current = {
  tab = false,
  
  request_liquid = false,
  request_units = false,
  request_amount = 0,
  
  alloying_alloy = false,
  alloying_units = false,
  alloying_amount = 0,
  
  cast_form = false,
  cast_amount = 0
}

local screen,  tabs, actionbar, main,  request, alloying, cast

--------------------------------------------------
--##############################################--
--------------------------------------------------

local function ConvertUnits(amount, from, to)
  if amount == "ALL" then
    return "ALL"
  end
  return (amount*unitDict[from])/unitDict[to]
end

local function ResetTab(tab)
  if tab == "request" then
    
  elseif tab == "alloying" then
    
  elseif tab == "cast" then
    
  end
end

local function SwitchTab(newTab)
  if not newTab or newTab == current.tab then
    return false
  end
  
  if current.tab then
    main.groups[current.tab]:Hide()
    tabs.elements[current.tab].pressed = false
  end
  main.groups[newTab]:Show()
  tabs.elements[newTab].pressed = true
  
  current.tab = newTab
  
  screen:Draw(m)
  return true
end

local function Flush()
  print("Flushing all liquid to storage...")
  local stamp = modem:Send(cmdPort, {action="flush"})
  local reply = modem:Receive(msgPort, stamp, 0.1)
  if reply and reply.action == "flush_ack" then
    reply = modem:Receive(msgPort, stamp)
    if reply and reply.action == "flush_done" then
      print("Done.")
      return true
    end
  end
  print("Flushing failed: invalid/no response!")
  return false
end

local function RequestLiquid(liquid, amount)
  print("Requesting "..tostring(amount).."mB of "..liquid.."...")
  local stamp = modem:Send(cmdPort, {
    action="request_liquid",
    liquid=liquid,
    amount=amount
  })
  
  local reply = modem:Receive(msgPort, stamp, 0.1)
  if reply and reply.action == "request_liquid_ack" then
    reply = modem:Receive(msgPort, stamp)
    if reply and reply.action == "request_liquid_done" then
      sleep(0.1)
      return true
    end
  end
  print("Liquid request failed: invalid/no response! ("..liquid..")")
  return false
end

local function MakeAlloy(alloy, amount)
  print("Making "..tostring(amount).."mB of "..alloy.."...")
  local batches = math.ceil(amount/alloyDict[alloy].step)
  for liquid,amt in pairs(alloyDict[alloy].liquids) do
    if not RequestLiquid(liquid, amt*batches) then
      print("Alloying failed: liquid request failed! ("..alloy..")")
      return false
    end
  end
  return true
end

local function Cast(form, amount)
  print("Casting "..tostring(amount).." items to "..form.." form...")
  local stamp = modem:Send(cmdPort, {
    action="cast",
    form=form,
    amount=amount
  })
  
  local reply = modem:Receive(msgPort, stamp, 0.1)
  if reply and reply.action == "cast_ack" then
    reply = modem:Receive(msgPort, stamp)
    if reply and reply.action == "cast_done" then
      return true
    end
  end
  print("Cast failed: invalid/no response! ("..form..")")
  return false
end

local function CanProceed()
  if current.tab == "request" then
    if current.request_liquid and (current.request_amount == "ALL" or (current.request_units and current.request_amount > 0)) then
      return true
    end
    print("Request failed: invalid selection!")
  elseif current.tab == "alloying" then
    if current.alloying_alloy and (current.alloying_amount == "ALL" or (current.alloying_units and current.alloying_amount > 0)) then
      return true
    end
    print("Alloying failed: invalid selection!")
  elseif current.tab == "cast" then
    if current.cast_form and (current.cast_amount == "ALL" or current.cast_amount > 0) then
      return true
    end
    print("Cast failed: invalid selection!")
  end
  print("----------")
  return false
end

local function Proceed(m)
  if current.tab == "request" then
    if RequestLiquid(current.request_liquid, ConvertUnits(current.request_amount, current.request_units, "mb")) then
      print("Request finished.")
      print("----------")
      return true
    end
  elseif current.tab == "alloying" then
    if MakeAlloy(current.alloying_alloy, ConvertUnits(current.alloying_amount, current.alloying_units, "mb")) then
      print("Alloying finished.")
      print("----------")
      return true
    end
  elseif current.tab == "cast" then
    if Cast(current.cast_form, current.cast_amount) then
      print("Cast finished.")
      print("----------")
      return true
    end
  end
  
  print("----------")
  return false
end

--------------------------------------------------
--##############################################--
--------------------------------------------------

local function CreateScrollList(name, list, height, itemalign, x1, y1, x2, y2, currentPtr)
  local newlist = UI.NewGroup(name, true, x1, y1, x2, y2)
  
  for i,item in ipairs(list) do
    local y = newlist.y1+(i-1)*height
    local btn = UI.NewElement(item.name, item.text, newlist.x1, y, newlist.x2, y+height-1, "white", "black", true, true, itemalign)
    btn.txtColorPressed = "gray"
    btn.bgrColorPressed = "white"
    btn.onClick = function(m)
      if not btn.pressed then
        btn.parent:ApplyElemProperty("pressed", false)
        btn.pressed = true
        current[currentPtr] = btn.name
        btn.parent:Draw(m)
        return true
      end
      return false
    end
    newlist:AddElement(btn)
  end

  newlist:MakeScrollable(nil, {size=1, step=1, iconUp="---/\\---", iconDown="---\\/---"}, "white", "lightGray", "lightGray", "gray")
  
  return newlist
end

local function CreateSwitches(name, list, height, spacing, x1, y1, x2, y2, currentPtr)
  local switches = UI.NewGroup(name, true, x1, y1, x2, y2)
  
  local topmost = math.ceil(switches:GetMidY() - (#list*(height+spacing)-spacing)/2)
  for i=1,#list do
    local y = topmost + (i-1)*(height+spacing)
    local btn = UI.NewElement(list[i].name, list[i].text, switches.x1, y, switches.x2, y+height-1, "black", "cyan", true, true, "center")
    btn.txtColorPressed = "white"
    btn.bgrColorPressed = "lightBlue"
    btn.onClick = function(m)
      if not btn.pressed then
        btn.parent:ApplyElemProperty("pressed", false)
        btn.pressed = true
        current[currentPtr] = btn.name
        btn.parent:Draw(m)
        return true
      end
      return false
    end
    switches:AddElement(btn)
  end
  
  return switches
end

local function CreateAmounts(name, x1, y1, x2, y2, currentPtr)
  local amounts = UI.NewGroup(name, true, x1, y1, x2, y2)
  
  local mid = math.floor(amounts:GetMidY())
  for i=1,7 do
    for k=0,1 do
      local y = mid - i*(k*2-1)
      local btn
      
      if i<7 then
        local val = (10^(i-1)) * (k*2-1)
        local name = tostring(val)
        
        if k==1 then
          name = "+"..name
        end
        
        btn = UI.NewElement("amount_"..name, name, amounts.x1, y, amounts.x2, y, "white", "blue", true, true, "right")
        btn.data = val
        
        btn.onClick = function(m)
          if current[currentPtr] == "ALL" then
            return false
          end
          
          local amount = current[currentPtr] + btn.data
          if amount < 0 then
            current[currentPtr] = 0
          elseif amount > 9999999 then
            current[currentPtr] = "ALL"
          else
            current[currentPtr] = amount
          end
          btn.parent.elements.amount:Draw(m)
          return true
        end
        
      else
        local name
        if k==0 then
          name = "reset"
        else
          name = "all"
        end
      
        btn = UI.NewElement("amount_"..name, string.upper(name), amounts.x1, y, amounts.x2, y, "white", "purple", true, true, "center")
        btn.data = name
        
        if k==0 then
          btn.onClick = function(m)
            current[currentPtr] = 0
            btn.parent.elements.amount:Draw(m)
          end
        else
          btn.onClick = function(m)
            current[currentPtr] = "ALL"
            btn.parent.elements.amount:Draw(m)
          end
        end
        
      end
      amounts:AddElement(btn)
    end
  end
  
  --current amount
  local btn = UI.NewElement("amount", 0, amounts.x1, mid, amounts.x2, mid, "black", "white", true, false, "right")
  btn.onBeforeDraw = function(m)
    btn.text = current[currentPtr]
  end
  amounts:AddElement(btn)
  
  return amounts
end

--------------------------------------------------
--##############################################--
--------------------------------------------------

local function CreateInterface()
  screen = UI.NewGroup("screen", false, 1, 1, w, h)

  top = top + screen.y1 - 1
  bottom = bottom + screen.y1 - 1

  screen.onBeforeDraw = function(m)
    Utils.Draw(m, screen.x1, screen.y1, screen.x2, screen.y2, " ", nil, layoutBgrColor)
  end
  
  screen.onAfterDraw = function(m)
    Utils.Draw(m, screen.x1, top, screen.x2, top, "-", layoutTxtColor, layoutBgrColor)
    Utils.Draw(m, screen.x1, bottom, screen.x2, bottom, "-", layoutTxtColor, layoutBgrColor)
  end

  ------------------------------------------------

  --TABS
  tabs = UI.NewGroup("tabs", false, screen.x1, screen.y1, screen.x2, top-1)
  screen:AddGroup(tabs)

  local spacing = 1
  local width = math.floor(((tabs.x2-tabs.x1+1)-(#tabList-1)*spacing)/#tabList)
  local leftmost = math.ceil(tabs:GetMidX() - (#tabList*(width+spacing)-spacing)/2)
  for i=1,#tabList do
    local x = leftmost + (i-1)*(width+spacing)
    local btn = UI.NewElement(tabList[i].name, tabList[i].text, x, tabs.y1, x+width-1, tabs.y2, "white", "red", false, true, "center")
    btn.bgrColorPressed = "black"
    btn.onClick = function(m)
      return SwitchTab(btn.name)
    end
    tabs:AddElement(btn)
  end

  ------------------------------------------------

  --MAIN
  main = UI.NewGroup("main", false, screen.x1, top+1, screen.x2, bottom-1)
  screen:AddGroup(main)

  ---------

  --REQUEST
  request = UI.NewGroup("request", true, main.x1, main.y1, main.x2, main.y2)
  main:AddGroup(request)

  
  local columns = {1, 24, 33, 41}

  request.onAfterDraw = function(m)
    for i=1,#columns do
      if columns[i]>=request.x1 and columns[i]<=request.x2 then
        Utils.Draw(m, request.x1+columns[i]-1, request.y1, request.x1+columns[i]-1, request.y2, "|", layoutTxtColor, layoutBgrColor)
      end
    end
  end


  local c = 1

  --liquids
  local liquids = CreateScrollList("liquids", liquidList, 1, "left", request.x1+columns[c], request.y1, request.x1+columns[c+1]-2, request.y2, "request_liquid")
  request:AddGroup(liquids)

  c = c+1


  --units
  local units = CreateSwitches("units", unitList, 3, 1, request.x1+columns[c], request.y1, request.x1+columns[c+1]-2, request.y2, "request_units")
  request:AddGroup(units)  

  c = c+1


  --amounts
  local amounts = CreateAmounts("amounts", request.x1+columns[c], request.y1, request.x1+columns[c+1]-2, request.y2, "request_amount")
  request:AddGroup(amounts)

  c = c+1

  ------------------------------------------------

  --ALLOYING
  alloying = UI.NewGroup("alloying", true, main.x1, main.y1, main.x2, main.y2)
  main:AddGroup(alloying)
  
  
  local columns = {1, 24, 33, 41}

  alloying.onAfterDraw = function(m)
    for i=1,#columns do
      if columns[i]>=alloying.x1 and columns[i]<=alloying.x2 then
        Utils.Draw(m, alloying.x1+columns[i]-1, alloying.y1, alloying.x1+columns[i]-1, alloying.y2, "|", layoutTxtColor, layoutBgrColor)
      end
    end
  end


  local c = 1

  --alloys
  local alloys = CreateScrollList("alloys", alloyList, 1, "left", alloying.x1+columns[c], alloying.y1, alloying.x1+columns[c+1]-2, alloying.y2, "alloying_alloy")
  alloying:AddGroup(alloys)

  c = c+1


  --units
  local units = CreateSwitches("units", unitList, 3, 1, alloying.x1+columns[c], alloying.y1, alloying.x1+columns[c+1]-2, alloying.y2, "alloying_units")
  alloying:AddGroup(units)  

  c = c+1


  --amounts
  local amounts = CreateAmounts("amounts", alloying.x1+columns[c], alloying.y1, alloying.x1+columns[c+1]-2, alloying.y2, "alloying_amount")
  alloying:AddGroup(amounts)

  c = c+1
  
  ------------------------------------------------

  --CAST
  cast = UI.NewGroup("cast", true, main.x1, main.y1, main.x2, main.y2)
  main:AddGroup(cast)
  
  local mid = cast:GetMidX()
  
  cast.onAfterDraw = function(m)
    Utils.Draw(m, mid, cast.y1, mid, cast.y2, "|", layoutTxtColor, layoutBgrColor)
  end
  
  local offset = 1
  
  --form
  local btnWidth = 10
  local forms = CreateSwitches("forms", formList, 3, 1, mid - btnWidth - offset, cast.y1, mid - offset - 1, cast.y2, "cast_form")
  cast:AddGroup(forms)  
  
  --amount
  local btnWidth = 9
  local amounts = CreateAmounts("amounts", mid + offset + 1, cast.y1, mid + btnWidth + offset, cast.y2, "cast_amount")
  cast:AddGroup(amounts)
  
  ------------------------------------------------
  
  --ACTION BAR
  actionbar = UI.NewGroup("actionbar", false, screen.x1, bottom+1, screen.x2, screen.y2)
  screen:AddGroup(actionbar)
  
  local x = actionbar.x2
  for i=1,#actionList do
    local left = x - actionList[i].width + 1
    if actionList[i].width < 0 then
      left = actionbar.x1
    end
    
    local btn = UI.NewElement(actionList[i].name, actionList[i].text, left, actionbar.y1, x, actionbar.y2, "white", "red", false, true, "center")
    btn.bgrColorPressed = "lime"
    actionbar:AddElement(btn)
    
    x = left - 2
  end
  
  --START
  local btn = actionbar.elements.start
  btn.onClick = function(m)
    if not btn.pressed and CanProceed() then
      btn.pressed = true
      btn:Draw(m)
      Proceed(m)
      btn.pressed = false
      btn:Draw(m)
      return true
    end
    return false
  end
  
  --FLUSH
  local btn = actionbar.elements.flush
  btn.onClick = function(m)
    if not btn.pressed then
      btn.pressed = true
      btn:Draw(m)
      Flush()
      btn.pressed = false
      btn:Draw(m)
      return true
    end
  end
  
  
end

------------------------------------------------
--############################################--
------------------------------------------------

CreateInterface()
SwitchTab("request")

---------------------

while true do
  sleep(0.2)
  e, s, x, y = os.pullEvent()
  if e == "monitor_touch" and s == mSide then
    screen:Click(m, x, y)
  end
end
