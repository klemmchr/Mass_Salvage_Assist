
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
    if MSA_save.pos == nil then
        MSA_save.pos = { "TOP" , "TOP" , 0 , -50 }  -- Default position top of the window
    end

    if MSA_save.count_bags_Only  == nil then        -- Only applies when Salvaging
        MSA_save.count_bags_Only = true
    end

    if MSA_save.always_show == nil then
        MSA_save.always_show = true
    end
end

------------------------
---- INITIALIZATION ----
------------------------
local addon_loaded = false;
local professions_loaded = false;

-- Method:          InitializeAddon()
-- What it Does:    Initializes the variables, ensures save variablea are formatted
-- Purpose:         Proper storage data set before beginning tracking profession work
local InitializeAddon = function()
    if MSA.UI and MSA.UI.LoadUI then
        LoadSettings();
        MSA.Crafting.Establish_Spells();
        -- Don't need profession window
        MSA.UI.Deploy_Timer_UI();
        addon_loaded = true;

        if professions_loaded then
            MSA.UI.LoadUI();
            MSA.Initialization:UnregisterAllEvents();
            MSA.Initialization = nil;
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
            InitializeAddon();
        elseif addon == "Blizzard_Professions" then
            professions_loaded = true;

            if addon_loaded then
                MSA.UI.LoadUI();
                MSA.Initialization:UnregisterAllEvents();
                MSA.Initialization = nil;
            end
        end
    end
end

MSA.Initialization = CreateFrame ( "Frame" );
MSA.Initialization:RegisterEvent ( "ADDON_LOADED" );
MSA.Initialization:SetScript ( "OnEvent" , ActivateAddon );
MSA.Initialization.ProfessionsLoaded = false;