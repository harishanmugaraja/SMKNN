getmetatable('').__index = function(str,i) return string.sub(str,i,i) end

local NNClient = {}

NNClient.client = nil

function NNClient.connect(host)
	local socket = require("socket")
	local port = 2222
	print("Connecting to " .. host  .. ":" .. port .. "...")
	NNClient.client = socket.connect(host, port)
	NNClient.client:settimeout(nil)
end

function NNClient.close()
	if NNClient.client ~= nil then
		NNClient.client:send("close\n")
		NNClient.client:close()
	end
	NNClient.client = nil
end

function NNClient.isConnected()
	return NNClient.client ~= nil
end

function NNClient.sendScreen(screen)
	local send = ""
	local first = true
	for i=1,#screen do
		if first then
			first = false
		else
			send = send .. " "
		end
		send = send .. screen[i]
	end
	
	send = send .. "\n"
	
	NNClient.client:send(send)
end

function receiveLine()
	local data,err = NNClient.client:receive()
	
	if err ~= nil then
		print("Socket Error: " .. err)
	end
	
	if data == nil then
		NNClient.close()
		return nil
	end
	
	return data
end

function NNClient.receiveButtons(ButtonNames)
	local data = receiveLine()
	if #data ~= 2*#ButtonNames-1 then
		NNClient.close()
		print("Data Error: Unexpected buttons length " .. #data)
		return
	end

	local jstate = {}
	for i=1,#ButtonNames do
		local button = ButtonNames[i]
		local pressed = data[i*2-1]
		if pressed == "0" then
			jstate[button] = false
		elseif pressed == "1" then
			jstate[button] = true
		else
			print("Data Error: Invalid Press State " .. pressed)
		end
	end
	
	return jstate
end

function NNClient.receiveHeader()
	local numParams = receiveLine()
	local header = {}
	for i=1,numParams do
		header[i] = receiveLine()
	end
	
	return header
end

return NNClient