--██╗     ██╗████████╗████████╗██╗     ███████╗██╗      █████╗ ██████╗ ██╗   ██╗    ██████╗ ██╗   ██╗███╗   ██╗████████╗██╗███╗   ███╗███████╗
--██║     ██║╚══██╔══╝╚══██╔══╝██║     ██╔════╝██║     ██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔══██╗██║   ██║████╗  ██║╚══██╔══╝██║████╗ ████║██╔════╝
--██║     ██║   ██║      ██║   ██║     █████╗  ██║     ███████║██║  ██║ ╚████╔╝     ██████╔╝██║   ██║██╔██╗ ██║   ██║   ██║██╔████╔██║█████╗  
--██║     ██║   ██║      ██║   ██║     ██╔══╝  ██║     ██╔══██║██║  ██║  ╚██╔╝      ██╔══██╗██║   ██║██║╚██╗██║   ██║   ██║██║╚██╔╝██║██╔══╝  
--███████╗██║   ██║      ██║   ███████╗███████╗███████╗██║  ██║██████╔╝   ██║       ██║  ██║╚██████╔╝██║ ╚████║   ██║   ██║██║ ╚═╝ ██║███████╗
--╚══════╝╚═╝   ╚═╝      ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝
-- Ascii art generated with https://patorjk.com/software/taag/
-- Originally created by ExeVirus/Just_Visiting for the 2021 Minetest Game Jam

local levels = {} -- table of registered levels to load

-------------------
-- Public API
-------------------
ll_runtime = {} --global table for other dependent mod access

-- Add register_level
ll_runtime.register_level = function(num, name, x, y, z, num_stars, image, formspec)
    table.insert(levels, {num=num, name=name, x=x, y=y, z=z, num_stars = num_stars, image=image, formspec=formspec})
end

-------------------
-- First time setup
-------------------
local worldmt = Settings(minetest.get_worldpath().."/world.mt")
if worldmt:get("backend") ~= "dummy" then
    worldmt:set("backend","dummy")
    worldmt:write()
    minetest.log("Changed map backend to RAM only (Dummy), forcing restart")
    minetest.request_shutdown("Intial world setup complete, please reconnect",true,0)
end

-------------------
-- Main Menu
-------------------
-- Register on_mods loaded
--  1. Sort the levels list

--Register on_join player
--  1. Turn off player gravity and stop them from falling
--  2. Display the main menu

-- Function display_main_menu()
--  0. Title
--  1. For each level in sorted_levels
--      a. Check if player has completed previous level (except for number 1)
--          image_button
--      else
--          image (darkened)
--      end
--      b. name of level

--Main menu formspec:
--  1. title
--  2. Have a vertical scrollbar section with each level getting it's own image button, name, and number
--    a. For each level not-yet completed (check singleplayer meta), darken it out and disable the button (just show an image)

--On receive:
--  1. Check that player can actually start that level (first level always succeeds)
--  2. Display Loading_level formspec (with animated ...)
--  3. Load level

--Load level


