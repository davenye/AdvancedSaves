-- THIS CODE IS TERRIBLE AND BORN OF FRUSTRATION WITH CIV INITIALISATION FIASCO
-- BASIC COMMON PROGRAMMING SENSE WAS DISREGARDED AND EVERY CHANGE WAS TO BE MY LAST
include( "InstanceManager" );
include( "IconSupport" );
include( "SupportFunctions" );
include( "UniqueBonuses" );
include( "MapUtilities" );

AdvSav = {};

if(not MapModData) then
	return;
end


if(not MapModData.AdvSav) then
	MapModData.AdvSav = {};
end
		
UserData = Modding.OpenUserData("AdvSav", 1);

local function GetData()
	return MapModData.AdvSav.Data;
end

local function deepcopy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[deepcopy(k, s)] = deepcopy(v, s) end
  return res
end
------------------------------------------------------------------

local SaveModeOptions = 
{

	{
		label = "At Intervals",
		tooltip = "turns between",
		needs_edit = true
	},
	{
		label = "On Request",
		tooltip = "ask nicely",
		needs_edit = false
	},
	{
		label = "Never",
		tooltip = "...ever",
		needs_edit = false
	}
};

local SaveModeConfigs = 
{

		{
			txt = "Pitboss Host",
			tooltip = "Pitboss Host",
			cat_id = 0,
			pointset = 2,
		},
		{
			txt = "MP Host",
			tooltip = "MP Host",
			cat_id = 1,
			pointset = 2,
		},
		{
			txt = "MP Guest",
			tooltip = "MP Guest",
			cat_id = 2,
			pointset = 2,
		},
		{
			txt = "MP Observer",
			tooltip = "MP Observer",
			cat_id = 3,
			pointset = 2,
		}	,
};

local PointSets =
{
	--sp
	{4,6},
	--mp
	{5,7},
};



--Data = {};



function AdvSav.InitData()
	local idx = 0;
	local Data = GetData();
	
	Data.PostSaves = false;
	
	Data.AllowAutoSaveRequests = false;
	
	Data.AllowForceSave = false;
	Data.AllowQueueSave = false;
	Data.AllowStaleSave = false;
	
	Data.QueuedSavePopup = false;
	Data.AllowAutoSaveRequests = false;
	Data.ShowLastAutoSaveDetails = false;
	
	Data.AllowSaveAndQuit	 = false;
	
	Data.NoHumansNoPosts		= false;
	Data.OnlyHumansNoPosts	  = false;
	Data.DisplayAutosaveMessages  = false;
	
	Data.MinTurnNormal = 0;
	Data.MinTurnPost = 0;
	
	Data.QueuedAuto = {};
	Data.Queued = {};	
	Data.LastSaves = {};
	Data.LastSavePoint = nil;
	
	local Filters = Data.Filters;
	for i,cat in ipairs(SaveModeConfigs) do
		for j,point in ipairs(PointSets[cat.pointset]) do
			idx = idx + 1;
			local default = 1;
			if(j == 2) then
				default = -1;
			end
			Filters[idx] = {cat.cat_id, point, default}; -- default to every turn
		end
	end
end


function AdvSav.LoadData()
		print("LoadData()");
	local Data = GetData();
	Data.AllowAutoSaveRequests = UserData.GetValue("AllowAutoSaveRequests");
	Data.AllowQueueSave = UserData.GetValue("Data.AllowQueueSave");
	Data.AllowForceSave = UserData.GetValue("Data.AllowForceSave");
	Data.AllowStaleSave = UserData.GetValue("Data.AllowStaleSave");
	
	Data.QueuedSavePopup = UserData.GetValue("Data.QueuedSavePopup");
	Data.AllowAutoSaveRequests = UserData.GetValue("Data.AllowAutoSaveRequests");
	Data.ShowLastAutoSaveDetails = UserData.GetValue("Data.ShowLastAutoSaveDetails");
	
	Data.AllowSaveAndQuit = UserData.GetValue("Data.AllowSaveAndQuit");
	Data.NoHumansNoPosts = UserData.GetValue("Data.NoHumansNoPosts");
	Data.OnlyHumansNoPosts = UserData.GetValue("Data.OnlyHumansNoPosts");
	Data.DisplayAutosaveMessages = UserData.GetValue("Data.DisplayAutosaveMessages");
	Data.MinTurnNormal = UserData.GetValue("Data.MinTurnNormal");
	Data.MinTurnPost = UserData.GetValue("Data.MinTurnPost");

		local Filters = Data.Filters;
	for i,conf in ipairs(Filters) do
		
		local value = UserData.GetValue("conf" .. conf[1] .. "_" .. conf[2]);
		if(value ~= nil) then
				conf[3] = value;
		end		
	end
end



function AdvSav.StoreData()
	local Data = GetData();
	UserData.SetValue("AllowAutoSaveRequests", Data.AllowAutoSaveRequests);
	UserData.SetValue("Data.AllowQueueSave", Data.AllowQueueSave);
	UserData.SetValue("Data.AllowForceSave", Data.AllowForceSave);
	UserData.SetValue("Data.AllowStaleSave", Data.AllowStaleSave);
	
	UserData.SetValue("Data.QueuedSavePopup", Data.QueuedSavePopup);
	UserData.SetValue("Data.AllowAutoSaveRequests", Data.AllowAutoSaveRequests);
	UserData.SetValue("Data.ShowLastAutoSaveDetails", Data.ShowLastAutoSaveDetails);
	
	UserData.SetValue("Data.AllowSaveAndQuit", Data.AllowSaveAndQuit);
	UserData.SetValue("Data.NoHumansNoPosts", Data.NoHumansNoPosts);
	UserData.SetValue("Data.OnlyHumansNoPosts", Data.OnlyHumansNoPosts);
	UserData.SetValue("Data.DisplayAutosaveMessages", Data.DisplayAutosaveMessages);
	UserData.SetValue("Data.MinTurnNormal", Data.MinTurnNormal);
	UserData.SetValue("Data.MinTurnPost", Data.MinTurnPost);
			
	local Filters = GetData().Filters;
	for i,conf in ipairs(Filters) do
		UserData.SetValue("conf" .. conf[1] .. "_" .. conf[2], conf[3]);
	end
end

function AdvSav.UpdateData(d)
	
	MapModData.AdvSav.Data = deepcopy(d);
	AdvSav.ApplyData();
end


Lookup = {};
function AdvSav.ApplyData() 
	local Filters = GetData().Filters;
	Lookup = {};
	for i,conf in ipairs(Filters) do		
		if(not Lookup[conf[1]]) then 
			Lookup[conf[1]] = {};
		end
		Lookup[conf[1]][conf[2]] = conf[3];
	end
end

function AdvSav.CopyData()
	local Data = GetData();
	return deepcopy(Data);
end

function AdvSav.GetData()
	return GetData();
end

local function GetBestPlayerTypeMatch()
	if (not PreGame.IsMultiplayerGame()) then
		return 4;
	end

	if (Game.IsPitbossHost()) then
		return 0;
	elseif (Game.IsHost()) then
		return 1;
	end

	if (Game.GetActivePlayer() ~= -1) then
		local player = Players[Game.GetActivePlayer()];
		if (player:IsObserver()) then
			return 3;
		elseif (player:IsHuman()) then
			return 2;
		end
	end
	return -1; --Not sure when this could happen though.	
end


function AdvSav.GetCurrentCat()
	return GetBestPlayerTypeMatch();
end


function OnWantAutoSave(eSavePoint)

	local isPost = false;
	if(eSavePoint == 7) then --TODO fix dis shiz
		isPost = true;
	end
	
	AdvSav.ApplyData();
	
	if(GetData().Queued[eSavePoint] and GetData().Queued[eSavePoint][1] == Game.GetGameTurn()) then
		local qd = GetData().Queued[eSavePoint];
			if(not qd[4]) then
				UI.SaveGame(qd[2]);
			else
				Steam.SaveGameToCloud(qd[2]);
			end
			if(GetData().QueuedSavePopup) then
				local str = "Saved to ";
				if(not qd[4]) then
					str = str .. qd[2];
				else
					str = str .. "Steam Cloud Slot #" .. qd[2];
				end
				Events.GameplayAlertMessage(str); -- popup please but only if not exiting.
				UIManager:QueuePopup( Controls.AdvSavPopup, PopupPriority.TextPopup);
			end
			if (qd[3]) then
				Events.GameplayAlertMessage("Now exiting after save..."); --timed popup please
				UIManager:QueuePopup( Controls.AdvSavPopup, PopupPriority.TextPopup);
				UI.ExitGame();
			end;
		GetData().Queued[eSavePoint] = nil;
	elseif(GetData().Queued[eSavePoint] and GetData().Queued[eSavePoint][1] < Game.GetGameTurn()) then
		GetData().Queued[eSavePoint] = nil; -- could be error here
	end;
	
	if(GetData().QueuedAuto[eSavePoint] and GetData().QueuedAuto[eSavePoint] == Game.GetGameTurn()) then
		GetData().QueuedAuto[eSavePoint] = nil;
		return true;
	elseif(GetData().QueuedAuto[eSavePoint] and GetData().QueuedAuto[eSavePoint] < Game.GetGameTurn()) then
		GetData().QueuedAuto[eSavePoint] = nil; -- could be error here
	end;
	

	if(not isPost and GetData().MinTurnNormal > Game.GetGameTurn()) then
		return false;
	end
	if(isPost and GetData().MinTurnPost  > Game.GetGameTurn()) then
		return false;
	end
		
	local numHumans = 0;
	local numNonHumans = 0;
	for playerID = 0, GameDefines.MAX_CIV_PLAYERS-1, 1 do
	 	local player = Players[playerID];
	 	--if player:IsEverAlive() then
	 	if player:IsAlive() then
	  	if(player:IsHuman() and not player:IsObserver()) then -- don't know if observers are human or even alive
	  		numHumans = numHumans + 1;
	  	elseif(not player:IsMajorCiv()) then
	  		numNonHumans = numHumans + 1;
			end
		end
	end
	
	if(isPost and numHumans == 0 and GetData().NoHumansNoPosts) then return false; end;
	if(isPost and numNonHumans == 0 and GetData().OnlyHumansNoPosts) then return false; end;

	local best = GetBestPlayerTypeMatch();
	 
	 local freq = Lookup[best][eSavePoint];
	 
	 
	 
	 if(freq <= 0) then
		return false;
	end
	local lastturn = GetData().LastSaves[eSavePoint] or -1;
	
	if(lastturn + freq > Game.GetGameTurn()) then
	
		return false;
	end

	 return true;

end

function OnAutoSaved( eSavePoint, saved)	 	
	print ("**** OnAutoSaved ****", eSavePoint,  saved, Game.GetGameTurn());	
	
	if(saved) then 

		GetData().LastSaves[eSavePoint] = Game.GetGameTurn();		
		GetData().LastSavePoint = eSavePoint;
		
		if(GetData().DisplayAutosaveMessages) then
		
		local str = "";

		if(eSavePoint == 7) then
			str = " (Post)";
		end
		Events.GameplayAlertMessage("--- Autosaved Turn " .. Game.GetGameTurn() .. str .. " ---"); 
	end
	
	
	end;
	
end


function AdvSav.CreateData()
		MapModData.AdvSav.Data = {};
		local Data = MapModData.AdvSav.Data;

		Data.Filters = {};
		
		Data.QueuedAuto = {};
		Data.Queued = {};
end

local hasInit = false;
function AdvSav.InitSystem()

		AdvSav.CreateData();
    AdvSav.InitData();
		AdvSav.LoadData();	
			
		AdvSav.ApplyData();
end

function AdvSav.IsActive()
return PreGame.GameStarted() and Game.IsNetworkMultiPlayer() and MapModData and MapModData.AdvSav and MapModData.AdvSav.Active;
end


function AdvSav.QueueAutoSave(point, turn)
	GetData().QueuedAuto[point] = turn; -- bug: won't handle multiple active requests
end

function AdvSav.QueueSave(steam, filename, quit,point, turn)
	GetData().Queued[point] = {turn, filename, quit, steam}; -- bug: won't handle multiple active requests
end

FUCKTHIS = true;
function AdvSav.Hookup() 	
			
		if(MapModData.AdvSav.HookedUp) then return; end;
			MapModData.AdvSav.HookedUp = true;
		
		--Events.LoadScreenClose.Add(function() 
			
		AdvSav.InitSystem();		
		if(Game.IsNetworkMultiPlayer()) then			
		
		--	if(not MapModData.AdvSav.WantAutoSave) then
				GameEvents.WantAutoSave.Add(OnWantAutoSave);
				GameEvents.AutoSaved.Add(OnAutoSaved);
				MapModData.AdvSav.WantAutoSave = true;
			--end
			MapModData.AdvSav.Active = true;				
		else
			MapModData.AdvSav.Active = false;
			--if(MapModData.AdvSav.WantAutoSave) then
				--	GameEvents.WantAutoSave.Remove(OnWantAutoSave);
				--	MapModData.AdvSav.WantAutoSave = false;
			--end
			
		end
		 --end);

end

ContextPtr:SetPostInit( function()
	--AdvSav.Hookup() 
end)

ContextPtr:SetShutdown( function()
	AdvSav.Hookup = false;
	MapModData.AdvSav.Hookup = nil;
	MapModData.AdvSav.HookedUp = false;
	MapModData.AdvSav.Active = false;
		
end)
if(not hackhackhack) then
	--Events.LoadScreenClose.Add(function() print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Events.LoadScreenClose."); end);
	--GameEvents.GameStarted.Add(function() print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~GameEvents.GameStarted."); end);
end


function AdvSav.GetLastAutoSaveTurn()
	if(not GetData()) then return -1; end
	if(not GetData().LastSavePoint) then return -1; end
	return GetData().LastSaves[GetData().LastSavePoint];
end

function AdvSav.GetLastAutoSavePoint()	
	return GetData().LastSavePoint or nil;
end