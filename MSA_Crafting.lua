
local Crafting = {};
MSA.Crafting = Crafting;

local combiningStacks = false;

-- Method:          Crafting.Establish_Spells()
-- What it DoeS:    Builds the dictionary tables for all the profession spells supported
-- Purpose:         Ensure the UI features are only available at compatible profession spells.
-- Note:            The int value of all ids is the number of reagents that need to be processed in spell
Crafting.Establish_Spells = function()
    Crafting.Profs = {}
    Crafting.Profs.MillingSpells = {
        [444181] = 5, [382981] = 5, [382982] = 5, [382984] = 5,
        [382986] = 5, [382987] = 5, [382988] = 5, [382989] = 5,
        [382990] = 5, [382991] = 5, [382994] = 5
    }
    Crafting.Profs.Jewelcrafting = {
        [434018] = 5, [434020] = 3, [374627] = 5, [395696] = 5, [325248] = 5,
        [382973] = 5, [382975] = 5, [382977] = 5, [382978] = 5, [404740] = 3,
        [382979] = 5, [382980] = 5, [382995] = 5
    }
    Crafting.Profs.HerbalismRefine = {
        [438811] = 5, [438812] = 5, [391088] = 5, [391089] = 5
    }
    Crafting.Profs.Cooking = {
        [445117] = 5, [445127] = 5, [445118] = 5, [445119] = 5, [447869] = 5
    }
    Crafting.Profs.Alchemy = {
        [430315] = 20, [370748] = 5, [427214] = 5
    }
    Crafting.Profs.Tailoring = {
        [446926] = 5
    }
    Crafting.Profs.Engineering = {
        [447310] = 5, [447311] = 5
    }
    Crafting.Profs.Enchanting = {
        [470726] = 1
    }
end

-- Method:          Crafting.Get_Reagent_Count_Spell ( int )
-- What it Does:    Returns the number of reagents needed for that crafting spell
-- Purpose:         When combining stacks, I want to always pick the lowest stack first, UNLESS it is small than the minimum stack size to craft
--                  Why? Well, what if 4 herbs are in an early bag slot, but 1 herb is in the final bag slot? I want to stakc the 4 first or else
--                  milling will keep erroring. In all other cases I combine smallest to largest.
Crafting.Get_Reagent_Count_Spell = function( craft_id )
    for spells in pairs ( Crafting.Profs ) do
        if Crafting.Profs[spells][craft_id] then
            return Crafting.Profs[spells][craft_id];
        end
    end
end

-- Method:          Crafting.CombineStacks ( list , bool , bool , int )
-- What it Does:    Determines which item is being processed, and then keeps the stacks refreshed so crafting can continue indefinitely.
-- Purpose:         Quality of life for crafting thousands.
Crafting.CombineStacks = function( scrapSlot , forced , restart_crafting , craft_id )
    if not combiningStacks or forced then

        combiningStacks = true;
        scrapSlot = scrapSlot or nil;
        if restart_crafting == nil then
            restart_crafting = false;
        end

        local lowestStack;
        local maxStackSize = 0  -- Placeholder til it gets replaced.
        local itemInfo;
        local itemID;

        if not scrapSlot and ( C_TradeSkillUI.IsRecipeRepeating() or restart_crafting ) then
            scrapSlot , itemID = Crafting.GetSalveItemDetails( restart_crafting );
        end

        if scrapSlot then

            -- BLIZZ HAS AN ORDER OF CRAFTING PRIORITY
            -- * PLAYER BAGS
            -- * PLAYER REAGENT BAG
            -- * PLAYER BANK
            -- * PLAYER REAGENT BANK
            -- * PLAYER WARBAND (TABS IN ORDER)

            local default_stack_min = 5

            -- Let's review first the bags in the slots
            for bag = 0 , NUM_BAG_SLOTS + 1 do  -- Loop through all bags (0 is backpack, 1-4 are additional bags, +1 for reagent bag)
                for slot = 1, C_Container.GetContainerNumSlots( bag ) do

                    if scrapSlot[1] ~= bag or scrapSlot[2] ~= slot then
                        itemInfo = C_Container.GetContainerItemInfo( bag , slot )

                        if itemInfo and itemInfo.itemID == itemID then

                            maxStackSize = C_Item.GetItemMaxStackSizeByID(itemID);
                            default_stack_min = Crafting.Get_Reagent_Count_Spell(craft_id);

                            if lowestStack and lowestStack[3] > itemInfo.stackCount and lowestStack[3] > default_stack_min then -- This
                                lowestStack = { bag , slot , itemInfo.stackCount};
                            elseif not lowestStack then
                                lowestStack = { bag , slot , itemInfo.stackCount};
                            end

                        end
                    end
                end
            end

            if lowestStack then
                -- Now, let's combine all of the smallest stacks to biggest stacks.
                C_Container.PickupContainerItem( lowestStack[1] , lowestStack[2] );
                C_Container.PickupContainerItem( scrapSlot[1] , scrapSlot[2] );

                -- I don't want to necessarily restart it - This also can only be called WHEN already mass crafting or it will cause taint.
                if C_TradeSkillUI.IsRecipeRepeating() then
                    Crafting.Refresh_Crafting();
                end

                if (scrapSlot[3] + lowestStack[3]) < maxStackSize then
                    C_Timer.After ( 2 , function()
                        Crafting.CombineStacks( scrapSlot , true , restart_crafting , craft_id );  -- Cycle back through to collect ALL the items. There needs to be a slight delay between each item move due to Blizz's bag limitations with stacking.
                    end);
                    return;
                end
            elseif C_TradeSkillUI.IsRecipeRepeating() then
                Crafting.Refresh_Crafting();
            end
        end
    end
    combiningStacks = false;
    if restart_crafting and not C_TradeSkillUI.IsRecipeRepeating() then
        print("MSA: Crafting has ended prematurely. Please restart and crafting will continue nonstop." )
    end
end

-- Method:          Crafting.Refresh_Crafting()
-- What it Does:    Refreshes the Craft all/Mill All button
-- Purpose:         Useful so stacks don't run out.
Crafting.Refresh_Crafting = function()
    ProfessionsFrame.CraftingPage:CreateInternal(ProfessionsFrame.CraftingPage.SchematicForm:GetRecipeInfo().recipeID, ProfessionsFrame.CraftingPage:GetCraftableCount(), ProfessionsFrame.CraftingPage.SchematicForm:GetCurrentRecipeLevel())
end

-- Method:          Crafting.GetSalveItemDetails( bool )
-- What it Does:    Determines the details of the item and slot the item is being processed/milled/prosected/etc, from
-- Purpose:         To replenish this stack, I need information. This also accomplishes accounting for the bug
--                  that Blizz has failed to fix in 2 expansions so far (DF and TWW) where even though you select a stack
--                  It mass mills the bag in order of slot position regardles (right and up in the bags). So, it will replenish
--                  First slot if it fails rather than the selected slot.
Crafting.GetSalveItemDetails = function( restart_crafting )

    local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
    if not item or type(item.debugItemID) ~= "number" then
        return;
    end

    -- This is failing, so add stacks to first slot (compensates for positioning bug of not crafting the item you selected, but first in slot)
    if restart_crafting then
        local item_detail = {}

        for bag = 0 , NUM_BAG_SLOTS + 1 do  -- Loop through all bags + reagent bag
            for slot = 1, C_Container.GetContainerNumSlots( bag ) do
                item_detail = C_Container.GetContainerItemInfo( bag , slot )

                if item_detail and item_detail.itemID == item.debugItemID then
                    return { bag , slot , item_detail.stackCount } , item.debugItemID;
                end
            end
        end

        -- Crafts the selected item in the salvage box.
    else
        local id = item.debugItemID;
        local itemDetails = item:GetItemLocation();

        if itemDetails then
            local bag , slot = itemDetails.bagID , itemDetails.slotIndex;
            return { bag , slot , C_Container.GetContainerItemInfo( bag , slot ).stackCount } , id;
        end
    end

end

-- Method:          Crafting.GetFirstReagentSizeStack()
-- What it Does:    Returns the stack count of the first slot in the bags where the reagent is
-- Purpose:         Need to know how many in the stack if going to initialize reagent stacking immediately.
Crafting.GetFirstReagentSizeStack = function()
    local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
    if not item or type(item.debugItemID) ~= "number" then
        return;
    end

    local item_info = {}

    for bag = 0 , NUM_BAG_SLOTS + 1 do  -- Loop through all bags + reagent bag
        for slot = 1, C_Container.GetContainerNumSlots( bag ) do
            item_info = C_Container.GetContainerItemInfo( bag , slot )

            if item_info and item_info.itemID == item.debugItemID then
                return item_info.stackCount
            end
        end
    end
end

-- Method:          Crafting.Is_More_To_Craft( int )
-- What it Does:    Returns true if there are enough reagents to continue crafting
-- Purpose:         There seems to be a common bug where crafting just stops for some reason when there is maybe only 20 or so
--                  crafts remaining. Or, even you get a resourcefulness proc and now have extra to craft at the end. This will do a
--                  quick bag check if crafting should be continued again after crafting.
Crafting.Is_More_To_Craft = function( craft_id )
    local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
    if not item or type(item.debugItemID) ~= "number" then
        return false;
    end

    local max_stack_size = C_Item.GetItemMaxStackSizeByID(item.debugItemID);
    local default_stack_min = Crafting.Get_Reagent_Count_Spell(craft_id);
    local total_count = 0;
    local first_stack_count = 0;
    local needs_to_stack = false;
    local more_to_craft = false;

    -- Just an escape in case this API fails. It shouldn't but there could be issues with long latency that could cause this to error out.
    if not max_stack_size then
        return false;
    end

    -- Let's see what's in our bags!
    for bag = 0 , NUM_BAG_SLOTS + 1 do  -- Loop through all bags + reagent bag
        for slot = 1, C_Container.GetContainerNumSlots( bag ) do
            local item_info = C_Container.GetContainerItemInfo( bag , slot )

            -- Establish the first stack size and the total amoutn
            -- We do this because I need to know if there are additional items in the bags to be stacked.
            if item_info and item_info.itemID == item.debugItemID then
                if first_stack_count == 0 then
                    first_stack_count = item_info.stackCount;
                end
                total_count = total_count + item_info.stackCount;
            end
        end
    end

    if first_stack_count < total_count and first_stack_count < max_stack_size then
        needs_to_stack = true
    end

    if total_count >= default_stack_min then
        more_to_craft = true
    end

    return needs_to_stack , more_to_craft
end

-- Method:          Crafting.is_reagent_bag_open()
-- What it Does:    Returns true of the reagent bag is open
-- Purpose:         To know which bank tab to sort the reagents in
Crafting.is_reagent_bag_open = function()
    if BankFrame:IsShown() and BankFrame.selectedTab == 2 then
        return true
    else
        return false
    end
end

-- Method:          Crafting.is_warband_bank_open()
-- What it Does:    Returns true of the Warband bag is open
-- Purpose:         To know which bank tab to sort the reagents in
Crafting.is_warband_bank_open = function()
    if BankFrame:IsShown() and BankFrame.selectedTab == 3 then      -- This selectedTab works both for Bank and the Distance Inhibitor
        return true
    else
        return false
    end
end

-- Method:          Crafting.CraftListener ( int )
-- What it Does:    Acts as an event listener to control when to trigger the reagent stacking action
-- Purpose:         Quality of life helper for mass Crafting.
Crafting.CraftListener = function ( craft_id )
    if MSA_save.non_stop and not combiningStacks then
        local first_stack = Crafting.GetFirstReagentSizeStack()
        local remaining_casts = C_TradeSkillUI.GetRemainingRecasts()

        -- Note: Get CraftableCount is minus 2 to accomodate for API counting mismatch, it's always 1 less because you just crafted, and there is a 1 count lag,
        if ( remaining_casts and remaining_casts < 25 ) or ( first_stack and first_stack < 100 ) then
            Crafting.CombineStacks( nil , nil , nil , craft_id );
        end
    end
end

-- Method:          Crafting.IsMassCraftingSpell ( int )
-- What it Does:    Returns true if this is a crafting spell in the list
-- Purpose:         Really just cleaner code to wrap all these truthy checks into a single function.
Crafting.IsMassCraftingSpell = function( craft_id )

    for spells in pairs ( Crafting.Profs ) do
        if Crafting.Profs[spells][craft_id] then
            return true
        end
    end

    return false
end

-- Event listener to account for actions to know when to align conditions to begin stacking the reagents in bags.
local CraftingFrame = CreateFrame( "FRAME" , "MSA_CraftingListener" );
CraftingFrame:RegisterEvent( "TRADE_SKILL_CRAFT_BEGIN" );
CraftingFrame:RegisterEvent( "UNIT_SPELLCAST_FAILED" );
CraftingFrame:SetScript( "OnEvent" , function( _ , event , craft_id , _ , failed_id )

    if event == "TRADE_SKILL_CRAFT_BEGIN" then
        if Crafting.IsMassCraftingSpell ( craft_id ) then
            Crafting.CraftListener(craft_id);
        end

    elseif event == "UNIT_SPELLCAST_FAILED" and MSA_save.non_stop and Crafting.IsMassCraftingSpell ( failed_id ) and C_TradeSkillUI.GetCraftableCount(failed_id) > 0 and not combiningStacks then
        local needs_to_stack , more_to_craft = Crafting.Is_More_To_Craft();

        -- Do we need to restack herbs and restart, or do we need to just restart
        if needs_to_stack then
            Crafting.CombineStacks( nil , nil , true , craft_id );

        elseif more_to_craft then
            print("MSA: Crafting has ended prematurely. Please restart and crafting will continue nonstop." )
        end
    end

end);