
local Milling = {};
MassMA.Milling = Milling;

local combiningHerbs = false;
Milling.MillingSpells = { [444181] = "TWW" , [382981] = "DF" , [382982] = "SL" , [382984] = "BFA" , [382986] = "LG" , [382987] = "WOD" , [382988] = "PANDA" , [382989] = "CATA" , [382990] = "WOTLK" , [382991] = "TBC" , [382994] = "CLASSIC"  }

-- Method:          Milling.CombineHerbStacks ( array , bool , bool , int )
-- What it Does:    Determines which item is being milled, and then keeps the stacks refreshed so milling can continue indefinitely.
-- Purpose:         Quality of life for mass milling thousands.
Milling.CombineHerbStacks = function( scrapSlot , forced , restart_crafting , craft_id )
    if not combiningHerbs or forced then

        combiningHerbs = true;
        scrapSlot = scrapSlot or nil;
        if restart_crafting == nil then
            restart_crafting = false;
        end

        local lowestStack;
        local maxStackSize = 1000
        local itemInfo;
        local itemID;

        if not scrapSlot and ( C_TradeSkillUI.IsRecipeRepeating() or restart_crafting ) then
            scrapSlot , itemID = Milling.GetSalveItemDetails();
        end

        if scrapSlot then

            -- BLIZZ HAS AN ORDER OF MILLING PRIORITY
            -- * PLAYER BAGS
            -- * PLAYER REAGENT BAG
            -- * PLAYER BANK
            -- * PLAYER REAGENT BANK
            -- * PLAYER WARBAND (TABS IN ORDER)

            -- Let's review first the bags in the slots
            for bag = 0 , NUM_BAG_SLOTS + 1 do  -- Loop through all bags (0 is backpack, 1-4 are additional bags, +1 for reagent bag)
                for slot = 1, C_Container.GetContainerNumSlots( bag ) do

                    if scrapSlot[1] ~= bag or scrapSlot[2] ~= slot then
                        itemInfo = C_Container.GetContainerItemInfo( bag , slot )

                        if itemInfo and itemInfo.itemID == itemID then

                            if lowestStack and lowestStack[3] > itemInfo.stackCount then
                                lowestStack = { bag , slot , itemInfo.stackCount};
                            elseif not lowestStack then
                                lowestStack = { bag , slot , itemInfo.stackCount};
                            end

                        end
                    end
                end
            end

            if lowestStack then
                -- Now, let's combine all of the smallest herbs to biggest stacks.
                C_Container.PickupContainerItem( lowestStack[1] , lowestStack[2] );
                C_Container.PickupContainerItem( scrapSlot[1] , scrapSlot[2] );

                -- This is important as if you try to get the OnClick script whilst it is NOT repeating, you will cause a permissions taint error
                if C_TradeSkillUI.IsRecipeRepeating() then
                    local buttonScript = ProfessionsFrame.CraftingPage.CreateAllButton:GetScript("OnClick");

                    if buttonScript then
                        buttonScript();
                    end
                end

                if (scrapSlot[3] + lowestStack[3]) < maxStackSize then
                    C_Timer.After ( 1.5 , function()
                        Milling.CombineHerbStacks( scrapSlot , true , restart_crafting , craft_id );  -- Cycle back through to collect ALL the herbs. There needs to be a slight delay between each item move due to Blizz's bag limitations with stacking. not sure why.
                    end);
                    return;
                end
            end
        end
    end
    combiningHerbs = false;
    if restart_crafting and not C_TradeSkillUI.IsRecipeRepeating() then
        print("MMA: Unable to overcome stacking issue. Please be sure to select the first stack and MMA will keep the stacks refreshed from here on out.")
    end
end

-- Method:          Milling.GetSalveItemDetails()
-- What it Does:    Determines the details of the item and slot the herb is being mass milled from
-- Purpose:         To replenish this stack, I need information. This also accomplishes accounting for the bug
--                  that Blizz has failed to fix in 2 expansions so far (DF and TWW) where even though you select a stack
--                  It mass mills the bag in order of slot position regardles (right and up in the bags). So, it will replenish
--                  First slot if it fails rather than the selected slot.
Milling.GetSalveItemDetails = function()

    local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
    if not item then
        return;
    end

    -- This is failing, so add stacks to first slot (compensates for positioning bug of milling not milling the item you selected, but first in slot)
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

        local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
        if not item then
            return;
        end

        -- Mills the selected item in the salvage box.
    else
        local id = item.debugItemID;
        local itemDetails = item:GetItemLocation();

        if itemDetails then
            local bag , slot = itemDetails.bagID , itemDetails.slotIndex;
            return { bag , slot , C_Container.GetContainerItemInfo( bag , slot ).stackCount } , id;
        end
    end

end

-- Method:          Milling.GetFirstHerbSizeStack()
-- What it Does:    Returns the stack count of the first slot in the bags where the herb is
-- Purpose:         Need to know how many in the stack if going to initialize herb stacking immediately.
Milling.GetFirstHerbSizeStack = function()
    local item = ProfessionsFrame.CraftingPage.SchematicForm:GetTransaction().salvageItem;
    if not item then
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

-- Method:          Milling.is_reagent_bag_open()
-- What it Does:    Returns true of the reagent bag is open
-- Purpose:         To know which bank tab to sort the herbs in
Milling.is_reagent_bag_open = function()
    if BankFrame:IsShown() and BankFrame.selectedTab == 2 then
        return true
    else
        return false
    end
end

-- Method:          Milling.is_warband_bank_open()
-- What it Does:    Returns true of the Warband bag is open
-- Purpose:         To know which bank tab to sort the herbs in
Milling.is_warband_bank_open = function()
    if BankFrame:IsShown() and BankFrame.selectedTab == 3 then      -- This selectedTab works both for Bank and the Distance Inhibitor
        return true
    else
        return false
    end
end

-- Method:          Milling.MillListener ()
-- What it Does:    Acts as an event listener to control when to trigger the herb stacking action
-- Purpose:         Quality of life helper for mass milling.
Milling.MillListener = function ()
    if MassMA_save.non_stop and not combiningHerbs and ( C_TradeSkillUI.GetRemainingRecasts() < 25 or Milling.GetFirstHerbSizeStack() < 100 ) then
        Milling.CombineHerbStacks();
    end
end

-- Event listenr to account for actions to know when to align conditions to begin stacking the herbs in bags.
local MillingFrame = CreateFrame( "FRAME" , "MassMA_MillingListener" );
MillingFrame:RegisterEvent( "TRADE_SKILL_CRAFT_BEGIN" );
MillingFrame:RegisterEvent( "UNIT_SPELLCAST_FAILED" );
MillingFrame:SetScript( "OnEvent" , function( _ , event , craft_id , t , failed_id )

    if event == "TRADE_SKILL_CRAFT_BEGIN" and Milling.MillingSpells[craft_id] then
        Milling.MillListener();

    elseif event == "UNIT_SPELLCAST_FAILED" and MassMA_save.non_stop and Milling.MillingSpells[failed_id] and C_TradeSkillUI.GetCraftableCount(failed_id) > 0 and not combiningHerbs then
        Milling.CombineHerbStacks( nil , nil , true , failed_id );

    end

end);