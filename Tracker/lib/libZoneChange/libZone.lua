local addon, data = ...

if not Library then Library = {} end
if not Library.libZoneChange then Library.libZoneChange = {} end

LIBZONECHANGE = {}

local _libZoneChange = {}

local LZ = _libZoneChange

if addon.toc.Version == "9.99r99" then
	function LZ.Debug(m, h)
		if h then
			_HEADLINES.Event_Chat_Notify(0,{message=m})
		else
			print(m)
		end
	end
else
	function LZ.Debug(m)
	end
end

local _esub_last = 0
local playerID = Inspect.Unit.Lookup("player")

local lzZONE = {}

local lzQZONE = {
	-- Chronicles
	["q2144167A0987645A"] = { qt="CHR", qn = "The Fallen Prince", qz = "Chronicle: Greenscale's Blight" },
	["q5EB3877F6405F1A9"] = { qt="CHR", qn = "Runes of Corruption", qz = "Hammerknell Fortress: Runes of Corruption" },
	["q5C975261188C5B9C"] = { qt="CHR", qn = "Runes of Corruption", qz = "Hammerknell Fortress: Runes of Corruption" },
	["q3A296526271E1DCD"] = { qt="CHR", qn = "Chains of Death", qz = "River of Souls: Chains of Death" },
	-- 10 man slivers
	["q6F5D39887D8A8ED3"] = { qt="SLV", qn = "The Drowned Halls", qz = "The Drowned Halls" },
	["q5DA5F06F782205B9"] = { qt="SLV", qn = "The Gilded Prophecy", qz = "Gilded Prophecy" },
	["q2ADE7614AA401E84"] = { qt="SLV", qn = "Rise of the Phoenix", qz = "Rise of the Phoenix" },
	["q31470E266B4D4A1C"] = { qt="SLV", qn = "Feast of Heroes", qz = "Primeval Feast" },
	["qFDB8CA5333942688"] = { qt="SLV", qn = "Revenge of the Ascended", qz = "Triumph of the Dragon Queen" },
	-- PVP areas
	["q5FAF0EB42AC65A22"] = { qt="CQS", qn = "Conquest: Stillmoor", qz = "Conquest: Stillmoor" },
	["q604C357A13A50C61"] = { qt="CQS", qn = "Conquest: Stillmoor", qz = "Conquest: Stillmoor" },
}

LZ.p_curZone = nil
LZ.p_prvZone = nil
LZ.p_ZQActive = false
LZ.p_ZQqID = false
LZ.p_qRetry = {}

function LZ.RaiseZoneChange(zn, zid)
	LZ.p_curZone = zid
	if LZ.p_curZone ~= LZ.p_prvZone then
		LIBZONECHANGE.currentZoneID = zid
		LIBZONECHANGE.currentZoneName = zn
		LZ.Debug(string.format("ZC: %s -> %s", tostring(lzZONE[LZ.p_prvZone]), tostring(lzZONE[zid])), true)
		LZ.p_prvZone = zid
		LZ.handle(zn, zid)
	end
end

function LZ.Event_System_Update_Begin(h)
	if LZ.p_curZone == nil then
		local pd = Inspect.Unit.Detail("player")
		if pd and pd.zone then
			if lzZONE[pd.zone] == nil then
				local zd = Inspect.Zone.Detail(pd.zone)
				if zd and zd.name then
					lzZONE[pd.zone] = zd.name
				end
			end
			if lzZONE[pd.zone] and pd.zone ~= LZ.p_prvZone then
				LIBZONECHANGE.actualZoneID = pd.zone
				LIBZONECHANGE.actualZoneName = lzZONE[pd.zone]
				LZ.RaiseZoneChange(lzZONE[pd.zone], pd.zone)
			end
		end
	end
	LZ.Event_Quest_Accept(0, LZ.p_qRetry)
	if LZ.p_ZQqID ~= false then
		local _esub_crnt = Inspect.Time.Real()
		if _esub_crnt - _esub_last > 5 then
			local ql = Inspect.Quest.List()
			if ql and ql[LZ.p_ZQqID] == nil then
				LZ.Event_Quest_Complete(0,{[LZ.p_ZQqID] = true})
			end
			_esub_last = _esub_crnt
		end
	end
end

function LZ.Event_Unit_Detail_Zone(h,u)
	if u[playerID] and LZ.p_ZQActive == false then
		LZ.p_curZone = nil
	end
end

function LZ.Event_Unit_Availability_Full(h,t)
	for k,v in pairs(t) do
		if v == "player" and LZ.p_ZQActive == false then
			LZ.p_curZone = nil
			break
		end
	end
end

function LZ.Event_Quest_Accept(h,t)
	for k,v in pairs(t) do
		if lzQZONE[k] ~= nil then
			local zid = Inspect.Unit.Detail("player").zone
			if zid then
				if lzZONE[zid] ~= nil then
					LIBZONECHANGE.actualZoneID = zid
					LIBZONECHANGE.actualZoneName = Inspect.Zone.Detail(LIBZONECHANGE.actualZoneID).name
					lzZONE[string.format("%s.%s", LIBZONECHANGE.actualZoneID, lzQZONE[k].qt)] = lzQZONE[k].qz
					LZ.p_ZQActive = true
					LZ.p_ZQqID = k
					LZ.p_qRetry[k] = nil
					LZ.RaiseZoneChange(lzQZONE[k].qz, string.format("%s.%s", LIBZONECHANGE.actualZoneID, lzQZONE[k].qt))
				else
					local zd = Inspect.Zone.Detail(zid)
					if zd and zd.name then
						lzZONE[zid] = zd.name
					end
					LZ.p_ZQActive = false
					LZ.p_qRetry[k] = true
				end
			else
				LZ.p_ZQActive = false
				LZ.p_qRetry[k] = true
			end
			break
		end
	end
end

function LZ.Event_Quest_Abandon(h,t)
	for k,v in pairs(t) do
		if lzQZONE[k] ~= nil then
			LZ.p_qRetry[k] = nil
			LZ.p_curZone = nil
			LZ.p_ZQActive = false
			LZ.p_ZQqID = false
			break
		end
	end
end

function LZ.Event_Quest_Change(h,t)
	for k,v in pairs(t) do
		if lzQZONE[k] ~= nil and LZ.p_ZQActive == false then
			LZ.Event_Quest_Accept(0,{[k] = true})
			LZ.p_ZQActive = true
			LZ.p_ZQqID = k
			break
		end
	end
end

function LZ.Event_Quest_Complete(h,t)
	for k,v in pairs(t) do
		if lzQZONE[k] ~= nil then
			LZ.p_ZQActive = false
			LZ.p_ZQqID = false
		end
	end
end

function LZ.Event_libZoneChange_Player(zn, zid)
	print(string.format("Event_libZoneChange_Player(%s,%s)", zn, zid))
end

function LZ.Library_libZoneChange_Player(h, zn, zid)
	print(string.format("Library_libZoneChange_Player(%s,%s)", zn, zid))
end

Command.Event.Attach(Event.System.Update.Begin, LZ.Event_System_Update_Begin, "Event.System.Update.Begin")
Command.Event.Attach(Event.Unit.Detail.Zone, LZ.Event_Unit_Detail_Zone, "Event.Unit.Detail.Zone")
Command.Event.Attach(Event.Unit.Availability.Full, LZ.Event_Unit_Availability_Full, "Event.Unit.Availability.Full")
Command.Event.Attach(Event.Quest.Accept, LZ.Event_Quest_Accept, "Event.Quest.Accept")
Command.Event.Attach(Event.Quest.Abandon, LZ.Event_Quest_Abandon, "Event.Quest.Abandon")
Command.Event.Attach(Event.Quest.Change, LZ.Event_Quest_Change, "Event.Quest.Change")
Command.Event.Attach(Event.Quest.Complete, LZ.Event_Quest_Complete, "Event.Quest.Complete")

LZ.handle, Library.libZoneChange.Player = Utility.Event.Create(addon.identifier, "Player")

--table.insert(Event.libZoneChange.Player, { LZ.Event_libZoneChange_Player, addon.identifier, "Event.libZoneChange.Player"})
--Command.Event.Attach(Library.libZoneChange.Player, LZ.Library_libZoneChange_Player, "Library.libZoneChange.Player")

print(string.format("v%s loaded.", addon.toc.Version))