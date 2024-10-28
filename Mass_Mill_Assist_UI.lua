-- For the UI Frames of Mass Milling Assist adddon

local UI = {};
MassMA.UI = UI;

local INSCRIPTION_ID = 773

-- Holds GUI frame load configuration details
UI.LoadUI = function()

    -- Checkbox to be placed on inscription window
    if not UI.MMA_checkbox then

        UI.MMA_checkbox = CreateFrame ( "CheckButton" , "MMA_checkbox" , ProfessionsFrame.CraftingPage , "InterfaceOptionsCheckButtonTemplate" )
        UI.MMA_checkbox.value = MassMA_save.non_stop
        UI.MMA_checkbox:SetChecked ( UI.MMA_checkbox.value )

        UI.MMA_checkbox:SetPoint ( "TOPLEFT" , ProfessionsFrame.CraftingPage.SchematicForm , "BOTTOMLEFT" , 10 , -4 )

        -- Text to the right of checkbox
        UI.MMA_checkbox.Text = UI.MMA_checkbox:CreateFontString ( nil , "OVERLAY" , "GameFontNormal" )
        UI.MMA_checkbox.Text:SetText( "Nonstop Mass Milling" )
        UI.MMA_checkbox.Text:SetPoint( "LEFT" , UI.MMA_checkbox, "RIGHT" , 3 , 0 )

        -- Normalize the click area of check button to length of the text
        UI.MMA_checkbox:SetHitRectInsets ( 0 , 0 - UI.MMA_checkbox.Text:GetWidth() - 2 , 0 , 0 );

        -- Change the setting wether enabled or not
        UI.MMA_checkbox:SetScript ( "OnClick" , function( self )
            MassMA_save.non_stop = self:GetChecked()
        end)

        -- Tooltip
        UI.MMA_checkbox:SetScript ( "OnEnter" , function( self )
            GameTooltip:SetOwner ( self , "ANCHOR_CURSOR" );
            GameTooltip:AddLine ( "MMA Limitation: Nonstop will only work for herbs within player bags, not bank tabs." );
            GameTooltip:Show();
        end);

        UI.MMA_checkbox:SetScript ( "OnLeave" , function()
            GameTooltip:Hide()
        end)

        -- Create an event to track when the profession spell changes thus it only runs the checkbox
        -- Show or Hide when necessary
        local Checkbox_Tracker = CreateFrame ( "Frame" );
        Checkbox_Tracker:RegisterEvent ( "SPELL_DATA_LOAD_RESULT" );
        Checkbox_Tracker:SetScript ( "OnEvent" , UI.Configure_Visiblity );

    end

end

-- Method:          UI.Configure_Visiblity( nil , nil , int )
-- What it Does:    Shows or hides the checkbox for mass milling depending on prfession and spell
-- Purpose:         Only show checkbox when necessary.
UI.Configure_Visiblity = function( _ , _ , spell_id )
    if spell_id then
        if C_TradeSkillUI.GetBaseProfessionInfo().professionID == INSCRIPTION_ID and MassMA.Milling.MillingSpells[spell_id] then
            UI.MMA_checkbox:Show()
        else
            UI.MMA_checkbox:Hide()
        end
    end
end

