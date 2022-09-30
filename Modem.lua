--------------------------------------------------
--UTILS--

local function RandomString(length)
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
--MODEM--

local Modem = {}
Modem.__index = Modem
function Init(side)
  local m = peripheral.wrap(side)
  if not m then
    error("Error: Modem not found! ("..side..")")
  end
  local modem = {
    modem=m,
    side=side,
    ports={}
  }
  setmetatable(modem, Modem)
  return modem
end




function Modem:SimpleSend(port, message)
  self.modem.transmit(port, port, message)
end

function Modem:Send(port, data, signature)
  local stamp
  if signature then
    stamp = signature
  else
    stamp = RandomString(8)
  end
  
  local packet = {DATA=data, SIGNATURE=stamp}
  self.modem.transmit(port, port, textutils.serialize(packet))
  
  return stamp
end



function Modem:SimpleReceive(port, timeout)
  local wasOpen = self.modem.isOpen(port)
  if not wasOpen then
    self.modem.open(port)
    self.ports[port] = true
  end
  
  local timerID
  if timeout then
    timerID = os.startTimer(timeout)
  end
  
  local message
  
  while true do
    local e, s, p, r, msg = os.pullEvent()
    if e == "modem_message" and s == self.side and p == port then
      message = msg
      break
    elseif timeout and e == "timer" and s == timerID then
      message = false
      break
    end
  end
  
  if not wasOpen then
    self.modem.close(port)
    self.ports[port] = nil
  end
  
  return message
end


function Modem:Receive(port, signature, timeout)
  local wasOpen = self.modem.isOpen(port)
  if not wasOpen then
    self.modem.open(port)
    self.ports[port] = true
  end
  
  local timerID
  if timeout then
    timerID = os.startTimer(timeout)
  end
  
  local data, stamp
  
  while true do
    local e, s, p, r, msg = os.pullEvent()
    if e == "modem_message" and s == self.side and p == port and type(msg) == "string" then
      local packet = textutils.unserialize(msg)
      if packet and packet.SIGNATURE then
        if signature then
          if packet.SIGNATURE == signature then
            data = packet.DATA
            stamp = packet.SIGNATURE
            break
          end
        else
          data = packet.DATA
          stamp = packet.SIGNATURE
          break
        end
      end
    elseif timeout and e == "timer" and s == timerID then
      data = false
      stamp = false
      break
    end
  end
  
  if not wasOpen then
    self.modem.close(port)
    self.ports[port] = nil
  end
  
  return data, stamp
end
