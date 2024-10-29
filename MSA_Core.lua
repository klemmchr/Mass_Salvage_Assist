
-- Author: Aaron Topping (The Genome Whisperer)

MSA = {}                        -- Global Addon List to Hold all functions
MSA_save = MSA_save or {}       -- Account-wide Save Variable

local ADDON_NAME = "Mass_Salvage_Assist"

----------------
--- SETTINGS ---
----------------

-- Method:          LoadSettings( bool )
-- What it Does:    What it WILL do is load the settings frame in the Built-In Interface
-- Purpose:         Useful configurations eventually.
local LoadSettings = function( reset_settings )
    if reset_settings then
        MSA_save = {}
    end

    if MSA_save.non_stop == nil then
        MSA_save.non_stop = true
    end
end

------------------------
---- INITIALIZATION ----
------------------------

-- Method:          InitializeAddon()
-- What it Does:    Initializes the variables, ensures save variablea are formatted
-- Purpose:         Proper storage data set before beginning tracking profession work
local InitializeAddon = function()
    if MSA.UI and MSA.UI.LoadUI then
        LoadSettings();
        if ProfessionsFrame then        -- In the case another addon has already pre-loaded the professions frame, this will force UI to load too.
            MSA.UI.LoadUI();
            MSA.Initialization:UnregisterAllEvents();
            MSA.Initialization = nil;
        else
            MSA.Initialization:UnregisterEvent("PLAYER_ENTERING_WORLD");
        end

    else
        C_Timer.After ( 1 , MSA.InitializeAddon)
    end
end

-- Method:          ActivateAddon ( ... , string , string )
-- What it Does:"   Controls load order of addon to ensure it doesn't initialize until player has fully logged into the world
-- Purpose:         Some things don't need to load until player is entering the world.
local ActivateAddon = function ( _ , event , addon )
    if event == "ADDON_LOADED" then
    -- initiate addon once all variable are loaded.
        if addon == ADDON_NAME then
            MSA.Initialization:RegisterEvent ( "PLAYER_ENTERING_WORLD" ); -- Ensures this check does not occur until after Addon is fully loaded. By registering, it acts recursively throug hthis method
        elseif addon == "Blizzard_Professions" then
            MSA.UI.LoadUI();
            MSA.Initialization:UnregisterAllEvents();
            MSA.Initialization = nil;
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeAddon();
    end
end

MSA.Initialization = CreateFrame ( "Frame" );
MSA.Initialization:RegisterEvent ( "ADDON_LOADED" );
MSA.Initialization:SetScript ( "OnEvent" , ActivateAddon );