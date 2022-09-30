--------------------------------------------------
--UTILS--

local function TableMerge(...)
  local result = {}
  for n,t in ipairs(arg) do
    for obj,val in pairs(t) do
      result[obj] = val
    end
  end
  return result
end


--------------------------------------------------
--ELEMENTS--

local Element = {}
Element.__index = Element
function NewElement(name, text, x1, y1, x2, y2, txtColor, bgrColor, hidden, enabled, align)
  local elem = {
    name=name,
    x1=x1, y1=y1,
    x2=x2, y2=y2,
    enabled=enabled,
    _enabled=true,
    pressed=false,
    hidden=hidden,
    txtColor=txtColor,
    txtColorPressed=txtColor,
    txtColorDisabled=txtColor,
    bgrColor=bgrColor,
    bgrColorPressed=bgrColor,
    bgrColorDisabled=bgrColor,
    text=text,
    align=align,
    parent=nil,
    disableDefaultDraw=false,
    --onClick=nil,
    --onBeforeDraw=nil,
    --onAfterDraw=nil,
  }
  setmetatable(elem, Element)
  return elem
end


function Element:Disable()
  self.enabled = false
end


function Element:Enable()
  self.enabled = self._enabled
end


function Element:Hide()
  self.hidden = true
  
  if self.parent and self.parent.parent and self.parent.parent.scrollable then
    self.parent.parent:UpdateScrolling()
  end
end


function Element:Show()
  self.hidden = false
  
  if self.parent and self.parent.parent and self.parent.parent.scrollable then
    self.parent.parent:UpdateScrolling()
  end
end


function Element:Move(dx, dy)
  self.x1 = self.x1 + dx
  self.x2 = self.x2 + dx
  self.y1 = self.y1 + dy
  self.y2 = self.y2 + dy
end


function Element:IsValidPoint(x, y, shallow)
  if x<self.x1 or x>self.x2 or y<self.y1 or y>self.y2 then
    return false
  end
  if not shallow and self.parent then
    return self.parent:IsValidPoint(x, y, false)
  end
  return true
end


function Element:Draw(m)
  if self.hidden then
    return
  end
  
  if self.onBeforeDraw then
    self.onBeforeDraw(m)
  end
  
  if not self.enabled then
    if self.bgrColorDisabled then
      m.setBackgroundColor(colors[self.bgrColorDisabled])
    end
    if self.txtColorDisabled then
      m.setTextColor(colors[self.txtColorDisabled])
    end
  elseif self.pressed then
    if self.bgrColorPressed then
      m.setBackgroundColor(colors[self.bgrColorPressed])
    end
    if self.txtColorPressed then
      m.setTextColor(colors[self.txtColorPressed])
    end
  else
    if self.bgrColor then
      m.setBackgroundColor(colors[self.bgrColor])
    end
    if self.txtColor then
      m.setTextColor(colors[self.txtColor])
    end
  end
  
  local text = tostring(self.text)
  
  if not self.disableDefaultDraw then
    local i = 1
    if self.align=="middle" or self.align=="center" then
      i = math.ceil(#text/2 - ((self.x2-self.x1+1)*(self.y2-self.y1+1))/2 + 1)
    elseif self.align=="right" then
      i = 1 + #text - (self.x2-self.x1+1)*(self.y2-self.y1+1)
    end
    
    for y=self.y1, self.y2 do
      for x=self.x1, self.x2 do
        
        if self:IsValidPoint(x, y, false) then
          m.setCursorPos(x,y)
          local ch=" "
          if i>=1 and i<=#text then
            ch = text:sub(i, i)
          end
          m.write(ch)
        end
        i=i+1
        
      end
    end
  end
  
  if self.onAfterDraw then
    self.onAfterDraw(m)
  end
end


function Element:Click(m, x, y, event, shallow)
  if self.enabled and not self.hidden and self:IsValidPoint(x, y, shallow) then
    if self.onClick then
      local result = self.onClick(m, x, y, event)
      if result == nil then
        result = true
      end
      return true, {[self] = result}
    else
      return true, {[self] = true}
    end
  else
    return false, {}
  end
end




--------------------------------------------------
--GROUPS--

local Group = {}
Group.__index = Group
function NewGroup(name, hidden, x1, y1, x2, y2)
  local group = {
    name=name,
    hidden=hidden,
    scrollable=false,
    x1=x1, y1=y1,
    x2=x2, y2=y2,
    groups={},
    elements={},
    parent=nil,
    --onBeforeDraw=nil,
    --onAfterDraw=nil,
  }
  setmetatable(group, Group)
  return group
end


function Group:AddElement(elem)
  if self.elements[elem.name] then
    error("Element '"..elem.name.."' already exists in this group!")
  end
  elem.parent = self
  self.elements[elem.name] = elem
  
  if self.parent and self.parent.scrollable then
    self.parent:UpdateScrolling()
  end
end


function Group:AddGroup(group)
  if self.groups[group.name] then
    error("Group '"..group.name.."' already exists in this group!")
  end
  group.parent = self
  self.groups[group.name] = group
  
  if self.parent and self.parent.scrollable then
    self.parent:UpdateScrolling()
  end
end


function Group:Disable()
  for name,elem in pairs(self.elements) do
    elem:Disable()
  end
  for name,group in pairs(self.groups) do
    group:Disable()
  end
end


function Group:Enable()
  for name,elem in pairs(self.elements) do
    elem:Enable()
  end
  for name,group in pairs(self.groups) do
    group:Enable()
  end
end


function Group:Hide()
  self.hidden = true
  
  for name,elem in pairs(self.elements) do
    elem:Hide()
  end
  for name,group in pairs(self.groups) do
    group:Hide()
  end
  
  if self.parent and self.parent.parent and self.parent.parent.scrollable then
    self.parent.parent:UpdateScrolling()
  end
end


function Group:Show()
  self.hidden = false
  
  for name,elem in pairs(self.elements) do
    elem:Show()
  end
  for name,group in pairs(self.groups) do
    group:Show()
  end
  
  if self.parent and self.parent.parent and self.parent.parent.scrollable then
    self.parent.parent:UpdateScrolling()
  end
end


function Group:UpdateScrolling(m)
  if not self.scrollable then
    error("Group is not scrollable!")
  end
  
  local content = self.groups[self.name.."_content"]
  local minX = math.huge
  local minY = math.huge
  local maxX = -math.huge
  local maxY = -math.huge
  
  for name,elem in pairs(content.elements) do
    if not elem.hidden then
      minX = math.min(minX, elem.x1)
      minY = math.min(minY, elem.y1)
      maxX = math.max(maxX, elem.x2)
      maxY = math.max(maxY, elem.y2)
    end
  end
  for name,group in pairs(content.groups) do
    if not group.hidden then
      minX = math.min(minX, elem.x1)
      minY = math.min(minY, elem.y1)
      maxX = math.max(maxX, elem.x2)
      maxY = math.max(maxY, elem.y2)
    end
  end
  
  if self.scrollable == "horizontal" or self.scrollable == "both" then
    if minX < content.x1 then
      self.elements.scrollLeft.enabled = true
      self.elements.scrollLeft._enabled = true
    else
      self.elements.scrollLeft.enabled = false
      self.elements.scrollLeft._enabled = false
    end
    
    if maxX > content.x2 then
      self.elements.scrollRight.enabled = true
      self.elements.scrollRight._enabled = true
    else
      self.elements.scrollRight.enabled = false
      self.elements.scrollRight._enabled = false
    end
  end
  
  if self.scrollable == "vertical" or self.scrollable == "both" then
    if minY < content.y1 then
      self.elements.scrollUp.enabled = true
      self.elements.scrollUp._enabled = true
    else
      self.elements.scrollUp.enabled = false
      self.elements.scrollUp._enabled = false
    end
    
    if maxY > content.y2 then
      self.elements.scrollDown.enabled = true
      self.elements.scrollDown._enabled = true
    else
      self.elements.scrollDown.enabled = false
      self.elements.scrollDown._enabled = false
    end
  end
  
  if m then
    self:Draw(m)
  end
end


function Group:MakeScrollable(H, V, txtColor, bgrColor, txtColorDisabled, bgrColorDisabled)
  if self.scrollable then
    error("Group already has scrolling!")
  end
  
  if not H and not V then
    error("No scrolling was specified")
  end
  
  if H and V then
    self.scrollable = "both"
  elseif H then
    self.scrollable = "horizontal"
  else
    self.scrollable = "vertical"
  end
  
  if not H then
    H = {size=0, step=0, iconLeft="", iconRight="", fake=true}
  end
  if not V then
    V = {size=0, step=0, iconUp="", iconDown="", fake=true}
  end
  
  local content = NewGroup(self.name.."_content", self.hidden, self.x1+H.size, self.y1+V.size, self.x2-H.size, self.y2-V.size)
  
  for name,elem in pairs(self.elements) do
    content:AddElement(elem)
  end
  for name,group in pairs(self.groups) do
    content:AddGroup(group)
  end
  
  self.elements = {}
  self.groups = {}
  self:AddGroup(content)
  
  content:MoveContent(H.size, V.size)
  
  if not H.fake then
    local scrollLeft = NewElement("scrollLeft", H.iconLeft, self.x1, self.y1, self.x1+H.size-1, self.y2, txtColor, bgrColor, self.hidden, false, "center")
    local scrollRight = NewElement("scrollRight", H.iconRight, self.x2-H.size+1, self.y1, self.x2, self.y2, txtColor, bgrColor, self.hidden, false, "center")
    
    if txtColorDisabled then
      scrollLeft.txtColorDisabled = txtColorDisabled
      scrollRight.txtColorDisabled = txtColorDisabled
    end
    if bgrColorDisabled then
      scrollLeft.bgrColorDisabled = bgrColorDisabled
      scrollRight.bgrColorDisabled = bgrColorDisabled
    end
    
    scrollLeft._enabled = false
    scrollRight._enabled = false
    scrollLeft.scrollStep = H.step
    scrollRight.scrollStep = -H.step
    
    scrollLeft.onClick = function(m, x, y, event)
      content:MoveContent(scrollLeft.scrollStep, 0)
      self:UpdateScrolling(m)
    end
    scrollRight.onClick = function(m, x, y, event)
      content:MoveContent(scrollRight.scrollStep, 0)
      self:UpdateScrolling(m)
    end
    
    self:AddElement(scrollLeft)
    self:AddElement(scrollRight)
  end
  
  if not V.fake then
    local scrollUp = NewElement("scrollUp", V.iconUp, self.x1, self.y1, self.x2, self.y1+V.size-1, txtColor, bgrColor, self.hidden, false, "center")
    local scrollDown = NewElement("scrollDown", V.iconDown, self.x1, self.y2, self.x2, self.y2-V.size+1, txtColor, bgrColor, self.hidden, false, "center")
    
    if txtColorDisabled then
      scrollUp.txtColorDisabled = txtColorDisabled
      scrollDown.txtColorDisabled = txtColorDisabled
    end
    if bgrColorDisabled then
      scrollUp.bgrColorDisabled = bgrColorDisabled
      scrollDown.bgrColorDisabled = bgrColorDisabled
    end
    
    scrollUp._enabled = false
    scrollDown._enabled = false
    scrollUp.scrollStep = V.step
    scrollDown.scrollStep = -V.step
    
    scrollUp.onClick = function(m, x, y, event)
      content:MoveContent(0, scrollUp.scrollStep)
      self:UpdateScrolling(m)
    end
    scrollDown.onClick = function(m, x, y, event)
      content:MoveContent(0, scrollDown.scrollStep)
      self:UpdateScrolling(m)
    end
    
    self:AddElement(scrollUp)
    self:AddElement(scrollDown)
  end
  
  self:UpdateScrolling()
end


function Group:ApplyElemProperty(prop, val, recursive)
  for name,elem in pairs(self.elements) do
    elem[prop] = val
  end
  
  if recursive then
    for name,group in pairs(self.groups) do
      group:ApplyElemProperty(prop, val, true)
    end
  end
end


function Group:Move(dx, dy)
  self.x1 = self.x1 + dx
  self.x2 = self.x2 + dx
  self.y1 = self.y1 + dy
  self.y2 = self.y2 + dy
  self:MoveContent(dx, dy)
end


function Group:MoveContent(dx, dy)
  for name,elem in pairs(self.elements) do
    elem:Move(dx, dy)
  end
  for name,group in pairs(self.groups) do
    group:Move(dx, dy)
  end
end


function Group:Click(m, x, y, event, shallow)
  if not self.hidden and self:IsValidPoint(x, y, shallow) then
    local result = {}
    local success = false
    
    for name,elem in pairs(self.elements) do
      local s, r = elem:Click(m, x, y, event, true)
      result = TableMerge(result, r)
      success = s or success
    end
    for name,group in pairs(self.groups) do
      local s, r = group:Click(m, x, y, event, true)
      result = TableMerge(result, r)
      success = s or success
    end
    
    return success, result
  else
    return false, {}
  end
end


function Group:IsValidPoint(x, y, shallow)
  if x<self.x1 or x>self.x2 or y<self.y1 or y>self.y2 then
    return false
  end
  if not shallow and self.parent then
    return self.parent:IsValidPoint(x, y, false)
  end
  return true
end


function Group:Draw(m)
  if self.hidden then
    return
  end
  
  if self.onBeforeDraw then
    self.onBeforeDraw(m)
  end
  
  for name,group in pairs(self.groups) do
    group:Draw(m)
  end
  for name,elem in pairs(self.elements) do
    elem:Draw(m)
  end
  
  if self.onAfterDraw then
    self.onAfterDraw(m)
  end
end


function Group:GetMidX()
  return (self.x1+self.x2)/2
end


function Group:GetMidY()
  return (self.y1+self.y2)/2
end
