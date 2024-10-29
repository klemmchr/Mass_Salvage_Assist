
-- Author: Aaron Topping (The Genome Whisperer)

MCA = {}                         -- Global Addon List to Hold all functions
MCA_save = MCA_save or {}     -- Save Variable0

local ADDON_NAME = "Mass_Crafting_Assist"

----------------
--- SETTINGS ---
----------------

-- Method:          LoadSettings( bool )
-- What it Does:    What it WILL do is load the settings frame in the Built-In Interface
-- Purpose:         Useful configurations eventually.
local LoadSettings = function( reset_settings )
    if reset_settings then
        MCA_save = {}
    end

    if MCA_save.non_stop == nil then
        MCA_save.non_stop = true
    end
end

------------------------
---- INITIALIZATION ----
------------------------

-- Method:          InitializeAddon()
-- What it Does:    Initializes the variables, ensures save variablea are formatted and session tables
-- Purpose:         Proper storage data set before beginning tracking card looting.
local InitializeAddon = function()
    if MCA.UI and MCA.UI.LoadUI then
        LoadSettings();

        if ProfessionsFrame then        -- In the case another addon has already pre-loaded the professions frame, this will force UI to load too.
            MCA.UI.LoadUI();
            MCA.Initialization:UnregisterAllEvents();
            MCA.Initialization = nil;
        else
            MCA.Initialization:UnregisterEvent("PLAYER_ENTERING_WORLD");
        end

    else
        C_Timer.After ( 1 , MCA.InitializeAddon)
    end
end

-- Method:          ActivateAddon ( ... , string , string )
-- What it Does:"   Controls load order of addon to ensure it doesn't initialize until player has fully logged into the world
-- Purpose:         Some things don't needto load until player is entering the world.
local ActivateAddon = function ( _ , event , addon )
    if event == "ADDON_LOADED" then
    -- initiate addon once all variable are loaded.
        if addon == ADDON_NAME then
            MCA.Initialization:RegisterEvent ( "PLAYER_ENTERING_WORLD" ); -- Ensures this check does not occur until after Addon is fully loaded. By registering, it acts recursively throug hthis method
        elseif addon == "Blizzard_Professions" then
            MCA.UI.LoadUI();
            MCA.Initialization:UnregisterAllEvents();
            MCA.Initialization = nil;
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeAddon();
    end
end

MCA.Initialization = CreateFrame ( "Frame" );
MCA.Initialization:RegisterEvent ( "ADDON_LOADED" );
MCA.Initialization:SetScript ( "OnEvent" , ActivateAddon );