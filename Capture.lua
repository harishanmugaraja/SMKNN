local Game = nil

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

function getController()
	local buttons = {}
	local state = joypad.get(1)
	
	for b=1,#ButtonNames do
		button = ButtonNames[b] 
		if state[button] then
			buttons[b] = 1
		else
			buttons[b] = 0
		end
	end	
	
	if state["L"] or state["R"] or client.isConnected() and sourceIsNN then
		buttons[5] = -1
	end

	
	return buttons
end

session = {}
currentSession = 1
recording = false
playing = false
capFilename = ""
capPath = ""
firstWrite = true

function resetSessions()
	session = {}
	currentSession = 1
	recording = false
	playing = false
	
	capFilename = os.date("cap%b%d%H%M%S.txt")
	capPath = "Capture\\" .. capFilename
end

resetSessions()

function start()
	if firstWrite then
		firstWrite = false
		writeHeader()
	end
	
	if recording then return end
	forms.settext(statusLabel, "Status: Capturing..." .. (currentSession))
	
	session = {}
	recording = true
end

function stop()
	if not recording then return end
	forms.settext(statusLabel, "Status: Stopped.")
	
	recording = false
	if #session > 0 then
		writeFile()
		session = {}
	end
end

function writeHeader()
	print("Opening " .. capPath .. " for write.")
	local file = io.open(capPath, "a+")
	file:write(Game.fileHeader(#ButtonNames) .. "\n")
	file:close()
end

function writeFile()
	print("Opening " .. capPath .. " for write.")
	local file = io.open(capPath, "a+")
	file:write("Session " .. currentSession .. "\n")
	for t=1,#session do
		timestep = session[t]
		file:write(Game.screenText(timestep.inputs))
		
		for o=1,#timestep.outputs do
			file:write(timestep.outputs[o] .. " ")
		end
		file:write("\n")
	end
	file:close()
	
	
	forms.settext(statusLabel, "Wrote Session " .. currentSession .. " to file")
	session = {}
	currentSession = currentSession + 1

end

client = require("NNClient")

function connect()
	if client.isConnected() then
		forms.settext(connectButton, "NN Start")
		client.close()
	else
		forms.settext(connectButton, "NN Stop")
		client.connect(forms.gettext(hostnameBox))
		if client.isConnected() then
			print("Connected.")
		else
			print("Unable to connect.")
		end
		
		header = client.receiveHeader()
		local verify = true
		if firstWrite then
			-- If we haven't written the header yet, it's okay
			-- to reconfigure the parameters.
			verify = false
		end
		Game.configure(header, verify)
	end
end

display = false

function displayCallback()
	display = not display
	if display then
		forms.settext(displayButton, "-Screen")
	else
		forms.settext(displayButton, "+Screen")
	end
		
end

form = forms.newform(195, 275, "Capture")
statusLabel = forms.label(form, "Status: Stopped.", 3, 6, 189, 15)
startButton = forms.button(form, "Start", start, 3, 33)
stopButton = forms.button(form, "Stop", stop, 100, 33)

hostnameBox = forms.textbox(form, "Seth-Laptop2", 100, 20, "TEXT", 60, 70)
forms.label(form, "Hostname:", 3, 73)
connectButton = forms.button(form, "NN Start", connect, 3, 100)

playerFromBox = forms.textbox(form, "30", 40, 20, "UNSIGNED", 3, 140)
playerToBox = forms.textbox(form, "60", 40, 20, "UNSIGNED", 60, 140)
forms.label(form, "Player Frames", 3, 125)
forms.label(form, "to", 45, 145)

NNFromBox = forms.textbox(form, "30", 40, 20, "UNSIGNED", 3, 180)
NNToBox = forms.textbox(form, "60", 40, 20, "UNSIGNED", 60, 180)
forms.label(form, "NN Frames", 3, 165)
forms.label(form, "to", 45, 185)

displayButton = forms.button(form, "+Screen", displayCallback, 3, 170, 150)

function onExit()
	forms.destroy(form)
	
	client.close()
end

event.onexit(onExit)

recFrame = 0
screen = nil
sourceIsNN = true
sourceSwap = math.random(15,30)
nnJoypad = joypad.get(1)

while true do
	if recFrame % 4 == 0 then
		screen = Game.getScreen(1)
		
		if client.isConnected() then
			client.sendScreen(screen)
			buttons = client.receiveButtons(ButtonNames)
			
			sourceSwap = sourceSwap - 1
			if sourceSwap <= 0 then
				sourceIsNN = not sourceIsNN
				local from, to
				if sourceIsNN then
					from = forms.gettext(NNFromBox)
					to = forms.gettext(NNFromBox)
				else
					from = forms.gettext(playerFromBox)
					to = forms.gettext(playerToBox)
				end
				if from == "" then from = "4" end
				if to == "" then to = "4" end
				from = math.floor(tonumber(from)/4)
				to = math.floor(tonumber(to)/4)
				
				if to <= from then
					to = from + 1
				end
				sourceSwap = math.random(from, to)
			end
			
			if sourceIsNN then
				for b=1,#ButtonNames do
					name = ButtonNames[b]
					nnJoypad[name] = buttons[name]
				end
			end
		end
		
	end
	if client.isConnected() and sourceIsNN then
		joypad.set(nnJoypad, 1)
	end
	
	if recording then
		if not Game.isGameplay() and playing then
			playing = false
			writeFile()
		end
		if Game.isGameplay() then
			if not playing then
				session = {}
				playing = true
				print("Starting session " .. currentSession)
			end
			if recFrame % 4 == 0 then
				timeStep = {}
				timeStep["inputs"] = Game.getScreen(1)
				timeStep["outputs"] = getController()
				session[#session+1] = timeStep
			end
		end
	end
	recFrame = recFrame + 1
	
	if display then
		Game.displayScreen(screen)
	end
	
	if client.isConnected() then
		if sourceIsNN then
			gui.drawText(5, 5, "Control: Neural network")
		else
			gui.drawText(5, 5, "Control: Player")
		end
	end
	
	emu.frameadvance();
end