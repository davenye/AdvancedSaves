-- THIS CODE IS TERRIBLE AND BORN OF FRUSTRATION WITH CIV INITIALISATION FIASCO
-- BASIC COMMON PROGRAMMING SENSE WAS DISREGARDED AND EVERY CHANGE WAS TO BE MY LAST

include( "InstanceManager" );
include( "IconSupport" );
include( "SupportFunctions" );
include( "UniqueBonuses" );
include( "MapUtilities" );


include( "AdvSavMain" );


local g_IsDeletingFile = true;
local controlDown = false;
local lastMode = 1;
-- Global Constants
g_InstanceManager = InstanceManager:new( "SaveButton", "Button", Controls.SaveFileButtonStack );
s_maxCloudSaves = Steam.GetMaxCloudSaves();

-- Global Variables
g_SavedGames = {};			-- A list of all saved game entries.
g_SelectedEntry = nil;		-- The currently selected entry.

function GetLastAutoSaveTurn()
	--return Game.GetLastAutoSaveTurn();
	return AdvSav.GetLastAutoSaveTurn();
end
local allsavemodes = {Controls.NormalSaveMode, Controls.QueuedSaveMode,Controls.QueuedSavePostMode,Controls.ForcedSaveMode,Controls.StaleSaveMode};

local savemodes = {};

function SetSaveModes()
	if(not AdvSav) then
		
	end
	savemodes = {};
	
	for i, v in ipairs(allsavemodes) do v:SetDisabled(true); v:SetHide(true); end;
	
	if (PreGame.GameStarted()) then 
		table.insert(savemodes, allsavemodes[1]);
		--if(GetLastAutoSaveTurn() == Game.GetGameTurn()) then table.insert(savemodes, allsavemodes[1]) end;
		if(AdvSav.GetData().AllowQueueSave) then table.insert(savemodes, allsavemodes[2]) end;
		if(AdvSav.GetData().AllowQueueSave) then table.insert(savemodes, allsavemodes[3]) end;
		if(AdvSav.GetData().AllowForceSave) then table.insert(savemodes, allsavemodes[4]) end;
		if(AdvSav.GetData().AllowStaleSave and GetLastAutoSaveTurn() >= 0 and GetLastAutoSaveTurn() ~= Game.GetGameTurn()) then table.insert(savemodes, allsavemodes[5]) end;
		
		savemodes[1]:SetCheck(true);
		
		if(#savemodes == 1) then savemodes = {}; end;
			
		for i, v in ipairs(savemodes) do v:SetDisabled(false); v:SetHide(false); end;
	end	
	
end


function GetSaveMode()
	for i,v in ipairs(savemodes) do
		if(v:IsChecked()) then return i end;
	end
	return 1;
end

local function ButtonAbility()
	local bUsingSteamCloud = Controls.CloudCheck:IsChecked();
	local text = Controls.NameBox:GetText();
	
	
	if(((bUsingSteamCloud and g_SelectedEntry) or (not bUsingSteamCloud and ValidateText(text))) and CanSave()) then
		Controls.SaveButton:SetDisabled(false);
		Controls.QueueSaveButton:SetDisabled(false);
		Controls.QueueSavePostButton:SetDisabled(false);
		Controls.ForceSaveButton:SetDisabled(false);
		Controls.StaleSaveButton:SetDisabled(false);
		Controls.SaveButton:SetToolTipString( "Save normally (copies most recent autosave)" );
		Controls.QueueSaveButton:SetToolTipString( "Save with name at next autosave point" );
		Controls.QueueSavePostButton:SetToolTipString( "Save with name at next post-autosave point" );
		Controls.ForceSaveButton:SetToolTipString( "Save completely new save (not using autosaves) - WARNING: MAY NOT SAVE ALL DATA CORRECTLY!" );
		Controls.StaleSaveButton:SetToolTipString( "Save using OLD autosave file - WARNING: SAVE WILL NOT INCLUDE TURNS SINCE AUTOSAVE" );
	elseif(bUsingSteamCloud and not ValidateText(text)) then
		Controls.SaveButton:SetDisabled(true);
		Controls.QueueSaveButton:SetDisabled(true);
		Controls.QueueSavePostButton:SetDisabled(true);
		Controls.ForceSaveButton:SetDisabled(true);
		Controls.StaleSaveButton:SetDisabled(true);
	else
		if(not CanSave()) then
			Controls.SaveButton:SetDisabled(true);
			Controls.SaveButton:SetToolTipString( Locale.ConvertTextKey("No autosave this turn - normal save requires current autosave to copy when saving"));	
			Controls.QueueSaveButton:SetDisabled(false);
			Controls.QueueSavePostButton:SetDisabled(false);
			Controls.ForceSaveButton:SetDisabled(false);			
			Controls.StaleSaveButton:SetDisabled(false);			
			Controls.QueueSaveButton:SetToolTipString( "Save with name at next autosave point" );
			Controls.QueueSavePostButton:SetToolTipString( "Save with name at next post-autosave point" );
			Controls.ForceSaveButton:SetToolTipString( "Save completely new save (not using autosaves) - WARNING: MAY NOT SAVE ALL DATA CORRECTLY!" );	
			Controls.StaleSaveButton:SetToolTipString( "Save using OLD autosave file - WARNING: SAVE WILL NOT INCLUDE TURNS SINCE AUTOSAVE" );	
			
		else
			Controls.SaveButton:SetDisabled(false);
			Controls.SaveButton:SetToolTipString("Save normally (copies most recent autosave)");
			Controls.QueueSaveButton:SetDisabled(false);
			Controls.QueueSavePostButton:SetDisabled(false);
			Controls.ForceSaveButton:SetDisabled(false);			
			Controls.StaleSaveButton:SetDisabled(false);			
			Controls.QueueSaveButton:SetToolTipString( "Save with name at next autosave point" );
			Controls.QueueSavePostButton:SetToolTipString( "Save with name at next post-autosave point" );
			Controls.ForceSaveButton:SetToolTipString("Save completely new save (not using autosaves) - WARNING: MAY NOT SAVE ALL DATA CORRECTLY!" );	
			Controls.StaleSaveButton:SetToolTipString( "Save using OLD autosave file - WARNING: SAVE WILL NOT INCLUDE TURNS SINCE AUTOSAVE"  );	
			
			
		end

	end		
end

local function ShowMainButton()
	local MainButtons = {Controls.SaveButton, Controls.QueueSaveButton, Controls.QueueSavePostButton, Controls.ForceSaveButton, Controls.StaleSaveButton};
	local best = GetSaveMode();
	
	for i, e in ipairs(MainButtons) do
		if(i == best) then
			print("show " .. i);
			e:SetHide(false);
		else
			print("hide " .. i);
			e:SetHide(true);
		end
	end
	ButtonAbility();	
end

function OnSaveModeChanged()
	ShowMainButton();
	if(not g_SelectedEntry) then
		Controls.NameBox:ClearString();
		Controls.NameBox:SetText(GetDefaultSaveName());		
	end;
end
for i, v in ipairs(allsavemodes) do v:RegisterCallback( Mouse.eLClick, OnSaveModeChanged) end;

----------------------------------------------------------------        
----------------------------------------------------------------
function CanSave()
	if (not PreGame.IsMultiplayerGame() or not PreGame.GameStarted() ) then
		return true;
	end
	
	if(PreGame.GameStarted() and GetLastAutoSaveTurn() == Game.GetGameTurn()) then
		return true;
	end
	
	
	return false;	
end

----------------------------------------------------------------        
----------------------------------------------------------------
function DoSaveToFile()
	
	local savemode = GetSaveMode();
	if(savemode == 1 or savemode == 5) then UI.CopyLastAutoSave( Controls.NameBox:GetText() );
	--elseif(savemode == 2) then Game.QueueSave( Controls.NameBox:GetText(), Game.GetGameTurn() + 1 );
	elseif(savemode == 2) then AdvSav.QueueSave( false, Controls.NameBox:GetText(), controlDown, 5, Game.GetGameTurn() + 1); -- TODO (5)
		elseif(savemode == 3) then AdvSav.QueueSave( false, Controls.NameBox:GetText(), controlDown, 7, Game.GetGameTurn() + 1); -- TODO (7)
	elseif(savemode == 4) then UI.SaveGame( Controls.NameBox:GetText() ); end;
	lastMode = savemode;
end
----------------------------------------------------------------        
----------------------------------------------------------------

function DoSaveToSteamCloud(i)
	if (PreGame.IsMultiplayerGame() and PreGame.GameStarted() and not CanSave()) then
		Steam.CopyLastAutoSaveToSteamCloud( i );
	else
		Steam.SaveGameToCloud( i );
	end
	local savemode = GetSaveMode();
	if(savemode == 1 or savemode == 5) then Steam.CopyLastAutoSaveToSteamCloud( i );
	--elseif(savemode == 2) then Game.QueueSave( Controls.NameBox:GetText(), Game.GetGameTurn() + 1 );
	elseif(savemode == 2) then AdvSav.QueueSave(true, i, controlDown, 5, Game.GetGameTurn() + 1); -- TODO (5)
		elseif(savemode == 3) then AdvSav.QueueSave(true, i, controlDown, 7, Game.GetGameTurn() + 1); -- TODO (7)
	elseif(savemode == 4) then Steam.SaveGameToCloud( i ) end;
	lastMode = savemode;
end

----------------------------------------------------------------        
----------------------------------------------------------------

function OnSave()
	if(g_SelectedEntry == nil) then
		local newSave = Controls.NameBox:GetText();
		for i, v in ipairs(g_SavedGames) do
			if(v.DisplayName ~= nil and Locale.Length(v.DisplayName) > 0) then
				if(Locale.ToUpper(newSave) == Locale.ToUpper(v.DisplayName)) then
					g_SelectedEntry = v;		
				end
			end
		end
	end
	
	if(g_SelectedEntry ~= nil) then
		if(g_SelectedEntry.SaveData == nil and g_SelectedEntry.IsCloudSave) then
			for i, v in ipairs(g_SavedGames) do
				if(v == g_SelectedEntry) then
					DoSaveToSteamCloud( i );
					break;
				end
			end
		else
			g_IsDeletingFile = false;
			Controls.Message:SetText( Locale.ConvertTextKey("TXT_KEY_OVERWRITE_TXT") );
			Controls.DeleteConfirm:SetHide(false);
			return;
		end
	else
		DoSaveToFile();
	end
	
	Controls.NameBox:ClearString();
	SetupFileButtonList();
	if(not controlDown or GetSaveMode() == 2 or GetSaveMode() == 3) then
		OnBack();
	else
		UI.ExitGame();
	end
end
Controls.SaveButton:RegisterCallback( Mouse.eLClick, OnSave );
Controls.QueueSaveButton:RegisterCallback( Mouse.eLClick, OnSave );
Controls.QueueSavePostButton:RegisterCallback( Mouse.eLClick, OnSave );
Controls.ForceSaveButton:RegisterCallback( Mouse.eLClick, OnSave );
Controls.StaleSaveButton:RegisterCallback( Mouse.eLClick, OnSave );

function OnRequestAutoSaveButton()
	--Game.QueueAutoSaveTurn(Game.GetGameTurn() + 1);
	AdvSav.QueueAutoSave(5, Game.GetGameTurn() + 1); -- TODO 5, also which one? boths? this sucks.
	OnBack();
end
Controls.RequestAutoSaveButton:RegisterCallback( Mouse.eLClick, OnRequestAutoSaveButton );


function GetDefaultSaveName()
	if (PreGame.GameStarted()) then 
		local iPlayer = Game.GetActivePlayer();
		local leaderName = PreGame.GetLeaderName(iPlayer);
		local civ = PreGame.GetCivilization();
		local civInfo = GameInfo.Civilizations[civ];
		local leader = GameInfo.Leaders[GameInfo.Civilization_Leaders( "CivilizationType = '" .. civInfo.Type .. "'" )().LeaderheadType];
		
		local leaderDescription = Locale.ConvertTextKey(leader.Description);
		if leaderName ~= nil and leaderName ~= ""then
			leaderDescription = leaderName;
		end
		local savemode = GetSaveMode();
		if(savemode == 1 or savemode == 4) then
			return leaderDescription .. "_" .. Game.GetTimeString();
		elseif(savemode == 2) then
			--return leaderDescription .. "_" .. string.format("%04d", (Game.GetGameTurn() + 1));
			return leaderDescription .. "_" .. Game.GetTimeStringForYear(Game.GetGameTurn() + 1);
		elseif(savemode == 3) then
			--return leaderDescription .. "_" .. string.format("%04d", (Game.GetGameTurn() + 1));
			return leaderDescription .. "_Post_" .. Game.GetTimeStringForYear(Game.GetGameTurn() + 1);
		else
			--return leaderDescription .. "_" .. string.format("%04d", (GetLastAutoSaveTurn()));
			return leaderDescription .. "_" .. Game.GetTimeStringForYear(GetLastAutoSaveTurn());
			
		end
	else
		-- Saving before the game starts, this will just save the setup data
		return Locale.ConvertTextKey("TXT_KEY_DEFAULT_GAME_CONFIGURATION_NAME");
	end
		
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnEditBoxChange( _, _, bIsEnter )	
	local text = Controls.NameBox:GetText();
	
	if( g_SelectedEntry ~= nil ) then
		g_SelectedEntry.Instance.SelectHighlight:SetHide( true );
		local iPlayer = 0;
		if (PreGame.GameStarted()) then
			local iPlayer = Game.GetActivePlayer();
			SetSaveInfoToCiv(PreGame.GetCivilization(), PreGame.GetGameSpeed(), PreGame.GetEra(), 0, 
							 PreGame.GetHandicap(), PreGame.GetWorldSize(), PreGame.GetMapScript(), nil, 
							 PreGame.GetLeaderName(iPlayer),PreGame.GetCivilizationDescription(iPlayer), Players[iPlayer]:GetCurrentEra(), PreGame.GetGameType() );
		else
			local iPlayer = Matchmaking.GetLocalID();
			SetSaveInfoToCiv(PreGame.GetCivilization(), PreGame.GetGameSpeed(), PreGame.GetEra(), 0, 
							 PreGame.GetHandicap(), PreGame.GetWorldSize(), PreGame.GetMapScript(), nil, 
							 PreGame.GetLeaderName(iPlayer),PreGame.GetCivilizationDescription(iPlayer), PreGame.GetEra(), PreGame.GetGameType() );
		end
						 
		g_SelectedEntry = nil;
	end

	ButtonAbility();
	Controls.Delete:SetDisabled(true); 
	
	 
	 
	if( bIsEnter ) then
	    OnSave();
	end
end
Controls.NameBox:RegisterCallback( OnEditBoxChange )

----------------------------------------------------------------        
----------------------------------------------------------------
function OnDelete()
	g_IsDeletingFile = true;
	Controls.Message:SetText( Locale.ConvertTextKey("TXT_KEY_CONFIRM_TXT") );
	Controls.DeleteConfirm:SetHide(false);
	Controls.BGBlock:SetHide(true);
end
Controls.Delete:RegisterCallback( Mouse.eLClick, OnDelete );

----------------------------------------------------------------        
----------------------------------------------------------------
function OnASS()	
	UIManager:QueuePopup( Controls.AdvSavDialog, PopupPriority.SaveMapMenu );
end
Controls.ASS:RegisterCallback( Mouse.eLClick, OnASS );


----------------------------------------------------------------        
----------------------------------------------------------------
function OnYes()
	Controls.DeleteConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
	if(g_IsDeletingFile) then
		UI.DeleteSavedGame( g_SelectedEntry.FileName );
	else
		if(g_SelectedEntry.IsCloudSave) then
			for i, v in ipairs(g_SavedGames) do
				if(v == g_SelectedEntry) then
					DoSaveToSteamCloud( i );
					break;
				end
			end
		else
			DoSaveToFile();
		end
		
		-- ctrl needs to be held down even when clicking the yes. cbf fixing yet.
		if(not controlDown or GetSaveMode() == 2 or GetSaveMode() == 3) then
			OnBack();
		else
			UI.ExitGame();
		end
	end
	
	SetupFileButtonList();
	Controls.NameBox:ClearString();
	Controls.SaveButton:SetDisabled(true);
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

----------------------------------------------------------------        
----------------------------------------------------------------
function OnNo( )
	Controls.DeleteConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );
-------------------------------------------------
-------------------------------------------------
function OnBack()
	-- Test if we are modal or a popup
	if (UIManager:IsModal( ContextPtr )) then
		UIManager:PopModal( ContextPtr );
	else
		UIManager:DequeuePopup( ContextPtr );
	end
    Controls.NameBox:ClearString();
    SetSelected( nil );
end
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );
-------------------------------------------------
-------------------------------------------------
Controls.CloudCheck:RegisterCheckHandler(function(checked)

	if(checked) then
		Controls.NameBox:ClearString();
	else
		Controls.NameBox:SetText(GetDefaultSaveName());
	end
	SetSelected( nil );
	SetupFileButtonList();
end);

-------------------------------------------------
-------------------------------------------------
function SetSelected( entry )
    if( g_SelectedEntry ~= nil ) then
        g_SelectedEntry.Instance.SelectHighlight:SetHide( true );
    end
    
    g_SelectedEntry = entry;
    
    if( entry ~= nil) then
		Controls.NameBox:SetText( entry.DisplayName );
		entry.Instance.SelectHighlight:SetHide( false );
		
		if(entry.SaveData == nil and entry.FileName ~= nil and not entry.IsCloudSave) then
			entry.SaveData = PreGame.GetFileHeader(entry.FileName);
		end
		
		if(entry.SaveData ~= nil) then
			local header = entry.SaveData;
			
			local date;
			if(entry.FileName) then
				date = UI.GetSavedGameModificationTime(entry.FileName);
			end
			
			SetSaveInfoToCiv(header.PlayerCivilization, header.GameSpeed, header.StartEra, header.TurnNumber, header.Difficulty, header.WorldSize, header.MapScript, date, header.LeaderName, header.CivilizationName, header.CurrentEra, header.GameType);
			Controls.Delete:SetDisabled(false); 
		
		elseif(entry.IsCloudSave) then
			SetSaveInfoToEmptyCloudSave();
		else
			SetSaveInfoToNone();
		end
		
		--Controls.SaveButton:SetDisabled(false);  
		ButtonAbility();
			
	else -- No saves are selected
		if (PreGame.GameStarted()) then
			local iPlayer = Game.GetActivePlayer();
			SetSaveInfoToCiv(PreGame.GetCivilization(), PreGame.GetGameSpeed(), PreGame.GetEra(), Game.GetElapsedGameTurns(), 
							 PreGame.GetHandicap(), PreGame.GetWorldSize(), PreGame.GetMapScript(), nil,
							 PreGame.GetLeaderName(iPlayer), PreGame.GetCivilizationDescription(iPlayer), Players[iPlayer]:GetCurrentEra(), PreGame.GetGameType() );
		else
			local iPlayer = Matchmaking.GetLocalID();
			SetSaveInfoToCiv(PreGame.GetCivilization(), PreGame.GetGameSpeed(), PreGame.GetEra(), 0, 
							 PreGame.GetHandicap(), PreGame.GetWorldSize(), PreGame.GetMapScript(), nil,
							 PreGame.GetLeaderName(iPlayer), PreGame.GetCivilizationDescription(iPlayer), PreGame.GetEra(), PreGame.GetGameType() );
		end
		Controls.Delete:SetDisabled(true);
    end
end

-------------------------------------------------
-------------------------------------------------
function SetSaveInfoToCiv(civType, gameSpeed, era, turn, difficulty, mapSize, mapScript, date, leaderName, civName, curEra, gameType)
	
	local currentEra;
	local startEra;
		
	if(curEra ~= "") then
		currentEra = GameInfo.Eras[curEra];
	end
	
	if(era ~= "") then
		startEra = GameInfo.Eras[era];
	end
	
	if(currentEra ~= nil) then
		Controls.EraTurn:LocalizeAndSetText("TXT_KEY_CUR_ERA_TURNS_FORMAT", currentEra.Description, turn);
	else
		Controls.EraTurn:LocalizeAndSetText("TXT_KEY_CUR_ERA_TURNS_FORMAT", "TXT_KEY_MISC_UNKNOWN", turn);
	end
	
	if(startEra ~= nil) then
		Controls.StartEra:LocalizeAndSetText("TXT_KEY_START_ERA", startEra.Description);
	else
		Controls.StartEra:LocalizeAndSetText("TXT_KEY_START_ERA", "TXT_KEY_MISC_UNKNOWN");
	end
							  
	-- Set Save file time
	if(date ~= nil) then
		Controls.TimeSaved:SetText(date);	
	else
		Controls.TimeSaved:SetText("");
	end
	
	if (gameType == GameTypes.GAME_HOTSEAT_MULTIPLAYER) then
		Controls.GameType:SetText( Locale.ConvertTextKey("TXT_KEY_MULTIPLAYER_HOTSEAT_GAME") );
	else
		if (gameType == GameTypes.GAME_NETWORK_MULTIPLAYER) then
			Controls.GameType:SetText(  Locale.ConvertTextKey("TXT_KEY_MULTIPLAYER_STRING") );
		else
			if (gameType == GameTypes.GAME_SINGLE_PLAYER) then
				Controls.GameType:SetText(  Locale.ConvertTextKey("TXT_KEY_SINGLE_PLAYER") );
			else
				Controls.GameType:SetText( "" );
			end
		end
	end
	
	
	-- ? leader icon
	IconHookup( 22, 128, "LEADER_ATLAS", Controls.Portrait );
	local civDesc = Locale.ConvertTextKey("TXT_KEY_MISC_UNKNOWN");
	local leaderDescription = Locale.ConvertTextKey("TXT_KEY_MISC_UNKNOWN");
	
	-- Sets civ icon and tool tip
	local civ = GameInfo.Civilizations[civType];
	if (civ ~= nil) then
		civDesc = Locale.ConvertTextKey(civ.Description);
		local leader = GameInfo.Leaders[GameInfo.Civilization_Leaders( "CivilizationType = '" .. civ.Type .. "'" )().LeaderheadType];
		if (leader ~= nil) then		
			leaderDescription = Locale.ConvertTextKey(leader.Description);
			IconHookup( leader.PortraitIndex, 128, leader.IconAtlas, Controls.Portrait );
		end
		local textureOffset, textureAtlas = IconLookup( civ.PortraitIndex, 64, civ.IconAtlas );
		if textureOffset ~= nil then       
			Controls.CivIcon:SetTexture( textureAtlas );
			Controls.CivIcon:SetTextureOffset( textureOffset );
			Controls.CivIcon:SetToolTipString( Locale.ConvertTextKey( civ.ShortDescription) );
		end
		Controls.LargeMapImage:UnloadTexture();
		local mapTexture = civ.MapImage;
		Controls.LargeMapImage:SetTexture(mapTexture);		
	end
		
	if(leaderName ~= nil and leaderName ~= "")then
		leaderDescription = leaderName;
	end
	
	if(civName ~= nil and civName ~= "")then
		civDesc = civName;
	end
	Controls.Title:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_CIV", leaderDescription, civDesc );
	
	local mapInfo = MapUtilities.GetBasicInfo(mapScript);
	IconHookup( mapInfo.IconIndex, 64, mapInfo.IconAtlas, Controls.MapType );
	Controls.MapType:SetToolTipString(Locale.Lookup(mapInfo.Name));
	
	-- Sets map size icon and tool tip
	info = GameInfo.Worlds[ mapSize ];
	if(info ~= nil) then
		IconHookup( info.PortraitIndex, 64, info.IconAtlas, Controls.MapSize );
		Controls.MapSize:SetToolTipString( Locale.ConvertTextKey( info.Description) );
	else
		if(questionOffset ~= nil) then
			Controls.MapSize:SetTexture( questionTextureSheet );
			Controls.MapSize:SetTextureOffset( questionOffset );
			Controls.MapSize:SetToolTipString( unknownString );
		end
	end
	
	-- Sets handicap icon and tool tip
	info = GameInfo.HandicapInfos[ difficulty ];
	if(info ~= nil) then
		IconHookup( info.PortraitIndex, 64, info.IconAtlas, Controls.Handicap );
		Controls.Handicap:SetToolTipString( Locale.ConvertTextKey( info.Description ) );
	else
		if(questionOffset ~= nil) then
			Controls.Handicap:SetTexture( questionTextureSheet );
			Controls.Handicap:SetTextureOffset( questionOffset );
			Controls.Handicap:SetToolTipString( unknownString );
		end
	end
	
	-- Sets game pace icon and tool tip
	info = GameInfo.GameSpeeds[ gameSpeed ];
	if(info ~= nil) then
		IconHookup( info.PortraitIndex, 64, info.IconAtlas, Controls.SpeedIcon );
		Controls.SpeedIcon:SetToolTipString( Locale.ConvertTextKey( info.Description ) );
	else
		if(questionOffset ~= nil) then
			Controls.SpeedIcon:SetTexture( questionTextureSheet );
			Controls.SpeedIcon:SetTextureOffset( questionOffset );
			Controls.SpeedIcon:SetToolTipString( unknownString );
		end
	end
end

function SetSaveInfoToNone()
	-- Disable ability to enter game if none are selected
	Controls.SaveButton:SetDisabled(true);
	Controls.Delete:SetDisabled(true);
	
	-- Empty all text fields
	Controls.Title:SetText( "" );
	Controls.EraTurn:SetText( "" );
	Controls.TimeSaved:SetText( "" );
	Controls.StartEra:SetText( "" );
	Controls.GameType:SetText( "" );

	-- ? leader icon
	IconHookup( 22, 128, "LEADER_ATLAS", Controls.Portrait );
	
	-- Set all icons across bottom of left panel to ?
	if questionOffset ~= nil then      
		-- Civ Icon 
		Controls.CivIcon:SetTexture( questionTextureSheet );
		Controls.CivIcon:SetTextureOffset( questionOffset );
		Controls.CivIcon:SetToolTipString( unknownString );

		-- Map Type Icon 
		Controls.MapType:SetTexture( questionTextureSheet );
		Controls.MapType:SetTextureOffset( questionOffset );
		Controls.MapType:SetToolTipString( unknownString );
		-- Map Size Icon 
		Controls.MapSize:SetTexture( questionTextureSheet );
		Controls.MapSize:SetTextureOffset( questionOffset );
		Controls.MapSize:SetToolTipString( unknownString );
		-- Handicap Icon 
		Controls.Handicap:SetTexture( questionTextureSheet );
		Controls.Handicap:SetTextureOffset( questionOffset );
		Controls.Handicap:SetToolTipString( unknownString );
		-- Game Speed Icon 
		Controls.SpeedIcon:SetTexture( questionTextureSheet );
		Controls.SpeedIcon:SetTextureOffset( questionOffset );
		Controls.SpeedIcon:SetToolTipString( unknownString );
	end
    
	-- Set Selected Civ Map
	Controls.LargeMapImage:UnloadTexture();
	local mapTexture="MapRandom512.dds";
	Controls.LargeMapImage:SetTexture(mapTexture);
end

function SetSaveInfoToEmptyCloudSave()
	
	-- Empty all text fields
	Controls.Title:LocalizeAndSetText("TXT_KEY_STEAM_EMPTY_SAVE");
	Controls.EraTurn:SetText("");
	Controls.TimeSaved:SetText("");
	Controls.StartEra:SetText( "" );
	Controls.GameType:SetText("");

	-- ? leader icon
	IconHookup( 22, 128, "LEADER_ATLAS", Controls.Portrait );
	
	-- Set all icons across bottom of left panel to ?
	if questionOffset ~= nil then      
		-- Civ Icon 
		Controls.CivIcon:SetTexture( questionTextureSheet );
		Controls.CivIcon:SetTextureOffset( questionOffset );
		Controls.CivIcon:SetToolTipString( unknownString );

		-- Map Type Icon 
		Controls.MapType:SetTexture( questionTextureSheet );
		Controls.MapType:SetTextureOffset( questionOffset );
		Controls.MapType:SetToolTipString( unknownString );
		-- Map Size Icon 
		Controls.MapSize:SetTexture( questionTextureSheet );
		Controls.MapSize:SetTextureOffset( questionOffset );
		Controls.MapSize:SetToolTipString( unknownString );
		-- Handicap Icon 
		Controls.Handicap:SetTexture( questionTextureSheet );
		Controls.Handicap:SetTextureOffset( questionOffset );
		Controls.Handicap:SetToolTipString( unknownString );
		-- Game Speed Icon 
		Controls.SpeedIcon:SetTexture( questionTextureSheet );
		Controls.SpeedIcon:SetTextureOffset( questionOffset );
		Controls.SpeedIcon:SetToolTipString( unknownString );
	end
    
	-- Set Selected Civ Map
	Controls.LargeMapImage:UnloadTexture();
	local mapTexture="MapRandom512.dds";
	Controls.LargeMapImage:SetTexture(mapTexture);
end
----------------------------------------------------------------        
----------------------------------------------------------------
function ChopFileName(file)
	_, _, chop = string.find(file,"\\.+\\(.+)%."); 
	return chop;
end

----------------------------------------------------------------        
----------------------------------------------------------------
function ValidateText(text)
	local isAllWhiteSpace = true;
	for i = 1, #text, 1 do
		if (string.byte(text, i) ~= 32) then
			isAllWhiteSpace = false;
			break;
		end
	end
	
	if (isAllWhiteSpace) then
		return false;
	end

	-- don't allow % character
	for i = 1, #text, 1 do
		if string.byte(text, i) == 37 then
			return false;
		end
	end

	local invalidCharArray = { '\"', '<', '>', '|', '\b', '\0', '\t', '\n', '/', '\\', '*', '?', ':' };

	for i, ch in ipairs(invalidCharArray) do
		if (string.find(text, ch) ~= nil) then
			return false;
		end
	end

	-- don't allow control characters
	for i = 1, #text, 1 do
		if (string.byte(text, i) < 32) then
			return false;
		end
	end

	return true;
end

----------------------------------------------------------------        
----------------------------------------------------------------
function SetupFileButtonList()
	SetSelected( nil );
    g_InstanceManager:ResetInstances();
    
    SetSaveInfoToNone();
    
    local bUsingSteamCloud = Controls.CloudCheck:IsChecked();
    
    if(bUsingSteamCloud) then
		local cloudSaveData = Steam.GetCloudSaves();
		
		local sortTable = {};
		
		for i = 1, s_maxCloudSaves, 1 do
			
			local instance = g_InstanceManager:GetInstance();
			local data = cloudSaveData[i];
			
			g_SavedGames[i] = {
				Instance = instance,
				SaveData = data,
				IsCloudSave = true,
			}
			
			local title = Locale.ConvertTextKey("TXT_KEY_STEAM_EMPTY_SAVE");
			if(data ~= nil) then
			
				local civName = Locale.ConvertTextKey("TXT_KEY_MISC_UNKNOWN");
				local leaderDescription = Locale.ConvertTextKey("TXT_KEY_MISC_UNKNOWN");
				
				local civ = GameInfo.Civilizations[ data.PlayerCivilization ];
				if(civ ~= nil) then
					local leader = GameInfo.Leaders[GameInfo.Civilization_Leaders( "CivilizationType = '" .. civ.Type .. "'" )().LeaderheadType];
					leaderDescription = Locale.Lookup(leader.Description);
					civName = Locale.Lookup(civ.Description);
				end

				if(not Locale.IsNilOrWhitespace(data.CivilizationName)) then
					civName = data.CivilizationName;
				end
				
				if(not Locale.IsNilOrWhitespace(data.LeaderName)) then
					leaderDescription = data.LeaderName;
				end
				
				title = Locale.Lookup("TXT_KEY_RANDOM_LEADER_CIV", leaderDescription, civName );
			end
			
			instance.ButtonText:LocalizeAndSetText("TXT_KEY_STEAMCLOUD_SAVE", i, title);
			instance.Button:RegisterCallback( Mouse.eLClick, function() SetSelected(g_SavedGames[i]); end);
		end
    else
        -- build a table of all save file names that we found
        local savedGames = {};
        local gameType = GameTypes.GAME_SINGLE_PLAYER;
        if (PreGame.IsMultiplayerGame()) then
			gameType = GameTypes.GAME_NETWORK_MULTIPLAYER;
        elseif (PreGame.IsHotSeatGame()) then
			gameType = GameTypes.GAME_HOTSEAT_MULTIPLAYER;
        end
		UI.SaveFileList( savedGames, gameType, false, true);
	   
		for i, v in ipairs(savedGames) do
    		local instance = g_InstanceManager:GetInstance();
    		
    		-- chop the part that we are going to display out of the bigger string
			local displayName = Path.GetFileNameWithoutExtension(v);
						
			g_SavedGames[i] = {
				Instance = instance,
				FileName = v,
				DisplayName = displayName,
			}
	    	
			TruncateString(instance.ButtonText, instance.Button:GetSizeX(), displayName); 
			
			instance.Button:SetVoid1( i );
			instance.Button:RegisterCallback( Mouse.eLClick, function() SetSelected(g_SavedGames[i]); end);
		end
    end
    
	Controls.Delete:SetHide(bUsingSteamCloud);
	Controls.NameBoxFrame:SetHide(bUsingSteamCloud);
	
	Controls.SaveFileButtonStack:CalculateSize();
    Controls.SaveFileButtonStack:ReprocessAnchoring();
    Controls.ScrollPanel:CalculateInternalSize();
end

----------------------------------------------------------------        
---------------------------------------------------------------- 

----------------------------------------------------------------        
---------------------------------------------------------------- 
function OnSaveMap()
    UIManager:QueuePopup( Controls.SaveMapMenu, PopupPriority.SaveMapMenu );
end
Controls.SaveMapButton:RegisterCallback( Mouse.eLClick, OnSaveMap );



----------------------------------------------------------------        
-- Key Down Processing
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_ESCAPE then
			if(Controls.DeleteConfirm:IsHidden() and Controls.AdvSavDialog:IsHidden())then
				OnBack();
			else
				if(not Controls.AdvSavDialog:IsHidden()) then				
					Controls.AdvSavDialog:SetHide(true);
					Controls.BGBlock:SetHide(false);
				end
				if(not Controls.DeleteConfirm:IsHidden()) then				
					Controls.DeleteConfirm:SetHide(true);
					Controls.BGBlock:SetHide(false);
				end
			end
		end		
	end
	if(uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_CONTROL and AdvSav.GetData().AllowSaveAndQuit) then    	
		controlDown = true;    	
		Controls.DangerBox:SetHide( false );
		Controls.DangerLabel:SetHide( false );
		
	elseif(uiMsg == KeyEvents.KeyUp and wParam == Keys.VK_CONTROL) then
		controlDown = false;
		Controls.DangerBox:SetHide( true );
		Controls.DangerLabel:SetHide( true );
	end
	
	return true;
end
ContextPtr:SetInputHandler( InputHandler );


----------------------------------------------------------------        
----------------------------------------------------------------
function ShowHideHandler( isHide )		
		if(AdvSav) then			
			if(not AdvSav.Hookup) then return; end;
			AdvSav.Hookup();
		end
		
    if( not isHide ) then
    	
    	SetSaveModes();

			
			
    	-- don't want to encourage potentially corrupting operations!		
    	--Controls.ForceFreshMPSave:SetCheck(false);
			Controls.SaveButton:SetDisabled(not CanSave());
    	if (PreGame.GameStarted()) then    	
    		--Controls.ForceFreshMPSave:SetHide(not PreGame.IsMultiplayerGame());
    		--Controls.ForceFreshMPSave:SetHide(false);
	    	-- If the lock mods option is on then disable the save map button    		    		    	
    		if( PreGame.IsMultiplayerGame() or
    			Modding.AnyActivatedModsContainPropertyValue( "DisableSaveMapOption", "1" ) or
        		PreGame.GetGameOption( GameOptionTypes.GAMEOPTION_LOCK_MODS ) ~= 0 or
        		UIManager:IsModal( ContextPtr ) ) then
        		Controls.SaveMapButton:SetHide( true );
        		Controls.RequestAutoSaveButton:SetHide( false );
        		
        			if(not AdvSav.GetLastAutoSavePoint()) then
        		  	Controls.LastAutosaveTypeLabel:SetText("Last AutoSave Type: Unknown");
        		  elseif(AdvSav.GetLastAutoSavePoint() == 5) then
    						Controls.LastAutosaveTypeLabel:SetText("Last AutoSave Type: Normal");
        		  elseif(AdvSav.GetLastAutoSavePoint() == 7) then
        		  	Controls.LastAutosaveTypeLabel:SetText("Last AutoSave Type: Post");
        		  elseif(AdvSav.GetLastAutoSavePoint() == 3) then
        		  	Controls.LastAutosaveTypeLabel:SetText("Last AutoSave Type: Initial");
        			else
        				Controls.LastAutosaveTypeLabel:SetText("Last AutoSave Type: Unknown");
        			end
        			
				    	if(GetLastAutoSaveTurn() >= 0) then
				    		if(GetLastAutoSaveTurn() == Game.GetGameTurn()) then
				    			Controls.LastAutosaveTurnLabel:SetText("Last AutoSave Turn: " .. GetLastAutoSaveTurn() .. " (current turn)");
				    		elseif(GetLastAutoSaveTurn() == Game.GetGameTurn() - 1) then
				    			Controls.LastAutosaveTurnLabel:SetText("Last AutoSave Turn: " .. GetLastAutoSaveTurn() .. " [COLOR_FONT_RED](1 turn ago)");
				    		else
				    			Controls.LastAutosaveTurnLabel:SetText("Last AutoSave Turn: " .. GetLastAutoSaveTurn() .. " [COLOR_FONT_RED](" ..(Game.GetGameTurn() - GetLastAutoSaveTurn()) .. " turns ago)");
				    		end
				    	else 
								Controls.LastAutosaveTurnLabel:SetText("Last AutoSave Turn: Unknown");
							end
				   	
				    	
				    	Controls.RequestAutoSaveButton:SetHide(not AdvSav.GetData().AllowAutoSaveRequests);
				    	Controls.AutoSaveDetails:SetHide(not AdvSav.GetData().ShowLastAutoSaveDetails);
				
				    	--Controls.ForceSaveButtonLabel:SetText("[COLOR_FONT_RED]Force [COLOR_WHITE]" .. Locale.ConvertTextKey("TXT_KEY_MENU_SAVE"));
				    	--Controls.QueueSaveButtonLabel:SetText("[COLOR_FONT_GREEN]Queue [COLOR_WHITE]" .. Locale.ConvertTextKey"(TXT_KEY_MENU_SAVE"));
				    	Controls.ForceSaveButtonLabel:SetText("[COLOR_FONT_RED]Force [COLOR_WHITE]" .. Locale.ConvertTextKey("TXT_KEY_MENU_SAVE") .. " [ICON_HAPPINESS_4]");
				    	Controls.QueueSaveButtonLabel:SetText("[COLOR_FONT_GREEN]Queue [COLOR_WHITE]" .. Locale.ConvertTextKey("TXT_KEY_MENU_SAVE"));
				    	Controls.QueueSavePostButtonLabel:SetText("[COLOR_FONT_GREEN]Queue [COLOR_WHITE]" .. Locale.ConvertTextKey("TXT_KEY_MENU_SAVE") .. " [COLOR_ADVISOR_HIGHLIGHT_TEXT](Post)");
				    	Controls.StaleSaveButtonLabel:SetText("[COLOR_MAGENTA]Stale [COLOR_WHITE]" .. Locale.ConvertTextKey("TXT_KEY_MENU_SAVE").. " [ICON_HAPPINESS_3]");
				

    		else
        		Controls.SaveMapButton:SetHide( false );
        		for i, v in ipairs(allsavemodes) do v:SetHide(true); end;
        		Controls.RequestAutoSaveButton:SetHide(true);        		
    		end
			else
				-- Saving before the game starts, this will just save the setup data
      	Controls.SaveMapButton:SetHide( true );
      	Controls.RequestAutoSaveButton:SetHide( true );
  	    for i, v in ipairs(allsavemodes) do v:SetHide(true); end;
    		Controls.RequestAutoSaveButton:SetHide(true);
    		Controls.RequestAutoSaveButton:SetHide( true );
    	end
			
			Controls.NameBox:SetText(GetDefaultSaveName());
      Controls.NameBox:TakeFocus();
			SetupFileButtonList();
			OnEditBoxChange();
			OnSaveModeChanged()
			ButtonAbility();
			if(PreGame.GameStarted() and AdvSav.IsActive()) then
				Controls.ASS:SetHide(false);
			else
				----------------------------------------------------------------------------------------------Controls.ASS:SetHide(true);
				Controls.ASS:SetHide(true);
				Controls.AutoSaveDetails:SetHide(true);
			end
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );
