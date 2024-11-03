-- Let's build a listener to help determine total crafting time
local CT = {};      -- CT for Craft Timer
CT.timer_table = {}
if MSA then
    MSA.CT = CT;    -- Compatibiity with Mass Crafting Assist addon
end

-- Method:          CT.Get_Avg_Craft_Time()
-- What it Does:    Returns back the avg crafting time
-- Purpose:         So calculation on total crafting time can be made
CT.Get_Avg_Craft_Time = function()
    local sum = 0

    for i = 1 , #CT.timer_table do
        sum = sum + CT.timer_table[i];
    end

    return ( sum / #CT.timer_table ) ;
end

-- Method:          formatTime ( int )
-- What it Does:    Creates a nice countdown of how much time is remaining
-- Purpose:         Quality of Life information
local function formatTime (seconds)
    if seconds < 60 then
        -- Less than a minute
        return string.format("%d seconds", seconds)
    end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = math.floor (seconds % 60)

    if hours > 0 then
        -- Has hours
        return string.format("%d hrs, %d minutes, %d seconds", hours, minutes, remainingSeconds)
    else
        -- Just minutes and seconds
        return string.format("%d minutes, %d seconds", minutes, remainingSeconds)
    end
end

-- Method:          CT.Calculate_Remaining_Time()
-- What it Does:    Returns the estimated total crafting time of the item currently
--                  being processed
-- Purpose:         Quality of life information
CT.Calculate_Remaining_Time = function()
    if #CT.timer_table > 9 then
        local avg = CT.Get_Avg_Craft_Time();
        local seconds = math.floor ( (avg * C_TradeSkillUI.GetCraftableCount(MSA.UI.CT_Core_Frame.craft_id)) + 0.5 );
        MSA.UI.CT_Core_Frame.value = seconds;
        MSA.UI.CT_Core_Frame.Countdown_Text:SetText( formatTime ( seconds ) );
    end
end

local timestamp = 0;
local function Trade_Skill_Craft_Record()
    if C_TradeSkillUI.IsRecipeRepeating() then
        if timestamp > 0 then
            table.insert ( CT.timer_table , ( GetTime() - timestamp ) )    -- GetTime is more precise than Epoch
            if #CT.timer_table > 100 then
                table.remove ( CT.timer_table , 1 );
            elseif #CT.timer_table == 100 then
                -- If exactly 100 it just got to 100, reset count tracking.
                CT.Initialize_Countdown();
            end
        end
        timestamp = GetTime();
    else
        if MSA_save.always_show then
            MSA.UI.CT_Core_Frame:Show();
        end
        CT.timer_table = {};
    end
end

local msa_timer = CreateFrame( "FRAME" , "MSA_Crafting_Timer" )
msa_timer:RegisterEvent("TRADE_SKILL_CRAFT_BEGIN")
msa_timer:SetScript("OnEvent", function( _ , event , craft_id )
    if event == "TRADE_SKILL_CRAFT_BEGIN" then
        Trade_Skill_Craft_Record()
        MSA.UI.CT_Core_Frame.craft_id = craft_id

        if #CT.timer_table > 0 then

            if #CT.timer_table < 10 then
                MSA.UI.CT_Core_Frame.Countdown_Text:SetText( "Calculating..." )
            elseif MSA.UI.CT_Core_Frame.value == 0 then
                CT.Calculate_Remaining_Time();
                CT.Initialize_Countdown();
            end
        end
    end
end)

local countdown_running = false;
-- TIMER FOR FRAME TRACKING UPDATES
CT.Initialize_Countdown = function( isRepeating )
    if not countdown_running or isRepeating then
        countdown_running = true;

        local count_remaining = C_TradeSkillUI.GetCraftableCount(MSA.UI.CT_Core_Frame.craft_id);
        MSA.UI.CT_Core_Frame.refresh_count = MSA.UI.CT_Core_Frame.refresh_count + 1;
        if MSA.UI.CT_Core_Frame.refresh_count == 300 or count_remaining < 100 and count % 20 == 0 then   -- Recalculate every 5 min, or every 20 crafts last 100
            CT.Calculate_Remaining_Time();
            MSA.UI.CT_Core_Frame.refresh_count = 0;
        end

        MSA.UI.CT_Core_Frame.Countdown_Text:SetText( formatTime ( MSA.UI.CT_Core_Frame.value ) );
        MSA.UI.CT_Core_Frame.value = MSA.UI.CT_Core_Frame.value - 1;
        C_Timer.After ( 1 , function()
            if C_TradeSkillUI.IsRecipeRepeating() then
                CT.Initialize_Countdown( true );
            else
                C_Timer.After ( 2 , function()
                    CT.timer_table = {};
                    MSA.UI.CT_Core_Frame.value = 0;
                    MSA.UI.CT_Core_Frame.craft_id = 0;
                    countdown_running = false;
                    MSA.UI.CT_Core_Frame:Hide();
                end)
            end
        end)
    end
end