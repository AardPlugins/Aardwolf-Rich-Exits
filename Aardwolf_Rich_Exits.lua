dofile(GetInfo(60) .. "aardwolf_colors.lua")

require "aardwolf_colors"
require "themed_miniwindows"

--
-- Variables
--

room_id = 0
room_name = ""
exits = {}
cexits = {}

cexit_max_length_var_name = "exits_var_draw_cexit_max_length"
draw_underline_var_name = "exits_var_draw_underline"
cexit_multiline_var_name = "exits_var_cexit_multiline"
cexit_trim_commmon_var_name = "exits_var_cexit_trim_commmon"
exits_after_fight_var_name = "exits_var_exits_after_fight"
show_window_var_name = "exits_var_show_window"
debug_mode_var_name = "exits_var_debug_mode"

cexit_north_var_name = "exits_var_cexit_north"
cexit_east_var_name = "exits_var_cexit_east"
cexit_south_var_name = "exits_var_cexit_south"
cexit_west_var_name = "exits_var_cexit_west"
cexit_up_var_name = "exits_var_cexit_up"
cexit_down_var_name = "exits_var_cexit_down"

cexit_max_length = tonumber(GetVariable(cexit_max_length_var_name)) or -1
draw_underline = tonumber(GetVariable(draw_underline_var_name)) or 1
cexit_multiline = tonumber(GetVariable(cexit_multiline_var_name)) or 0
cexit_trim_commmon = tonumber(GetVariable(cexit_trim_commmon_var_name)) or 0
exits_after_fight = tonumber(GetVariable(exits_after_fight_var_name)) or 0
show_window = tonumber(GetVariable(show_window_var_name)) or 1
debug_mode = tonumber(GetVariable(debug_mode_var_name)) or 0

cexit_north = GetVariable(cexit_north_var_name) or "open north;north"
cexit_east = GetVariable(cexit_east_var_name) or "open east;east"
cexit_south = GetVariable(cexit_south_var_name) or "open south;south"
cexit_west = GetVariable(cexit_west_var_name) or "open west;west"
cexit_up = GetVariable(cexit_up_var_name) or "open up;up"
cexit_down = GetVariable(cexit_down_var_name) or "open down;down"

local character_state = -1

--
-- Plugin Methods
--

local plugin_id_gmcp_handler = "3e7dedbe37e44942dd46d264"
local plugin_id_gmcp_mapper = "b6eae87ccedd84f510b74714"

function OnPluginBroadcast(msg, id, name, text)
    if (id == plugin_id_gmcp_handler) then
        if (text == "room.info") then
            on_room_info_update(gmcp("room.info"))
        elseif (text == "char.status") then
            on_character_status_update(gmcp("char.status"))
        end
    end
end

function OnPluginInstall()
    init_plugin()
end

function OnPluginConnect()
    init_plugin()
end

function OnPluginEnable()
    init_plugin()
end

function init_plugin()
    if not IsConnected() then
        return
    end

    -- Wait until tags can be called
    local current_state = gmcp("char.status.state")
    if ((current_state ~= "3") and (current_state ~= "8") and (current_state ~= "9") and (current_state ~= "11")) then
        return
    end

    EnableTimer("timer_init_plugin", false)
    Message("Enabled Plugin")
    SendNoEcho("tags exits on")
    on_room_info_update(gmcp("room.info"))
    on_character_status_update(gmcp("char.status"))

    create_window()
end

function gmcp(s)
    local ret, datastring = CallPlugin(plugin_id_gmcp_handler, "gmcpdata_as_string", s)
    pcall(loadstring("data = " .. datastring))
    return data
end

--
-- Help & Options
--

function alias_help(name, line, wildcards)
    Message([[@WCommands:@w

  @Wrexit help                 @w- Print out this help message
  @Wrexit update               @w- Updates to the latest version of the plugin
  @Wrexit reload               @w- Reloads the plugin
  @Wrexit reset window         @w- Resets the window to its default position
  @Wrexit options              @w- Print out the plugin options
  @Wrexit set maxlength @Ylength @w- Sets the maximum length of the cexit name to display, set to -1 to show all
  @Wrexit set window           @w- Toggles displaying the window
  @Wrexit set underline        @w- Toggles displaying an underline in the hyperlinks
  @Wrexit set multiline        @w- Toggles displaying cexits on their own line
  @Wrexit set exitsafterfight  @w- Toggles displaying the exits after a fight
  @Wrexit set trimcommon       @w- Trims common words like say and enter from cexit names
  @Wrexit set cexit @Ydir cmd    @w- Set door opening cexit command for standard cardinal directions
  @Wcexit @Yindex                @w- Executes the cexit command based on index

  @Wrexit debug                @w- Toggles debug logs
  @Wrexit force update @Ybranch  @w- Force updates to the branch specified]])
end

function alias_options(name, line, wildcards)
    local options_show_window = "@RNo"
    if show_window == 1 then
        options_show_window = "@GYes"
    elseif show_window == nil then
        options_show_window = "@RNil"
    end

    local options_draw_underline = "@RNo"
    if draw_underline == 1 then
        options_draw_underline = "@GYes"
    elseif draw_underline == nil then
        options_draw_underline = "@RNil"
    end

    local options_cexit_multiline = "@RNo"
    if cexit_multiline == 1 then
        options_cexit_multiline = "@GYes"
    elseif cexit_multiline == nil then
        options_cexit_multiline = "@RNil"
    end

    local options_cexit_trim_commmon = "@RNo"
    if cexit_trim_commmon == 1 then
        options_cexit_trim_commmon = "@GYes"
    elseif cexit_trim_commmon == nil then
        options_cexit_trim_commmon = "@RNil"
    end

    local options_exits_after_fight = "@RNo"
    if exits_after_fight == 1 then
        options_exits_after_fight = "@GYes"
    elseif exits_after_fight == nil then
        options_exits_after_fight = "@RNil"
    end

    Message(string.format([[@WCurrent options:@w

  @WCexit Max Length:  @w(%s@w)
  @WShow Window:       @w(%s@w)
  @WUnderline:         @w(%s@w)
  @WMultiline:         @w(%s@w)
  @WTrim common:       @w(%s@w)
  @WExits after Fight: @w(%s@w)
  @WNorth Cexit:       @w(%s@w)
  @WEast Cexit:        @w(%s@w)
  @WSouth Cexit:       @w(%s@w)
  @WWest Cexit:        @w(%s@w)
  @WUp Cexit:          @w(%s@w)
  @WDown Cexit:        @w(%s@w)]],
    cexit_max_length,
    options_show_window,
    options_draw_underline,
    options_cexit_multiline,
    options_cexit_trim_commmon,
    options_exits_after_fight,
    cexit_north,
    cexit_east,
    cexit_south,
    cexit_west,
    cexit_up,
    cexit_down))
end

function alias_set_show_window(name, line, wildcards)
    local new_show_window = -1

    if show_window == 1 then
        new_show_window = 0
    else
        new_show_window = 1
    end

    SetVariable(show_window_var_name, new_show_window)
    show_window = new_show_window

    if new_show_window == 0 then
        Message("@WDisabling the window")
        if my_window ~= nil then
            my_window:delete()
            my_window = nil
        end
    else
        Message("@WEnabling the window")
        create_window()
        draw_window()
    end
end

function alias_set_draw_underline(name, line, wildcards)
    local new_draw_underline = -1

    if draw_underline == 1 then
        new_draw_underline = 0
    else
        new_draw_underline = 1
    end

    if new_draw_underline == 0 then
        Message("@WExit hyperlinks will no longer have an underline")
    else
        Message("@WExit hyperlinks will now have an underline")
    end
    SetVariable(draw_underline_var_name, new_draw_underline)
    draw_underline = new_draw_underline
end

function alias_set_cexit_multiline(name, line, wildcards)
    local new_cexit_multiline = -1

    if cexit_multiline == 1 then
        new_cexit_multiline = 0
    else
        new_cexit_multiline = 1
    end

    if new_cexit_multiline == 0 then
        Message("@WCustom exits will now appear on same line as exits")
    else
        Message("@WCustom exits will now appear on their own line")
    end
    SetVariable(cexit_multiline_var_name, new_cexit_multiline)
    cexit_multiline = new_cexit_multiline
end

function alias_set_trim_common(name, line, wildcards)
    local new_cexit_trim_commmon = -1

    if cexit_trim_commmon == 1 then
        new_cexit_trim_commmon = 0
    else
        new_cexit_trim_commmon = 1
    end

    if new_cexit_trim_commmon == 0 then
        Message("@WNo longer removing common words from custom exits")
    else
        Message("@WCommon words will now be removed from custom exits")
    end
    SetVariable(cexit_trim_commmon_var_name, new_cexit_trim_commmon)
    cexit_trim_commmon = new_cexit_trim_commmon
end

function alias_set_exits_after_fight(name, line, wildcards)
    local new_exits_after_fight = -1

    if exits_after_fight == 1 then
        new_exits_after_fight = 0
    else
        new_exits_after_fight = 1
    end

    if new_exits_after_fight == 0 then
        Message("@WNo longer printing exits after a fight")
    else
        Message("@WExits will now be printed after a fight")
    end
    SetVariable(exits_after_fight_var_name, new_exits_after_fight)
    exits_after_fight = new_exits_after_fight
end

function alias_set_debug_mode(name, line, wildcards)
    local new_debug_mode = -1

    if debug_mode == 1 then
        new_debug_mode = 0
    else
        new_debug_mode = 1
    end

    if new_debug_mode == 0 then
        Message("@WDisabled debug logs")
    else
        Message("@WEnabled debug logs")
    end
    SetVariable(debug_mode_var_name, new_debug_mode)
    debug_mode = new_debug_mode
end

function alias_set_max_length(name, line, wildcards)
    local new_max_length = tonumber(Trim(wildcards.max_length))
    if new_max_length == nil or new_max_length == 0 then
        Message("@WYou must specify a valid length.")
        return
    end

    if new_max_length < 0 then
        new_max_length = -1
        Message("@WThe full cexit name will now be displayed")
    else
        Message("@WCexit names will now automatically be truncated to @Y" .. new_max_length .. " @Wcharacters")
    end
    SetVariable(cexit_max_length_var_name, new_max_length)
    cexit_max_length = new_max_length
end

function alias_set_cexit_dir(name, line, wildcards)
    local dir = string.lower(wildcards.dir)
    local cmd = Trim(wildcards.cmd)

    if dir == "north" then
        SetVariable(cexit_north_var_name, cmd)
        cexit_north = cmd
    elseif dir == "east" then
        SetVariable(cexit_east_var_name, cmd)
        cexit_east = cmd
    elseif dir == "south" then
        SetVariable(cexit_south_var_name, cmd)
        cexit_south = cmd
    elseif dir == "west" then
        SetVariable(cexit_west_var_name, cmd)
        cexit_west = cmd
    elseif dir == "up" then
        SetVariable(cexit_up_var_name, cmd)
        cexit_up = cmd
    elseif dir == "down" then
        SetVariable(cexit_down_var_name, cmd)
        cexit_down = cmd
    else
        Message("@WInvalid direction")
        return
    end

    Message("@Y" .. dir .. " @Wcexit is now set to (@Y" .. cmd .. "@W)")
end

--
-- Main Code
--

function alias_cexit(name, line, wildcards)
    local index = tonumber(wildcards.index)
    local cexit = cexits[index]
    if cexit == nil then
        Message("Custom exit not found with index " .. index)
        return
    end
    Execute(cexit.cmd)
end

function on_room_info_update(room_info)
    if room_info.exits == nil then
        room_id = 0
        room_name = ""
        exits = {}
        cexits = {}
        return
    end

    room_id = tonumber(room_info.num)
    room_name = room_info.name

    exits = {
        north = {
            cmd = "north",
            room_id = room_info.exits.n
        },
        east = {
            cmd = "east",
            room_id = room_info.exits.e
        },
        south = {
            cmd = "south",
            room_id = room_info.exits.s
        },
        west = {
            cmd = "west",
            room_id = room_info.exits.w
        },
        up = {
            cmd = "up",
            room_id = room_info.exits.u
        },
        down = {
            cmd = "down",
            room_id = room_info.exits.d
        },
    }

    -- Read custom exits from mapper plugin
    cexits = {}

    local rc, room_cexits = CallPlugin(plugin_id_gmcp_mapper, "room_cexits", room_id)
    if (rc == error_code.eOK) then
        local room_cexits = loadstring(string.format("return %s", room_cexits))()
        if room_cexits ~= nil then
            for k, v in pairs(room_cexits) do
                if k == cexit_north then
                    exits.north.cmd = k
                elseif k == cexit_east then
                    exits.east.cmd = k
                elseif k == cexit_south then
                    exits.south.cmd = k
                elseif k == cexit_west then
                    exits.west.cmd = k
                elseif k == cexit_up then
                    exits.up.cmd = k
                elseif k == cexit_down then
                    exits.down.cmd = k
                else
                    table.insert(cexits, {
                        text = k,
                        cmd = k,
                        room_id = v
                    })
                end
            end
        end
    end
end

function trigger_exits(name, line, wildcards, style)
    display_exits()
    draw_window()
end

function display_exits()
    local no_underline = false
    if draw_underline == 0 then
        no_underline = true
    end

    local has_one_cardinal = false

    ColourTell("green", "", "[ Exits:")
    if exits.north.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.north.cmd, "north", "moves to " .. exits.north.room_id, "green", "", false, no_underline)
    end
    if exits.east.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.east.cmd, "east", "moves to " .. exits.east.room_id, "green", "", false, no_underline)
    end
    if exits.south.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.south.cmd, "south", "moves to " .. exits.south.room_id, "green", "", false, no_underline)
    end
    if exits.west.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.west.cmd, "west", "moves to " .. exits.west.room_id, "green", "", false, no_underline)
    end
    if exits.up.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.up.cmd, "up", "moves to " .. exits.up.room_id, "green", "", false, no_underline)
    end
    if exits.down.room_id ~= nil then
        has_one_cardinal = true
        ColourTell("green", "", " ")
        Hyperlink(exits.down.cmd, "down", "moves to " .. exits.down.room_id, "green", "", false, no_underline)
    end

    if cexit_multiline == 1 then
        if not has_one_cardinal then
            ColourTell("green", "", " none")
        end
        ColourTell("green", "", " ]")
        Note()
        if #cexits > 0 then
            ColourTell("green", "", "[ Cexits:")
        else
            Note()
            return
        end
    end

    for i, cexit in ipairs(cexits) do
        ColourTell("green", "", " ")
        local text = cexit.text

        if cexit_trim_commmon == 1 then
            text = string.gsub(text, "^enter ", "")
            text = string.gsub(text, "^say ", "")
        end

        if cexit_max_length > 0 then
            text = string.sub(text, 1, cexit_max_length)
        end
        if text:match("%s") then
            text = "'" .. text .. "'"
        end
        local hint = "'" .. cexit.text .. "' moves to " .. cexit.room_id
        Hyperlink(cexit.cmd, text, hint, "green", "", false, no_underline)
    end

    if not has_one_cardinal and #cexits <= 0 then
        ColourTell("green", "", " none")
    end

    ColourTell("green", "", " ]")
    Note()
    Note()
end

function on_character_status_update(status)
    -- handle state changes
    local previous_state = character_state
    character_state = tonumber(status.state)

    if previous_state ~= character_state and previous_state ~= -1 then
        on_character_state_change(previous_state, character_state)
    end
end

function on_character_state_change(previous_state, new_state)
    if previous_state == 8 and new_state ~= 8 then
        -- exiting fighting state
        if exits_after_fight == 1 then
            Note()
            ColourNote("green", "", room_name)
            Note()
            display_exits()
        end
    end
end


--
-- Window methods
--

default_window_width = 400
default_window_height = 50
my_window = nil

function alias_reset_window(name, line, wildcards)
    if show_window == 0 or my_window == nil then
        Error("Window is not enabled")
        return
    end

    my_window:reset()

    -- Make sure it isn't behind any other miniwindows.
    my_window:bring_to_front()
end

function create_window()
    if show_window == 0 then
        return
    end

    my_window = ThemedTextWindow(
        GetPluginID(),  -- id
        (GetInfo(281)-default_window_width)/2,  -- default_left_position
        (GetInfo(280)-default_window_height)/2,  -- default_top_position
        default_window_width,  -- default_width
        default_window_height,  -- default_height
        "Rich Exits",  -- title
        "center",  -- title alignment
        false,  -- is_temporary (closeable)
        true,  -- resizeable
        false,  -- text_scrollable
        false,  -- text_selectable
        false,  -- text_copyable
        true,  -- url_hyperlinks
        true,  -- autowrap
        nil,  -- title_font_name
        6,  -- title_font_size
        GetAlphaOption("output_font_name"), -- text_font_name
        GetOption("output_font_height"),  -- text_font_size
        3,  -- text_max_lines
        nil,  -- text_padding
        false,  -- defer_showing
        false -- body_is_transparent
    )

    -- Make sure it isn't behind any other miniwindows.
    my_window:bring_to_front()
end

function draw_window()
    if show_window == 0 or my_window == nil then
        return
    end

    my_window:clear(false)

    text = "@g"
    links = {}

    local has_one_cardinal = false

    if exits.north.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.north.room_id,
            start=#text - 1,
            stop=#text + 3,
            text="Execute(\"" .. exits.north.cmd .. "\")"
        })
        text = text .. "north "
    end
    if exits.east.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.east.room_id,
            start=#text - 1,
            stop=#text + 2,
            text="Execute(\"" .. exits.east.cmd .. "\")"
        })
        text = text .. "east "
    end
    if exits.south.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.south.room_id,
            start=#text - 1,
            stop=#text + 3,
            text="Execute(\"" .. exits.south.cmd .. "\")"
        })
        text = text .. "south "
    end
    if exits.west.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.west.room_id,
            start=#text - 1,
            stop=#text + 2,
            text="Execute(\"" .. exits.west.cmd .. "\")"
        })
        text = text .. "west "
    end
    if exits.up.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.up.room_id,
            start=#text - 1,
            stop=#text,
            text="Execute(\"" .. exits.up.cmd .. "\")"
        })
        text = text .. "up "
    end
    if exits.down.room_id ~= nil then
        has_one_cardinal = true
        table.insert(links, {
            label="moves to " .. exits.down.room_id,
            start=#text - 1,
            stop=#text + 2,
            text="Execute(\"" .. exits.down.cmd .. "\")"
        })
        text = text .. "down "
    end

    for i, cexit in ipairs(cexits) do
        local ctext = cexit.text

        if cexit_trim_commmon == 1 then
            ctext = string.gsub(ctext, "^enter ", "")
            ctext = string.gsub(ctext, "^say ", "")
        end

        if cexit_max_length > 0 then
            ctext = string.sub(ctext, 1, cexit_max_length)
        end
        if ctext:match("%s") then
            ctext = "'" .. ctext .. "'"
        end
        local hint = "'" .. cexit.text .. "' moves to " .. cexit.room_id

        table.insert(links, {
            label=hint,
            start=#text - 1,
            stop=#text + #ctext - 2,
            text="Execute(\"" .. cexit.cmd .. "\")"
        })
        text = text .. ctext .. " "
    end

    if not has_one_cardinal and #cexits <= 0 then
        text = text .. " none"
    end

    my_window:add_text(text, false, links)

    -- I used the defer_showing flag, so now I have to show the window.
    my_window:show()
end

--
-- Print methods
--

function Message(str)
    AnsiNote(stylesToANSI(ColoursToStyles(string.format("\n@C[@GExits@C] %s@w\n", str))))
end

function Debug(str)
    if debug_mode == 1 then
        Message(string.format("@gDEBUG@w %s", str))
    end
end

function Error(str)
    Message(string.format("@RERROR@w %s", str))
end

--
-- Update code
--

async = require "async"

local version_url = "https://raw.githubusercontent.com/AardPlugins/Aardwolf-Rich-Exits/refs/heads/main/VERSION"
local plugin_base_url = "https://raw.githubusercontent.com/AardPlugins/Aardwolf-Rich-Exits/refs"
local plugin_files = {
    {
        remote_file = "Aardwolf_Rich_Exits.xml",
        local_file =  GetPluginInfo(GetPluginID(), 6),
        update_page= ""
    },
    {
        remote_file = "Aardwolf_Rich_Exits.lua",
        local_file =  GetPluginInfo(GetPluginID(), 20) .. "Aardwolf_Rich_Exits.lua",
        update_page= ""
    }
}
local download_file_index = 0
local download_file_branch = ""
local plugin_version = GetPluginInfo(GetPluginID(), 19)

function download_file(url, callback)
    Debug("Starting download of " .. url)
    -- Add timestamp as a query parameter to bust cache
    url = url .. "?t=" .. GetInfo(304)
    async.doAsyncRemoteRequest(url, callback, "HTTPS")
end

function alias_reload_plugin(name, line, wildcards)
    Message("Reloading plugin")
    reload_plugin()
end

function alias_update_plugin(name, line, wildcards)
    Debug("Checking version to see if there is an update")
    download_file(version_url, check_version_callback)
end

function check_version_callback(retval, page, status, headers, full_status, request_url)
    if status ~= 200 then
        Error("Error while fetching latest version number")
        return
    end

    local upstream_version = Trim(page)
    if upstream_version == tostring(plugin_version) then
        Message("@WNo new updates available")
        return
    end

    Message("@WUpdating to version " .. upstream_version)

    local branch = "tags/v" .. upstream_version
    download_plugin(branch)
end

function alias_force_update_plugin(name, line, wildcards)
    local branch = "main"

    if wildcards.branch ~= "" then
        branch = wildcards.branch
    end

    Message("@WForcing updating to branch " .. branch)

    branch = "heads/" .. branch
    download_plugin(branch)
end

function download_plugin(branch)
    Debug("Downloading plugin branch " .. branch)
    download_file_index = 0
    download_file_branch = branch

    download_next_file()
end

function download_next_file()
    download_file_index = download_file_index + 1

    if download_file_index > #plugin_files then
        Debug("All plugin files downloaded")
        finish_update()
        return
    end

    local url = string.format("%s/%s/%s", plugin_base_url, download_file_branch, plugin_files[download_file_index].remote_file)
    download_file(url, download_file_callback)
end

function download_file_callback(retval, page, status, headers, full_status, request_url)
    if status ~= 200 then
        Error("Error while fetching the plugin")
        return
    end

    plugin_files[download_file_index].update_page = page

    download_next_file()
end

function finish_update()
    Message("@WUpdating plugin. Do not touch anything!")

    -- Write all downloaded files to disk
    for i, plugin_file in ipairs(plugin_files) do
        local file = io.open(plugin_file.local_file, "w")
        file:write(plugin_file.update_page)
        file:close()
    end

    reload_plugin()

    Message("@WUpdate complete!")
end

function reload_plugin()
    if GetAlphaOption("script_prefix") == "" then
        SetAlphaOption("script_prefix", "\\\\\\")
    end
    Execute(
        GetAlphaOption("script_prefix") .. 'DoAfterSpecial(0.5, "ReloadPlugin(\'' .. GetPluginID() .. '\')", sendto.script)'
    )
end
