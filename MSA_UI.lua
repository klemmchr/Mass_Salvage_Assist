-- For the UI Frames of Mass Salvage Assist adddon

local UI = {};
MSA.UI = UI;

-- Holds GUI frame load configuration details
UI.LoadUI = function()

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
            UI.MSA_checkbox.value = MSA_save.non_stop
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

----------------------------
------ UI DEVELOPMENT ------
---------- TIMER -----------
----------------------------

-- Deploy it
UI.Deploy_Timer_UI = function()

    if not UI.CT_Core_Frame then
        -- Core frame
        UI.CT_Core_Frame = CreateFrame( "Frame" , "CT_Core_Frame" , UIParent , BackdropTemplateMixin and "BackdropTemplate" );
        UI.CT_Core_Frame:SetBackdrop ( {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" ,
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 8,
            insets = { left = 2 , right = 2 , top = 3 , bottom = 2 }
         })
        UI.CT_Core_Frame:SetPoint ( MSA_save.pos[1] , UIParent , MSA_save.pos[2] , MSA_save.pos[3] , MSA_save.pos[4] );
        UI.CT_Core_Frame:SetSize( 300 , 120 );
        UI.CT_Core_Frame:EnableMouse ( true );
        UI.CT_Core_Frame:SetToplevel ( true );
        UI.CT_Core_Frame:EnableMouse ( true );
        UI.CT_Core_Frame:SetMovable ( true );
        UI.CT_Core_Frame:RegisterForDrag ( "LeftButton" );
        UI.CT_Core_Frame:SetScript ( "OnDragStart" , UI.CT_Core_Frame.StartMoving )
        UI.CT_Core_Frame:SetScript ( "OnDragStop" , function( self )
            self:StopMovingOrSizing()
            local pos1 , _ , pos2 , x , y = self:GetPoint();
            MSA_save.pos = { pos1 , pos2 , x , y };
        end);
        UI.CT_Core_Frame.value = 0              -- Will be placeholder of the seconds...
        UI.CT_Core_Frame.On_Update_Timer = 0;   -- Control speed of on_update.
        UI.CT_Core_Frame.craft_id = 0;          -- Keep tabs on the craft ID
        UI.CT_Core_Frame.refresh_count = 0      -- Refresh the countdown every X crafts

        -- Keep it closed at start
        UI.CT_Core_Frame:Hide();

        UI.CT_Core_Frame:SetScript( "OnShow" , function()
            if C_TradeSkillUI.IsRecipeRepeating() then
                if #CT.timer_table < 10 then
                    MSA.UI.CT_Core_Frame.Countdown_Text:SetText( "Calculating..." )
                elseif MSA.UI.CT_Core_Frame.value > 0 then
                    MSA.UI.CT_Core_Frame.Countdown_Text:SetText( formatTime ( MSA.UI.CT_Core_Frame.value ) );
                end
            end
        end)

        -- Close Button
        UI.CT_Core_Frame.CT_CloseButton = CreateFrame( "Button" , "CT_CloseButton" , UI.CT_Core_Frame , "UIPanelCloseButton");
        UI.CT_Core_Frame.CT_CloseButton:SetPoint( "TOPRIGHT" , UI.CT_Core_Frame , "TOPRIGHT" , -4 , -4 );
        UI.CT_Core_Frame.CT_CloseButton:SetSize ( 26 , 26 );

        -- Font Strings Title and main
        UI.CT_Core_Frame.Header_Text = UI.CT_Core_Frame:CreateFontString ( nil , "OVERLAY" , "GameFontWhiteTiny" );
        UI.CT_Core_Frame.Header_Text:SetPoint ( "TOP" , UI.CT_Core_Frame, "TOP" , 0 , -12 );
        UI.CT_Core_Frame.Header_Text:SetFont( STANDARD_TEXT_FONT , 14 , "BOLD");
        UI.CT_Core_Frame.Header_Text:SetText ( "Time Remaining" );

        UI.CT_Core_Frame.Countdown_Text = UI.CT_Core_Frame:CreateFontString ( nil , "OVERLAY" , "GameFontWhite" );
        UI.CT_Core_Frame.Countdown_Text:SetPoint ( "TOP" , UI.CT_Core_Frame.Header_Text , "BOTTOM" , 0 , -5 );


        --------------------------------
        -------- TIMER SETTINGS --------
        ---------- CHECKBOXES ----------

        -- MSA_save.count_bags_Only  == nil then        -- Only applies when Salvaging
        --     MSA_save.count_bags_Only = true
        -- end

        -- if MSA_save.always_show

        UI.CT_Core_Frame.Always_Show_Checkbox = CreateFrame ( "CheckButton" , "Always_Show_Checkbox" , UI.CT_Core_Frame , "InterfaceOptionsCheckButtonTemplate" )
        UI.CT_Core_Frame.Always_Show_Checkbox.value = MSA_save.always_show
        UI.CT_Core_Frame.Always_Show_Checkbox:SetChecked ( UI.CT_Core_Frame.Always_Show_Checkbox.value )

        -- Text to the right of checkbox
        UI.CT_Core_Frame.Always_Show_Checkbox.Text = UI.CT_Core_Frame.Always_Show_Checkbox:CreateFontString ( nil , "OVERLAY" , "GameFontNormal" )
        UI.CT_Core_Frame.Always_Show_Checkbox.Text:SetFont( STANDARD_TEXT_FONT , 12 , "BOLD");
        UI.CT_Core_Frame.Always_Show_Checkbox.Text:SetText( "Always Show Timer When Crafting" )
        UI.CT_Core_Frame.Always_Show_Checkbox.Text:SetPoint( "LEFT" , UI.CT_Core_Frame.Always_Show_Checkbox, "RIGHT" , 2 , 0 )

        -- Normalize the click area of check button to length of the text
        UI.CT_Core_Frame.Always_Show_Checkbox:SetHitRectInsets ( 0 , 0 - UI.CT_Core_Frame.Always_Show_Checkbox.Text:GetWidth() - 2 , 0 , 0 );

        -- Ensures this is always to the left of the CreateAllButton, accounting for width of text also
        UI.CT_Core_Frame.Always_Show_Checkbox:SetPoint ( "BOTTOMLEFT" , UI.CT_Core_Frame , "BOTTOMLEFT" , 10 , 10 )

        -- Change the setting wether enabled or not
        UI.CT_Core_Frame.Always_Show_Checkbox:SetScript ( "OnClick" , function( self )
            MSA_save.always_show = self:GetChecked()
            UI.MSA_checkbox.value = MSA_save.always_show
            if not UI.MSA_checkbox.value then
                print('If you wish to reopen the timer again, type `/msa timer' )
            end
        end)

    end

end

-----------------
--- UI LOGIC ----
-----------------

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
        [333] = 'Enchanting',
        [393] = "Skinning",
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

