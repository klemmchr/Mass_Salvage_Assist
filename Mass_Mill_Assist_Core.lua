
-- Author: Aaron Topping (The Genome Whisperer)

MassMA = {}                         -- Global Addon List to Hold all functions
MassMA_save = MassMA_save or {}     -- Save Variable0

local ADDON_NAME = "Mass_Mill_Assist"

----------------
--- SETTINGS ---
----------------

-- Method:          LoadSettings( bool )
-- What it Does:    What it WILL do is load the settings frame in the Built-In Interface
-- Purpose:         Useful configurations eventually.
local LoadSettings = function( reset_settings )
    if reset_settings then
        MassMA_save = {}
    end

    if MassMA_save.non_stop == nil then
        MassMA_save.non_stop = true
    end
end

------------------------
---- INITIALIZATION ----
------------------------

-- Method:          InitializeAddon()
-- What it Does:    Initializes the variables, ensures save variablea are formatted and session tables
-- Purpose:         Proper storage data set before beginning tracking card looting.
local InitializeAddon = function()
    if MassMA.UI and MassMA.UI.LoadUI then
        LoadSettings();

        if ProfessionsFrame then        -- In the case another addon has already pre-loaded the professions frame, this will force UI to load too.
            MassMA.UI.LoadUI();
            MassMA.Initialization:UnregisterAllEvents();
            MassMA.Initialization = nil;
        else
            MassMA.Initialization:UnregisterEvent("PLAYER_ENTERING_WORLD");
        end

    else
        C_Timer.After ( 1 , MassMA.InitializeAddon)
    end
end

-- Method:          ActivateAddon ( ... , string , string )
-- What it Does:"   Controls load order of addon to ensure it doesn't initialize until player has fully logged into the world
-- Purpose:         Some things don't needto load until player is entering the world.
local ActivateAddon = function ( _ , event , addon )
    if event == "ADDON_LOADED" then
    -- initiate addon once all variable are loaded.
        if addon == ADDON_NAME then
            MassMA.Initialization:RegisterEvent ( "PLAYER_ENTERING_WORLD" ); -- Ensures this check does not occur until after Addon is fully loaded. By registering, it acts recursively throug hthis method
        elseif addon == "Blizzard_Professions" then
            MassMA.UI.LoadUI();
            MassMA.Initialization:UnregisterAllEvents();
            MassMA.Initialization = nil;
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeAddon();
    end
end

MassMA.Initialization = CreateFrame ( "Frame" );
MassMA.Initialization:RegisterEvent ( "ADDON_LOADED" );
MassMA.Initialization:SetScript ( "OnEvent" , ActivateAddon );