--------------------------------------------------
--TABLES--
--------------------------------------------------

function TableMerge(...)
  local result = {}
  for n,t in ipairs(arg) do
    for obj,val in pairs(t) do
      result[obj] = val
    end
  end
  return result
end


--------------------------------------------------
--STRINGS--
--------------------------------------------------

function Capitalize(str)
  return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

function StringSplit(str, separator)
  local result = {}
  local part = ""
  local idx = 1
  for i=1,#str do
    local ch = string.sub(str, i, i)
    if ch == separator then
      result[idx] = part
      part = ""
      idx = idx + 1
    else
      part = part .. ch
    end
  end
  result[idx] = part
  return result
end

function RandomString(length)
  local result = ""
  for i=1,length do
    local n = math.random(0, 61)
    if n < 10 then
      result = result .. string.char(n + 48)
    elseif n < 36 then
      result = result .. string.char(n + 55)
    else
      result = result .. string.char(n + 61)
    end
  end
  return result
end


--------------------------------------------------
--NUMBERS & MATH--
--------------------------------------------------

function Round(n)
  return math.floor(n + 0.5)
end


--------------------------------------------------
--FILES--
--------------------------------------------------

function ParseFile(fPath)
  local f = fs.open(fPath, "r")
  local fText = f.readAll()
  f.close()
  return textutils.unserialize(fText)
end


--------------------------------------------------
--DISPLAY--
--------------------------------------------------

function Write(m, x, y, text, txtCol, bgrCol)
  if txtCol then
    m.setTextColor(colors[txtCol])
  end
  if bgrCol then
    m.setBackgroundColor(colors[bgrCol])
  end
  m.setCursorPos(x, y)
  m.write(tostring(text))
end


function Draw(m, x1, y1, x2, y2, ch, txtCol, bgrCol)
  if txtCol then
    m.setTextColor(colors[txtCol])
  end
  if bgrCol then
    m.setBackgroundColor(colors[bgrCol])
  end
  local ch = tostring(ch)
  for y=y1,y2 do
    for x=x1,x2 do
      m.setCursorPos(x, y)
      m.write(ch)
    end
  end
end
