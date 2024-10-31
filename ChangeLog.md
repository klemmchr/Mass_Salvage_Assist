
## **Mass Salvage Assist - Version 1.0.4 - Oct 31st, 2024

*I was unaware of the memory leak issue on Blizz's end where when crafting the addon memory usage can go through the roof. While it still does proper garbage collection, it still consumes massive amounts of memory when using professions. This isn't a huge deal, except if you are on a PC where Frames start to slow down, and it gets choppy, this can actually end up interrupting nonstop crafting. So, I was informed by a few people that there is actually this workaround people developed to bypass this memory issue by way of using macros. You can start salvaging with a macro rather than ever opening the player window. I have decided to implement this type of adaptation support to this addon as well.*

* Code tweaked slightly that will help some memory performance with the professions window, but it doesn't resolve the main issue with professions.

* Mass Salvage Assist(MSA) will now full support salvaging nonstop even without the profession window open.

* Slash command has been added to the addon `/msa`

    - Example - Mass Mill Hochenblume:
    - `/msa craft recipe_id item_id`
    - `/msa craft 382981 191461`
    -
    - You can also get help:
    - `/msa help`

    - YES, this can be used within a macro.

* Please note, the profession

## **Mass Salvage Assist - Version 1.0.3 - Oct 29th, 2024

* Coreway Catalysts spell added for Alchemy

* Gleaming Shatter added for Enchanting

## **Mass Salvage Assist - Version 1.0.2 - Oct 29th, 2024

* Changed position of the checkbox so it is compatible with other professions.


## **Mass Salvage Assist - Version 1.0.1 - Oct 29th, 2024

* Fixed an issue that can cause a Lua error with certain reagents.


## **Mass Crafting Assist - Version 1.0.0 - Oct 28th, 2024

* Mass Mill Assist has been converted to Mass Crafting Assist due to expanded functionality beyond milling.