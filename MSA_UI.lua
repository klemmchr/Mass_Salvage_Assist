-- For the UI Frames of Mass Salvage Assist adddon

local UI = {};
MSA.UI = UI;

-- Holds GUI frame load configuration details
UI.LoadUI = function()

    if not MSA.Crafting.Profs then
        MSA.Crafting.Establish_Spells()
    end

    -- Checkbox to be placed on inscription window
    if not UI.MSA_checkbox then

        UI.MSA_checkbox = CreateFrame ( "CheckButton" , "MSA_checkbox" , ProfessionsFrame.CraftingPage , "InterfaceOptionsCheckButtonTemplate" )
        UI.MSA_checkbox.value = MSA_save.non_stop
        UI.MSA_checkbox:SetChecked ( UI.MSA_checkbox.value )

        -- Text to the right of checkbox
        UI.MSA_checkbox.Text = UI.MSA_checkbox:CreateFontString ( nil , "OVERLAY" , "GameFontNormal" )
        UI.MSA_checkbox.Text:SetText( "Nonstop Crafting" )
        UI.MSA_checkbox.Text:SetPoint( "LEFT" , UI.MSA_checkbox, "RIGHT" , 2 , 0 )

        -- Normalize the click area of check button to length of the text
        UI.MSA_checkbox:SetHitRectInsets ( 0 , 0 - UI.MSA_checkbox.Text:GetWidth() - 2 , 0 , 0 );

        -- Ensures this is always to the left of the CreateAllButton, accounting for width of text also
        UI.MSA_checkbox:SetPoint ( "BOTTOMLEFT" , ProfessionsFrame.CraftingPage.CreateAllButton , "TOPLEFT" , 0 , 10 )

        -- Change the setting wether enabled or not
        UI.MSA_checkbox:SetScript ( "OnClick" , function( self )
            MSA_save.non_stop = self:GetChecked()
        end)

        -- Tooltip
        UI.MSA_checkbox:SetScript ( "OnEnter" , function( self )
            GameTooltip:SetOwner ( self , "ANCHOR_CURSOR" );
            GameTooltip:AddLine ( "MSA Limitation: Nonstop will only work for reagents within player bags, not bank tabs." );
            GameTooltip:Show();
        end);

        UI.MSA_checkbox:SetScript ( "OnLeave" , function()
            GameTooltip:Hide()
        end)

        -- Create an event to track when the profession spell changes thus it only runs the checkbox
        -- Show or Hide when necessary
        local Checkbox_Tracker = CreateFrame ( "Frame" );
        Checkbox_Tracker:RegisterEvent ( "SPELL_DATA_LOAD_RESULT" );
        Checkbox_Tracker:SetScript ( "OnEvent" , UI.Configure_Visiblity );

    end

end

-- Method:          UI.Is_Supported_Profession ( int )
-- What it Does:    Returns true if the profession has been added and configured by addon dev for mass crafting
-- Purpose:         Addon will continue to expand usage.
UI.Is_Supported_Profession = function ( profession_id )

    local ids = {
        -- [164] = "Blacksmithing",
        -- [165] = "Leatherworking",
        [171] = "Alchemy",
        [182] = "Herbalism",
        [185] = "Cooking",
        [197] = "Tailoring",
        [202] = "Engineering",
        [755] = "Jewelcrafting",
        [773] = "Inscription"
    }

    if ids[profession_id] then
        return true
    end
    return false
end

-- Method:          UI.Configure_Visiblity( nil , nil , int )
-- What it Does:    Shows or hides the checkbox for mass crafting depending on prfession and spell
-- Purpose:         Only show checkbox when necessary.
UI.Configure_Visiblity = function( _ , _ , spell_id )
    if spell_id then
        if UI.Is_Supported_Profession(C_TradeSkillUI.GetBaseProfessionInfo().professionID) and MSA.Crafting.IsMassCraftingSpell(spell_id) then
            UI.MSA_checkbox:Show()
        else
            UI.MSA_checkbox:Hide()
        end
    end
end

