achievements = {}
achievements["Silverwood"] = "The Foul Enemies of the Wood"
achievements["Gloamwood"] = "A Grizzly Business"
achievements["Freemarch"] = "Freemarch Exterminator"
achievements["Stonefield"] = "Fields of Shattered Foes"
achievements["Scarlet Gorge"] = "I Like it Rare"
achievements["Scarwood Reach"] = "Big Game Hunter"
achievements["Moonshade Highlands"] = "The Hidden Threat"
achievements["Droughtlands"] = "Seldom Seen"
achievements["Iron Pine Peak"] = "Peaks Assassin"
achievements["Shimmersand"] = "Stalking the Sands"
achievements["Stillmoor"] = "A Dangerous Endeavor"
achievements["Ember Isle"] = "It's Always Hunting Season"
achievements["Cape Jule"] = "Stalking the Jungle"
achievements["City Core"] = "Rare Breed"
achievements["Eastern Holdings"] = "How Would You Like Your Mob?"
achievements["Ardent Domain"] = "Prey to Play"
achievements["Kingsward"] = "The King's Hunt"
achievements["Ashora"] = "Ashoradly Dead"
achievements["The Dendrome"] = "Rooting Them Out"
achievements["Kingdom of Pelladane"] = "Chain of Command"
achievements["Seratos"] = "No Escape"
achievements["Morban"] = "The Elusive Obvious"
achievements["Steppes of Infinity"] = "Extinction Distinction"

local addon = ...
local targets = {}
local filteredList = {}
local string_format = string.format
local T = { UI = {} }
local currentZone 

function buildUI() 
	T.context = UI.CreateContext(addon.identifier)
	T.context:SetSecureMode("restricted")
	T.UI.button = UI.CreateFrame("Texture", "T.UI.button", T.context)
	T.UI.button:SetTexture(addon.identifier, "img/img-thing.jpg")
	T.UI.button:SetSecureMode("restricted")
	T.UI.button:SetLayer(1)

	T.UI.button:EventAttach(Event.UI.Input.Mouse.Right.Down, function(self, h)
		if Inspect.System.Secure() == false then
			self.MouseDown = true
			local mouseData = Inspect.Mouse()
			self.sx = mouseData.x - T.UI.button:GetLeft()
			self.sy = mouseData.y - T.UI.button:GetTop()		
		end
	end, "Event.UI.Input.Mouse.Right.Down")

	T.UI.button:EventAttach(Event.UI.Input.Mouse.Right.Up, function(self, h)
		self.MouseDown = false
		Tracker_Settings.buttonx = T.UI.button:GetLeft()
		Tracker_Settings.buttony = T.UI.button:GetTop()
	end, "Event.UI.Input.Mouse.Right.Up")

	T.UI.button:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(self, h)
		if self.MouseDown then
			local nx, ny
			local mouseData = Inspect.Mouse()
			nx = mouseData.x - self.sx
			ny = mouseData.y - self.sy
			T.UI.button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nx,ny)
		end
	end, "Event.UI`	.Input.Mouse.Cursor.Move")
	T.UI.button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Tracker_Settings.buttonx, Tracker_Settings.buttony)
	T.UI.button:SetHeight(30)
	T.UI.button:SetWidth(30)
end

local function mapChange(h, zoneName, zoneID)
	print (string.format("Map changed: %s", zoneName))
	currentZone = zoneName	
	setMacro()
end

local function track(h, args)
	print("What?")
	setMacro()
end 

function setMacro()
	local macroText = "suppressmacrofailures"
	for k,v in pairs(filteredList) do
		local d = Inspect.Achievement.Detail(k)
		if (d.name == achievements[currentZone]) then
			for l,w in pairs(d.requirement) do
				if (w.complete ~= true) then
					macroText = string_format("%s\ntargetexact %s", macroText, w.name)
				end				
			end
		end
	end
	T.UI.button:SetVisible(true)
	T.UI.button:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macroText)
	T.UI.button:SetTexture(addon.identifier, "img/img-thing.png")
	
end

local default_settings = {
	buttonx = 200, buttony = 200
}

local function MergeTable(o,n)
	for k,v in pairs(n) do
		if type(v) == "table" then
			if o[k] == nil then
				o[k] = {}			
			end
	 	 	if type(o[k]) == 'table' then
	 			MergeTable(o[k], n[k])
	 	 	end
		else
			if o[k] == nil then
				o[k] = v
			end
		end
	end
end

local function loaded(h, a)
	local achvlist = {}

	achvlist = Inspect.Achievement.List()	

	for k,v in pairs(achvlist) do
		local d = Inspect.Achievement.Detail(k)
		for l,w in pairs(achievements) do
			if (d.name == w) then
				filteredList[k] = v
			end
		end
	end

	if Tracker_Settings == nil then Tracker_Settings = {} end
	MergeTable(Tracker_Settings, default_settings)

	buildUI()
end

--table.insert (Event.Addon.Load.End, {loaded, "Tracker", "loaded"})
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, loaded, "Event.Addon.SavedVariables.Load.End")
Command.Event.Attach(Library.libZoneChange.Player, mapChange, "Library.libZoneChange.Player")
Command.Event.Attach(Command.Slash.Register("tracker"), track, "Command.Slash.Register")