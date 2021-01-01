getmetatable('').__index = function(str,i) return string.sub(str,i,i) end

if gameinfo.getromname () == "Super Mario Kart (USA)" then 
	Game = require("SMKScreen")
elseif gameinfo.getromname() == "Super Mario World (USA)" then
	Game = require("SMWScreen")
end

ButtonNames = {
	"A",
	"B",
	"X",
	"Y",
	"Up",
	"Down",
	"Left",
	"Right",
}

local client = require("NNClient")

function onExit()
	forms.destroy(form)

	client.close()
end

event.onexit(onExit)

function connect()
	if client.isConnected() then	
		client.close()
		forms.settext(connectButton, "NN Start")
	else
		client.connect(forms.gettext(hostnameBox))

		if not client.isConnected() then
			print("Unable to connect to local server")
			return
		else
			print("Connected successfully.")
		end

		header = client.receiveHeader()
		Game.configure(header, false)
		forms.settext(connectButton, "NN Stop")
	end
end

form = forms.newform(195, 110, "Remote")
hostnameBox = forms.textbox(form, "Seth-Laptop2", 100, 20, "TEXT", 60, 10)
forms.label(form, "Hostname:", 3, 13)
connectButton = forms.button(form, "NN Start", connect, 3, 40)

local player = 1
local jstate = joypad.get(player)

local frame = 0

while true do
	if client.isConnected() then
		if frame % 4 == 0 then
			storedScreen = Game.getScreen(player)
			client.sendScreen(storedScreen)
			jstate = client.receiveButtons(ButtonNames)
		end
		
		currentJoypad = joypad.get(player)
		for i=1,#ButtonNames do
			button = ButtonNames[i]
			currentJoypad[button] = jstate[button]
		end
		joypad.set(currentJoypad, player)
		
		--Game.displayScreen(storedScreen)
		
		frame = frame + 1
	end

	emu.frameadvance();
end