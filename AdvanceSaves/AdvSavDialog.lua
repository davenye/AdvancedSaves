-- THIS CODE IS TERRIBLE AND BORN OF FRUSTRATION WITH CIV INITIALISATION FIASCO
-- BASIC COMMON PROGRAMMING SENSE WAS DISREGARDED AND EVERY CHANGE WAS TO BE MY LAST

include( "InstanceManager" );
include( "IconSupport" );
include( "SupportFunctions" );
include( "UniqueBonuses" );
include( "MapUtilities" );
include( "AdvSav" );

local ModeConfigInstances = {};
local Data = {};

local CatToNum = {};
local CatToLine = {};


----------------------------------------------------------------        
-- Key Down Processing
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE then
					OnBack();
				end
		end	
    return true;
end
ContextPtr:SetInputHandler( InputHandler );

------------------------------------------------------------------

function OnBack()
	-- Test if we are modal or a popup
	if (UIManager:IsModal( ContextPtr )) then
		UIManager:PopModal( ContextPtr );
	else
		UIManager:DequeuePopup( ContextPtr );
	end
	Data = AdvSav.CopyData(); 
	ChangeAll();
end
Controls.CancelButton:RegisterCallback( Mouse.eLClick, OnBack );


------------------------------------------------------------------

function OnDefaults()
	  InitData();
		ChangeAll();
end
Controls.DefaultsButton:RegisterCallback( Mouse.eLClick, OnDefaults );


------------------------------------------------------------------

function OnAccept()
		UpdateData();
	 StoreData();
	 OnBack();
end
Controls.AcceptButton:RegisterCallback( Mouse.eLClick, OnAccept );

------------------------------------------------------------------
local hasInit = false;
function ShowHideHandler( isHide, isInit )
	if(false and isInit) then		
		Data = AdvSav.CopyData();
		CreateConfigControls();
		ChangeAll();
		hasInit = true;		
	end
	
	if( not isHide ) then
		if(not hasInit) then					
			 Data = AdvSav.CopyData();
			 
			CreateConfigControls();
			ChangeAll();
			hasInit = true;
		end    
    Data = AdvSav.CopyData();
		ChangeAll();
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler);


------------------------------------------------------------------

local SaveModeOptions = 
{

	{
		label = "Turn Interval",
		tooltip = "Save a new autosave after a certain number of turns since the last one",
		needs_edit = true
	},
	{
		label = "Request Only",
		tooltip = "ask nicely",
		needs_edit = false
	},
	{
		label = "Never",
		tooltip = "Not saved.",
		needs_edit = false
	}
};

local SaveModeConfigs = 
{
		{
			txt = "Pitboss Host",
			tooltip = "When running as the Pitboss server",
			cat_id = 0,
			pointset = 2,
		},
		{
			txt = "MP Host",
			tooltip = "When playing as the multiplayer host",
			cat_id = 1,
			pointset = 2,
		},
		{
			txt = "MP Guest",
			tooltip = "When playing a multiplayer game as player who is not hosting",
			cat_id = 2,
			pointset = 2,
		},
		{
			txt = "MP Observer",
			tooltip = "When observing a multiplayer game and not hosting",
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


function CreateConfigControls()
	local idx = 1;
	for i,v in ipairs(SaveModeConfigs) do
		local lineinstance = {};
		ContextPtr:BuildInstanceForControl( "SavePointConfigLine", lineinstance, Controls.ConfigLines);
		lineinstance.WhenTypeo:LocalizeAndSetText( v.txt);
		lineinstance.WhenTypeo:SetToolTipString( v.tooltip);

		CatToLine[v.cat_id] = lineinstance;
		CatToNum[v.cat_id] = i;
		for saveid = 1, 2 do
			
			local instance = {};
			local post = saveid == 2;
			
	
		ContextPtr:BuildInstanceForControl( "SavePointConfig", instance, lineinstance.ConfigsLine);
	
				local control = instance.SaveMode;
				for m = 1, 3 do
					if(m ~= 2) then
						local controlTable = {};
						
				    control:BuildEntry("InstanceOne", controlTable);
				    controlTable.Button:LocalizeAndSetText( SaveModeOptions[m].label );
				    controlTable.Button:SetToolTipString( Locale.ConvertTextKey(SaveModeOptions[m].tooltip));
				    controlTable.Button:SetVoids( m , idx);
				   end

			  end
			  control:RegisterSelectionCallback(OnModeSelected);
			  instance.IntervalEdit:SetVoid1(idx);
			  local dontwantclosure = idx;
			  instance.IntervalEdit:RegisterCallback( function(s) OnIntervalChanged(s, dontwantclosure) end);
			  control:CalculateInternals();
    		
			ModeConfigInstances[idx] = instance;
			idx = idx + 1;
		end
	end
end

function InitData()
	local idx = 0; 
	
	
	Data.AllowQueueSave = false;
	Data.AllowForceSave = false;
	Data.AllowStaleSave  = false;
	Data.AllowAutoSaveRequests = false;
	Data.ShowLastAutoSaveDetails = false;
	Data.QueuedSavePopup = false;
	
	Data.AllowSaveAndQuit	 = false;
	Data.NoHumansNoPosts		 = false;
	Data.OnlyHumansNoPosts	   = false;
	Data.DisplayAutosaveMessages   = false;
	Data.MinTurnNormal = 0;
	Data.MinTurnPost = 0;
	
	for i,cat in ipairs(SaveModeConfigs) do
		for j,point in ipairs(PointSets[cat.pointset]) do
			idx = idx + 1;
			local default = 1;
			if(j == 2) then
				default = -1;
			end
			Data.Filters[idx] = {cat.cat_id, point, default}; -- default to every turn
		end
	end
end




function ChangeAll()
	
	Controls.AllowQueueSave:SetCheck(Data.AllowQueueSave);
	Controls.AllowForceSave:SetCheck(Data.AllowForceSave);
	Controls.AllowStaleSave:SetCheck(Data.AllowStaleSave);
	Controls.QueuedSavePopup:SetCheck(Data.QueuedSavePopup);
	Controls.AllowAutoSaveRequests:SetCheck(Data.AllowAutoSaveRequests);
	Controls.ShowLastAutoSaveDetails:SetCheck(Data.ShowLastAutoSaveDetails);
	
	Controls.AllowSaveAndQuit:SetCheck(Data.AllowSaveAndQuit);
	Controls.NoHumansNoPosts:SetCheck(Data.NoHumansNoPosts);
	Controls.OnlyHumansNoPosts:SetCheck(Data.OnlyHumansNoPosts);
	Controls.DisplayAutosaveMessages:SetCheck(Data.DisplayAutosaveMessages);
	
	Controls.MinTurnNormal:SetText(Data.MinTurnNormal);
	Controls.MinTurnPost:SetText(Data.MinTurnPost);

	
	
	for i,conf in ipairs(Data.Filters) do
		OnDataChange(i, conf[3]);		
	end
end

function StoreData()
	
	AdvSav.StoreData();
end

function UpdateData()
	AdvSav.UpdateData(Data);
end

function ApplyData() 
	for i,conf in ipairs(Data.Filters) do
		
	end
end

function OnDataChange(i, v)
	local cfg = ModeConfigInstances[i];
	
	local pd = -1;
	
	if(v ==nil) then								
		pd = 1;		
	elseif(v < 0) then		
		pd = 3;		
	elseif(v == 0) then	
			pd = 2;
	elseif(v > 0) then				
		cfg.IntervalEdit:SetText(v);		
		pd = 1;
		
	end
	
	if(pd == 1) then
		cfg.IntervalBox:SetHide(false);
		cfg.IntervalEdit:SetHide(false);
	else
		cfg.IntervalBox:SetHide(true);
		cfg.IntervalEdit:SetHide(true);
	end
		
	cfg.SaveMode:GetButton():SetText(Locale.ConvertTextKey(SaveModeOptions[pd].label));
	cfg.SaveMode:GetButton():SetToolTipString( Locale.ConvertTextKey(SaveModeOptions[pd].tooltip));
end

function ChangeData(i, v)
	Data.Filters[i][3] = v;
	OnDataChange(i, v);
end


function OnModeSelected(i, g)
	local cfg = ModeConfigInstances[g];
	if(i == 3) then		
		ChangeData(g, -1);
	elseif(i == 2) then
		ChangeData(g, 0);
	elseif(i == 1) then		
		--ChangeData(g, nil);
		local v = tonumber(cfg.IntervalEdit:GetText());
		if (not v or v <= 0) then v = 1 end;
		ChangeData(g,  v);		
	end
	 
end


function OnIntervalChanged( s, g )
		local i = tonumber(s);
		ChangeData(g, i);
end


function GetCurrentCat()
	return AdvSav.GetCurrentCat();
end

local lastcat = -1;
function DoUpdate() 
	local thislast = GetCurrentCat();	
	if(lastcat ~= thislast) then
		if(lastcat ~= -1) then
			CatToLine[lastcat].WhenTypeo:SetColorByName("Beige_Black");
			CatToLine[lastcat].WhenTypeo:SetToolTipString( SaveModeConfigs[CatToNum[lastcat]].tooltip);
		end
		CatToLine[thislast].WhenTypeo:SetColorByName("Green_Black");
		
		CatToLine[thislast].WhenTypeo:SetToolTipString(SaveModeConfigs[CatToNum[thislast]].tooltip .. "[NEWLINE][COLOR_FONT_GREEN](Current)[END_COLOR]");
		local x0 = 45;
		local x1 = 825;
		local y = 280 + (CatToNum[thislast] - 1) * 42;
		
		Controls.ActiveHighlight:SetStartVal(x0, y);
		Controls.ActiveHighlight:SetEndVal(x1, y);
		lastcat = thislast;
	end	
end

local lastlast = -2;


function OpenDialog()
	UIManager:QueuePopup( ContextPtr, PopupPriority.SaveMapMenu );
end

dropdownentry = { text = "-1", call = OpenDialog};

ContextPtr:SetUpdate( function(deltaTime)
	if(not hasInit) then
		return;
	end
	local thislast = AdvSav.GetLastAutoSaveTurn();
	if(lastlast ~= thislast) then
			DoUpdate();
			lastlast = thislast;
	end
end);






--[[
-- Was getting CTDs until I commented out this. Mahy have been a coincidence but I was over it by then.
function AddDropdownEntry(additionalEntries)
	-- Add new dialog entry to the additional information dropdown list.	
	local str = "";
	if(AdvSav.GetLastAutoSaveTurn() < 0) then
		--str = "[COLOR_NEGATIVE_TEXT]-1 (Unknown number of turns turn since last autosave)";
		str = "00";
	elseif(AdvSav.GetLastAutoSaveTurn() == 0) then
		--str = "[COLOR_POSITIVE_TEXT]0 (autosaved this turn)";
		str = "0";
	elseif(AdvSav.GetLastAutoSaveTurn() > 0) then
		--str = tostring(Game.GetGameTurn() - AdvSav.GetLastAutoSaveTurn()) .. " turn(s) since last autosave";
		str = tostring(Game.GetGameTurn() - AdvSav.GetLastAutoSaveTurn());
	end
	table.insert(additionalEntries, { text = str, call = OpenDialog});
end
--]]

function AddDropdownEntry(additionalEntries)
	table.insert(additionalEntries, { text = "#", call = OpenDialog});
end

if(MapModData) then
	if(not MapModData.AdvSavDialog) then 
		MapModData.AdvSavDialog = {};
	
		LuaEvents.AdditionalInformationDropdownGatherEntries.Add(AddDropdownEntry);
		LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();
	--[[
		GameEvents.AutoSaved.Add(function ( eSavePoint, saved) 
			if (saved) then LuaEvents.RequestRefreshAdditionalInformationDropdownEntries(); end;
		end);
			
		Events.ActivePlayerTurnStart.Add(function ( ) 
			LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();
			end);
			--]]
	end
	
end



function AllowAutoSaveRequestsCheckHandler(checked) Data.AllowAutoSaveRequests = checked;	end
Controls.AllowAutoSaveRequests:RegisterCheckHandler(AllowAutoSaveRequestsCheckHandler);

function AllowQueueSaveCheckHandler(checked) Data.AllowQueueSave = checked;	end
Controls.AllowQueueSave:RegisterCheckHandler(AllowQueueSaveCheckHandler);

function AllowForceSaveCheckHandler(checked) Data.AllowForceSave = checked;	end
Controls.AllowForceSave:RegisterCheckHandler(AllowForceSaveCheckHandler);

function AllowStaleSaveCheckHandler(checked) Data.AllowStaleSave = checked;	end
Controls.AllowStaleSave:RegisterCheckHandler(AllowStaleSaveCheckHandler);

function QueuedSavePopupCheckHandler(checked) Data.QueuedSavePopup = checked;	end	
Controls.QueuedSavePopup:RegisterCheckHandler(QueuedSavePopupCheckHandler);


function ShowLastAutoSaveDetailsCheckHandler(checked) Data.ShowLastAutoSaveDetails = checked;	end
Controls.ShowLastAutoSaveDetails:RegisterCheckHandler(ShowLastAutoSaveDetailsCheckHandler);

function AllowSaveAndQuitCheckHandler(checked) Data.AllowSaveAndQuit = checked;	end
Controls.AllowSaveAndQuit:RegisterCheckHandler(AllowSaveAndQuitCheckHandler);

function NoHumansNoPostsCheckHandler(checked) Data.NoHumansNoPosts = checked;	end
Controls.NoHumansNoPosts:RegisterCheckHandler(NoHumansNoPostsCheckHandler);

function OnlyHumansNoPostsCheckHandler(checked) Data.OnlyHumansNoPosts = checked;	end
Controls.OnlyHumansNoPosts:RegisterCheckHandler(OnlyHumansNoPostsCheckHandler);

function DisplayAutosaveMessagesCheckHandler(checked) Data.DisplayAutosaveMessages = checked;	end
Controls.DisplayAutosaveMessages:RegisterCheckHandler(DisplayAutosaveMessagesCheckHandler);

function MinTurnNormalChangeHandler(edit) Data.MinTurnNormal = tonumber(edit);	end
Controls.MinTurnNormal:RegisterCallback(MinTurnNormalChangeHandler);

function MinTurnPostChangeHandler(edit) Data.MinTurnPost = tonumber(edit);	end
Controls.MinTurnPost:RegisterCallback(MinTurnPostChangeHandler);
		
	  