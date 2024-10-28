
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
    if MassMA_save.non_stop and not combiningHerbs then
        local first_stack = Milling.GetFirstHerbSizeStac
        local remaining_casts = C_TradeSkillUI.GetRemainingRecasts()
        if ( remaining_casts and C_TradeSkillUI.GetRemainingRecasts() < 25 ) or ( first_stack and first_stack < 100 ) then
            Milling.CombineHerbStacks();
        end
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

-- -- To be used eventually
-- HerbsEnum = {
--     ["CLASSIC"] = {
--         [765] = true , [785] = true , [2447] = true , [2449] = true , [2450] = true , [2452] = true , [2453] = true , [3355] = true , [3356] = true , [3357] = true , [3358] = true , [3369] = true , [3820] = true , [3818] = true , [3819] = true , [3821] = true , [4625] = true , [8153] = true , [8831] = true , [8836] = true , [8838] = true , [8839] = true , [8845] = true , [8846] = true , [13463] = true , [13464] = true , [13465] = true , [13466] = true , [13467] = true , [13468] = true , [19726] = true
--     },
--     ["TBC"] = {
--         [181270] = true , [181271] = true , [181275] = true , [181277] = true , [181278] = true , [181279] = true , [181280] = true , [181281] = true
--     },
--     ["WOTLK"] = {
--         [190169] = true , [190170] = true , [190171] = true , [190172] = true , [190173] = true , [190175] = true , [190176] = true , [191303] = true , [189973] = true , [191019] = true
--     },
--     ["CATA"] = {
--         [202747] = true , [202748] = true , [202749] = true , [202750] = true , [202751] = true , [202752] = true
--     },
--     ["PANDA"] = {
--         [89639] = true , [109130] = true , [79010] = true , [79011] = true , [72235] = true , [72237] = true
--     },
--     ["WOD"] = {
--         [109124] = true , [109125] = true , [109126] = true , [109127] = true , [109128] = true , [109129] = true   -- Chameleon Lotus removed from game
--     },
--     ["LG"] = {
--         [124101] = true , [124102] = true , [124103] = true , [124104] = true , [124105] = true , [124106] = true , [128304] = true , [151565] = true
--     },
--     ["BFA"] = {
--         [152505] = true , [152506] = true , [152507] = true , [152508] = true , [152509] = true , [152510] = true , [152511] = true , [168487] = true
--     },
--     ["SL"] = {
--         [187699] = true , [171315] = true , [168583] = true , [168586] = true , [168589] = true , [170554] = true , [169701] = true
--     },
--     ["DF"] = {
--         [191460 ] = true , [191461] = true , [191462] = true , [191464 ] = true , [191465] = true , [191466] = true , [191467 ] = true , [191468] = true , [191469] = true , [191470 ] = true , [191471] = true , [191472] = true
--     },
--     ["TWW"] = {
--         [210796] = true , [210797] = true , [210798] = true , [210799] = true , [210800] = true , [210801] = true , [210802] = true , [210803] = true , [210804] = true , [210805] = true , [210806] = true , [210807] = true , [210808] = true , [210809] = true , [210810] = true , [222538] = true
--     }
-- }