-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
local zen_mode = -1
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

beautiful.notification_icon_size = 0

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/clock/.config/awesome/theme.modus.lua")
-- beautiful.init("/home/clock/.config/awesome/theme.gruvbox.lua")
-- beautiful.init("/home/clock/.config/awesome/theme.light-blue.lua")
-- beautiful.init("/home/clock/.config/awesome/theme.tomorrow-night.lua")
-- beautiful.init("/home/clock/.config/awesome/theme.void.lua")
-- beautiful.init("/home/clock/.config/awesome/theme.dark-red.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.fair,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock(" %a %d %b %H:%M ")

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    gears.wallpaper.maximized("/home/clock/images/lisp-wall-light.png", s)
    -- gears.wallpaper.maximized("/home/clock/images/lisp-wall-dark.png", s)
    -- gears.wallpaper.maximized("/home/clock/.config/awesome/backgrounds/pent-blue.png", s)
    -- gears.wallpaper.maximized("/usr/share/backgrounds/mate/desktop/Ubuntu-Mate-Cold-no-logo.png", s)
    -- gears.wallpaper.centered("/home/clock/images/void-stars-2.png", s)
    -- gears.wallpaper.centered("/home/clock/images/fractured.png", s)
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create a battery status widget
    local battery_status = wibox.widget {
        widget = wibox.widget.textbox
    }

   gears.timer {
       timeout = 12,
       call_now = true,
       autostart = true,
       callback = function()
           awful.spawn.easy_async("battery-status", function(stdout)
               battery_status:set_text(stdout)
           end)
       end
   }

    -- Create a network status widget
    local wlan_ssid = wibox.widget {
        widget = wibox.widget.textbox
    }

   gears.timer {
       timeout = 12,
       call_now = true,
       autostart = true,
       callback = function()
           awful.spawn.easy_async("wlan-ssid", function(stdout)
               wlan_ssid:set_text(stdout)
           end)
       end
   }

    -- Create a vpn status widget
    local vpn_status = wibox.widget {
        widget = wibox.widget.textbox
    }

   gears.timer {
       timeout = 12,
       call_now = true,
       autostart = true,
       callback = function()
           awful.spawn.easy_async("vpn-status", function(stdout)
               vpn_status:set_text(stdout)
           end)
       end
   }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            -- s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            battery_status,
            wlan_ssid,
            vpn_status,
            mytextclock,
        },
    }

end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    -- awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey, "Shift"   }, "c", function () awful.spawn("emacsclient ~/.config/awesome/rc.lua") end,
              {description="Edit config", group="awesome"}),
    -- awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
    --           {description = "view previous", group = "tag"}),
    -- awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
    --           {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    awful.key({ modkey, "Control" }, "z",
       function ()
          if zen_mode == -1 then
             for i,v in ipairs(awful.screen.focused().tags) do v:delete() end
             zen_mode = 1
          else
             for i,v in ipairs(awful.screen.focused().tags) do v:delete() end
             awful.tag({ "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
             zen_mode = -1
          end
       end,
       {description = "Toggle zen mode", group = "awesome"}
    ),
    -- Layout manipulation
    awful.key({ modkey, "Control" }, "h", function () awful.client.swap.global_bydirection("left") end,
              {description = "swap with client leftwards", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.client.swap.global_bydirection("down") end,
              {description = "swap with client downwards", group = "client"}),
    awful.key({ modkey, "Control" }, "k", function () awful.client.swap.global_bydirection("up") end,
              {description = "swap with client upwards", group = "client"}),
    awful.key({ modkey, "Control" }, "l", function () awful.client.swap.global_bydirection("right") end,
              {description = "swap with client rightwards", group = "client"}),
    awful.key({ modkey, "Shift" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Shift" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab", function () awful.spawn("rofi -show window") end,
              {description = "Window Switcher", group = "launcher"}),

    awful.key({ modkey, "Shift" }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey,           }, "v", function () awful.spawn("urxvtc -e alsamixer") end,
              {description = "Volume Control", group = "launcher"}),
    awful.key({ modkey,           }, "x", function () awful.spawn("urxvtc -e htop") end,
              {description = "Open htop", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "r", function () awful.spawn("rex") end,
    -- awful.key({ modkey, "Shift"   }, "r", function () awful.spawn("emacs") end,
              {description = "Start Rex", group = "launcher"}),
    awful.key({ modkey,           }, "f", function () awful.spawn("rex-client-frame") end,
    -- awful.key({ modkey,           }, "f", function () awful.spawn("emacsclient -cna ''") end,
              {description = "Start Emacs", group = "launcher"}),
    awful.key({ modkey,           }, "e", function () awful.spawn("rofi-finder") end,
              {description = "Rofi", group = "launcher"}),
    awful.key({ modkey,           }, "b", function () awful.spawn("firefox") end,
              {description = "Start Firefox", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "d", function () awful.spawn("firefox http://m.dict.cc/") end,
              {description = "dict.cc", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "s", function () awful.spawn("fullscreen-snapshot") end,
              {description = "Screenshot", group = "launcher"}),
    awful.key({ modkey, "Control" }, "s", function () awful.spawn("window-snapshot") end,
              {description = "Screenshot current window", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Control" }, "Delete", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next layout", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous layout", group = "layout"}),

    awful.key({ modkey, "Shift"   }, "l", function () naughty.notify{text=awful.layout.getname(), "Current Layout", 0.2}     end,
              {description = "Show current layout", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    awful.key({ modkey },            "r",     function () awful.util.spawn_with_shell("dr") end,
              {description = "run prompt", group = "launcher"}),

    -- awful.key({ modkey }, "x",
    --           function ()
    --               awful.prompt.run {
    --                 prompt       = "Run Lua code: ",
    --                 textbox      = awful.screen.focused().mypromptbox.widget,
    --                 exe_callback = awful.util.eval,
    --                 history_path = awful.util.get_cache_dir() .. "/history_eval"
    --               }
    --           end,
    --           {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = gears.table.join(

    awful.key({ modkey, "Shift"   }, "Right", function (c) c:relative_move(0, 0, 10, 0) end,
              {description = "grow rightwards", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Left", function (c) c:relative_move(0, 0, -10, 0) end,
              {description = "shrink leftwards", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Up", function (c) c:relative_move(0, 0, 0, -10) end,
              {description = "grow downwards", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Down", function (c) c:relative_move(0, 0, 0, 10) end,
              {description = "shrink upwards", group = "client"}),

    awful.key({ modkey,           }, "Right", function (c) c:relative_move(10, 0, 0, 0) end,
              {description = "move rightwards", group = "client"}),
    awful.key({ modkey,           }, "Left", function (c) c:relative_move(-10, 0, 0, 0) end,
              {description = "move leftwards", group = "client"}),
    awful.key({ modkey,           }, "Up", function (c) c:relative_move(0, -10, 0, 0) end,
              {description = "move upwards", group = "client"}),
    awful.key({ modkey,           }, "Down", function (c) c:relative_move(0, 10, 0, 0) end,
              {description = "move downwards", group = "client"}),

    awful.key({ modkey, "Shift"   }, "c", awful.placement.centered,
              {description = "move downwards", group = "client"}),

    awful.key({ modkey, "Control" }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    -- awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
    --           {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     -- focus = false,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     maximized_horizontal = false,
                     maximized_vertical = false,
                     maximized = false,
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "pinentry",
        },
        class = {
          "Arandr",
          "Kruler",
        },

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
        }
      }, properties = { floating = true }},

    -- don't steal focus
    { rule_any = {
         class = {
            "Steam"
         }
    }, properties = { focus = false }},

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    c.size_hints_honor = false
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
-- Autostart
autorun = true
autorunApps = {
    "start"
}
if autorun then
    for app = 1, #autorunApps do
        awful.util.spawn(autorunApps[app])
    end
end
