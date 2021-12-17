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
local handle = nil
ll_runtime.register_level = function(mts_location, num, name, start, num_stars, image, formspec, music)
    handle = minetest.register_schematic(mts_location)
    --if handle ~= nil then
        table.insert(levels, {num=num, name=name, scheme=mts_location, start=start, num_stars = num_stars, image=image, formspec=formspec, music=music})
    --else
        --error("File: " .. mts_location .. "was unable to load properly, quitting")
    --end
end

-------------------
-- Local API
-------------------
local music_handle = nil
local function play_music(filename)
    --Close the previous music
    if music_handle ~= nil then
        minetest.sound_fade(music_handle, 0.7, 0) --fast fade
    end
    -- Play the new music
    music_handle = minetest.sound_play(filename, {loop=true}) --loop until close

    --if still nil, play the default
    if music_handle == nil then
        music_handle = minetest.sound_play("default", {loop=true})
    end
end

--Tracker Variables
local loaded_level = nil
local globalsteps_enabled = false
local stars_collected = 0
local HUD = {} -- is a table of handles

--Some declarations to local functions defined later
local main_menu = nil
local load_level = nil
local unload_level = nil
local reset_player = nil
local win_level = nil

-------------------
-- First time setup
--    (which executes before any levels or schematics are loaded)
-------------------
local worldmt = Settings(minetest.get_worldpath().."/world.mt")
if worldmt:get("backend") ~= "dummy" then
    worldmt:set("backend","dummy")
    worldmt:write()
    minetest.log("Changed map backend to RAM only (Dummy), forcing restart")
    minetest.request_shutdown("Intial world setup complete, please reconnect",true,0)
end
-------------------
--Load our Settings
-------------------
local function handleColor(settingtypes_name, default)
    return minetest.settings:get(settingtypes_name) or default
end
local primary_c              = handleColor("laby_primary_c",              "#06EF")
local hover_primary_c        = handleColor("laby_hover_primary_c",        "#79B1FD")
local on_primary_c           = handleColor("laby_on_primary_c",           "#FFFF")
local secondary_c            = handleColor("laby_secondary_c",            "#FFFF")
local hover_secondary_c      = handleColor("laby_hover_secondary_c",      "#AAAF")
local on_secondary_c         = handleColor("laby_on_secondary_c",         "#000F")
local background_primary_c   = handleColor("laby_background_primary_c",   "#F0F0F0FF")
local background_secondary_c = handleColor("laby_background_secondary_c", "#D0D0D0FF")

local storage = minetest.get_mod_storage()
local current_level = storage:get_int("current_level") or 1
if current_level < 1 then current_level = 1 end -- just in case

-------------------
-- Main Menu and startup
-------------------
minetest.register_on_joinplayer(function(player)
    -- Show off little Lady!
    player:set_properties({
        mesh = "lady_assets_littlelady.obj",
        textures = {"lady_assets_ladybug.png"},
        visual = "mesh",
        visual_size = {x = 1, y = 1},
        collisionbox = {-0.24, 0.0, -0.26, 0.24, 1, 0.26},
        stepheight = 0.55,
        eye_height = 1,
    })
    -- Turn off builtin crap
    player:hud_set_flags(
        {
            hotbar = false,
            healthbar = false,
            crosshair = false,
            wielditem = false,
            breathbar = false,
            minimap = false,
            minimap_radar = false,
        }
    )
--  1. Turn off player gravity and stop them from falling
    player:set_physics_override(
        {
            speed = 0.0,
            jump = 0.0,
            gravity = 0.0,
            sneak = false,
        }
    )
--  2. Change the player's "I" in-game menu to quit to main menu, reset, quit, and credits
    player:set_inventory_formspec(table.concat(
        {
            "formspec_version[3]",
            "size[8,8]",
            "position[0.5,0.5]",
            "anchor[0.5,0.5]",
            "no_prepend[]",
            "bgcolor[",background_primary_c,";both;#AAAAAA40]",
            "style_type[button;border=false;bgimg=back.png^[multiply:",primary_c,";bgimg_middle=10,10;textcolor=",on_primary_c,"]",
            "style_type[button:hovered;bgimg=back.png^[multiply:",hover_primary_c,";bgcolor=#FFF]",
            "button_exit[0.6,0.5;6.8,1;menu;Quit to Menu]",
            "button_exit[0.6,2;6.8,1;reset;Reset to start]",
            "hypertext[2,3.5;4,4.25;;<global halign=center color=",primary_c," size=32 font=Regular>Credits<global halign=center color=",on_secondary_c," size=16 font=Regular>\n",
            "Original Game by ExeVirus\n",
            "Source code is MIT License, 2021\n",
            "Media/Music is:\nCC-BY-SA, ExeVirus 2021\n",
            "Music coming soon to Spotify and other streaming services!]",
        }
    ))
-- 3. Display the main Menu
    minetest.show_formspec(player:get_player_name(),"menu",main_menu())
-- 4. Play the main menu music
    play_music("theme")
end)

-- Function display_main_menu()
main_menu = function(scroll_in)
    local scroll = scroll_in or 0
    local r =  {
        "formspec_version[3]",
        "size[11,11]",
        "position[0.5,0.5]",
        "anchor[0.5,0.5]",
        "no_prepend[]",
        "bgcolor[",background_primary_c,";both;#AAAAAA40]",
        "box[0,0;11,1;",primary_c,"]",
        "style_type[button;border=false;bgimg=back.png^[multiply:",secondary_c,";bgimg_middle=10,3;textcolor=",on_secondary_c,"]",
        "style_type[button:hovered;bgcolor=",hover_secondary_c,"]",
        "hypertext[1,0.08;9,5;;<global halign=center color=",on_primary_c," size=36 font=Regular>Little Lady]",
        "button[7.5,0.15;3.3,0.7;exit;Quit Little Lady]",
        "box[3.4,1.9;4.2,8.2;",background_secondary_c,"]",
        "scroll_container[3.5,2;4,8;scroll;vertical;0.2]",
    }
    for i=1, #levels, 1 do
        if i <= current_level then
            table.insert(r,"image_button[1.1,".. (i-1)*2+0.1 ..";1.8,1.8;"..levels[i].image..".png;level"..i..";"..levels[i].name.."]")
        else
            table.insert(r,"image[1.1,".. (i-1)*2+0.1 ..";1.8,1.8;"..levels[i].image..".png^[colorize:#000:170]")
        end
    end
    table.insert(r,"scroll_container_end[]")
    table.insert(r,"scrollbaroptions[max="..tostring((#levels - 5) * 10)..";thumbsize="..tostring((#levels - 5) * 2.5).."]")
    table.insert(r,"scrollbar[7.6,1.9;0.5,8.2;vertical;scroll;"..tostring(scroll).."]")
    return table.concat(r)
end

-------------------
--On receive
-------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "menu" then
        if fields.scroll then
            scroll_in = tonumber(minetest.explode_scrollbar_event(fields.scroll).value)
        end
            --Loop through all fields for level selected
        for fieldtext,_ in pairs(fields) do
            if string.sub(fieldtext,1,5) == "level" then
                loaded_level = tonumber(string.sub(fieldtext,6,-1))
                if levels[loaded_level] ~= nil and loaded_level <= current_level then
                    load_level(player)
                    minetest.close_formspec(player:get_player_name(),"menu")
                else
                    loaded_level = nil
                end
            end
        end
        if fields.quit then
            minetest.after(0.10, function() minetest.show_formspec(player:get_player_name(), "menu", main_menu(scroll_in)) end)
            return
        elseif fields.exit then
            minetest.request_shutdown("Thanks for playing!")
            return
        else
            --minetest.show_formspec(player:get_player_name(), "game:main", main_menu(width_in, height_in, scroll_in))
        end
    elseif formname == "" then --pause menu
        if fields.menu then
            unload_level(loaded_level)
        elseif fields.reset then
            reset_player(player)
        end
    end  
end)


load_level = function(player)
    stars_collected = 0 
    
    --  1. Show HUD element that shows loading
    HUD.loading_back = player:hud_add({
        hud_elem_type = "image",
        position  = {x = 0.5, y = 0.5},
        offset    = {x = 0, y = 0},
        text      = "back.png",
        scale     = { x = 100, y = 100},
        alignment = { x = 0, y = 0 },
    })

    HUD.loading_text = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 0.5, y = 0.8},
        offset    = {x = 0, y = 0},
        text      = "Loading...",
        scale     = { x = 100, y = 100},
        alignment = { x = 0, y = 0 },
        number = tonumber(primary_c),
        size = {x=5}
    })
    --  1. Load schematic <num>.mts at 0,0,0 position
    minetest.place_schematic( {x=0,y=0,z=0}, levels[loaded_level].scheme, "random", {}, true, nil)
    --  2. Show formspec to read while loading
    --minetest.show_formspec(player:get_player_name(),"level",levels[loaded_level].formspec)
    --  3. Wait an arbitrary amount of time, say 4 seconds (for now)
    minetest.after(1, function(player)
        player:hud_remove(HUD.loading_back)
        player:hud_remove(HUD.loading_text)
    end, player)
    --  4. Update Star part of HUD overlay, then Remove HUD overlay. 
    --  5. When finished loading, move player into position "start", and set player physics
    --  6. Enable Globalstep for water drowning and to update the hud timer (time since start)
end

win_level = function()
    -- 0. Update player meta to note current level completion number (1-99 etc)
    -- 1. Show Win Formspec message
    -- 2. Unload Level function
end

unload_level = function()
    globalsteps_enabled = false
    -- 0. Remove star HUD 
    -- 1. Show HUD "unloading level..." message
    -- 2. Unload current level
    -- 3. Show Main Menu
end

minetest.register_globalstep(function(dtime)
    if globalsteps_enabled then 
        -- When player is inside a star, remove the star, make a sound, increment the star counter, and if enough stars have been collected, win_level
        -- When the player is inside water, they drown and reset_player()
    end
end)

