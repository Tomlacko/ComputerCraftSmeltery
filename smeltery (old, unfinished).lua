rsSide = "left"
mSide = "top"
orePath = "smeltery/ores.cfg"

msgPort = 50000
cmdPort = 50001

mScale = 2
cols = {1, 10, 19, 27, 41}
tabs = {"Ores","Alloys"}

units = {
  {name="nuggets", text="Nuggets", value=16},
  {name="ingots", text="Ingots", value=144},
  {name="blocks", text="Blocks", value=1296},
  {name="mb", text="mB", value=1}
}

actions = {"request", "cast", "store"}

screen = {
  ores={},
  alloys={}
}

--------------------------------------------------

local function parseFile(fPath)
  local f = fs.open(fPath, "r")
  local fText = f.readAll()
  f.close()
  return textutils.unserialize(fText)
end

local function rep(str, n)
  local text = ""
  for i=1,n do
    text = text .. str
  end
  return text
end

local function idx(str, i)
  return string.sub(str, i, i)
end

local function capitalize(str)
  return string.upper(string.sub(str, 1, 1))..string.sub(str, 2)
end

local function mWrite(x, y, text, bgrColor, color)
  if color then
    m.setTextColor(colors[color])
  end
  if bgrColor then
    m.setBackgroundColor(colors[bgrColor])
  end
  m.setCursorPos(x, y)
  m.write(text)
end

local function mWriteVert(x, y, text, bgrColor, color)
  if color then
    m.setTextColor(colors[color])
  end
  if bgrColor then
    m.setbackgroundColor(colors[bgrColor])
  end
  for i=1,#text do
    m.setCursorPos(x, y+i-1)
    m.write(idx(text, i))
  end
end

Button = {}
Button.__index = Button
function newButton(name, text, x1, y1, x2, y2, 
txtColor, bgrColor, centered, enabled, hidden, data)
  if buttons[name] then
    error("Button '"..name.."' already exists!")
  end
  local btn = {
    name=name,
    x1=x1, y1=y1,
    x2=x2, y2=y2,
    enabled=enabled,
    pressed=false,
    hidden=hidden,
    bgrColor=bgrColor,
    bgrColorOn=bgrColor,
    txtColor=txtColor,
    txtColorOn=txtColor,
    text=text,
    centered=centered,
    data=data
  }
  setmetatable(btn, Button)
  buttons[name] = btn
  return btn
end

function Button:click(event)
  if self.enabled and self.onclick then
    self.pressed = true
    return self:onclick(event)
  else
    return false
  end
end

function Button:draw()
  if self.hidden then
    return
  end
  if self.pressed then
    if self.bgrColorOn then
      m.setBackgroundColor(colors[self.bgrColorOn])
    end
    if self.txtColorOn then
      m.setTextColor(colors[self.txtColorOn])
    end
  else
    if self.bgrColor then
      m.setBackgroundColor(colors[self.bgrColor])
    end
    if self.txtColor then
      m.setTextColor(colors[self.txtColor])
    end
  end
  local i = 1
  if self.centered then
    i = math.ceil(#self.text/2 - ((self.x2-self.x1+1)*(self.y2-self.y1+1))/2 + 1)
  end
  for y=self.y1, self.y2 do
    for x=self.x1, self.x2 do
      m.setCursorPos(x,y)
      local ch = " "
      if i>=1 and i<=#self.text then
        ch = idx(self.text, i)
      end
      m.write(ch)
      i=i+1
    end
  end
end

--------------------------------------------------

local function drawLayout()
  for i=1,#cols do
    if cols[i]>=1 and cols[i]<=w then
      for j=top+1, bottom-1 do
        mWrite(cols[i], j, "|")
      end
    end
  end
  mWrite(1, top, rep("-", w))
  mWrite(1, bottom, rep("-", w))
end

local function drawOres()
  for i,btn in pairs(buttonCtg.ores) do
    btn:draw()
  end
end

local function drawUnits()
  for i,btn in pairs(buttonCtg.units) do
    btn:draw()
  end
end

local function drawAmounts()
  for i,btn in pairs(buttonCtg.amounts) do
    btn:draw()
  end
end

local function drawActions()
  for i,btn in pairs(buttonCtg.actions) do
    btn:draw()
  end
end

local function drawToolbar()
  for i,btn in pairs(buttonCtg.toolbar) do
    btn:draw()
  end
end

local function drawTabs()
  for i,btn in pairs(buttonCtg.tabs) do
    btn:draw()
  end
end

local function drawScreen()
  drawLayout()
  drawOres()
  drawUnits()
  drawAmounts()
  drawActions()
  drawToobar()
  drawTabs()
end

local function createOreButtons()
  local i = top+1
  for name in pairs(ores) do
    if idx(name, 1) ~= "_" then
      local btn = newButton(
        name, capitalize(name),
        cols[1]+1, i, cols[2]-1, i,
        "white", "black", false, false, true
      )
      btn.onclick = selectOre
      buttonCtg.ores[#buttonCtg.ores+1] = btn
      i=i+1
    end
  end
end

local function createUnitButtons()
  local height = 3
  local spacing = 1
  local topmost = math.ceil(top+(bottom-top)/2 - (#units*(height+spacing)-spacing)/2)
  
  for i=1,#units do
    local y = topmost+(i-1)*(height+spacing)
    local btn = newButton(
      units[i].name, units[i].text,
      cols[2]+1, y, cols[3]-1, y+height-1,
      "white", "orange", true, false, true
    )
    btn.bgrColorOn = "darkGray"
    btn.onclick = selectUnit
    buttonCtg.units[#buttonCtg.units+1] = btn
  end
end

local function createAmountButtons()
  local mid = math.floor(top+(bottom-top-1)/2)
  for i=1,7 do
    for k=0,1 do
      local y = mid+i*(k*2-1)
      local val = (10^(i-1))*(k*2-1)
      local name = tostring(val)
      local cl = "blue"
      if i==7 then
        cl = "purple"
        if k==0 then
          name="Minimum"
        else
          name="Maximum"
        end
      else
        if k==1 then
          name = "+"..name
        end
      end
      local btn = newButton(
        "amount_"..name, name,
        cols[3]+1, y, cols[4]-1, y,
        "white", cl, true, false, true
      )
      btn.onclick = selectAmount
      buttonCtg.amounts[#buttonCtg.amounts+1] = btn
    end
  end
  local btn = newButton(
    "amount", "0",
    cols[3]+1, mid, cols[4]-1, mid,
    "white", "black", true, false, true
  )
  buttonCtg.amounts[#buttonCtg.amounts+1] = btn
end

local function createActionButtons()
  local height = 3
  local spacing = 1
  
  local topmost = math.ceil(top+(bottom-top)/2 - (#actions*(height+spacing)-spacing)/2)
  
  for i=1,#actions do
    local btn = newButton(
      "action_"..actions[i], capitalize(actions[i]),
      cols[4]+2, topmost+(i-1)*(height+spacing), cols[5]-2, topmost+(i-1)*(height+spacing)+height-1,
      "white", "red", true, false, true
    )
    btn.bgrColorOn = "green"
    buttonCtg.actions[#buttonCtg.actions+1] = btn
  end
end

local function createToolbarButtons()
  
end

local function createTabButtons()

end

local function createButtons()
  createOreButtons()
  createUnitButtons()
  createAmountButtons()
  createActionButtons()
  createToolbarButtons()
  createTabButtons()
end

function selectOre(event)

end

function selectUnit(event)

end

function selectAmount(event)

end

--------------------------------------------------

ores = parseFile(orePath)
m = peripheral.wrap(mSide)

m.setTextScale(2)
w, h = m.getSize()
top = 2
bottom = h-1
m.setTextColor(colors.white)
m.setBackgroundColor(colors.black)
m.clear()

buttons = {}
buttonCtg = {
  ores={},
  units={},
  amounts={},
  actions={},
  toolbar={},
  tabs={}
}
selected = nil
unit = "mb"
amount = 0

createButtons()
drawScreen()



--init buttons