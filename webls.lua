#!/bin/env lua
-- depends: lua-filesystem

local config = require("config")
local lfs = require("lfs")
local markdown = require("markdown/markdown")
local images = {
  [".png"] = true,
  [".jpg"] = true,
  [".jpeg"] = true,
  [".webp"] = true,
  [".gif"] = true,
}

local function empty(tbl)
  for _ in pairs(tbl) do
    return nil
  end

  return true
end

local function round(num)
  return math.floor(num * 100 + .5)/100
end

local function spairs(t, index, reverse)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  table.sort(keys)

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

local icons = {
  ["download"] = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M20.54 5.23l-1.39-1.68C18.88 3.21 18.47 3 18 3H6c-.47 0-.88.21-1.16.55L3.46 5.23C3.17 5.57 3 6.02 3 6.5V19c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6.5c0-.48-.17-.93-.46-1.27zM12 17.5L6.5 12H10v-2h4v2h3.5L12 17.5zM5.12 5l.81-1h12l.94 1H5.12z"/><path d="M0 0h24v24H0z" fill="none"/></svg>',
}

local html = {
  page = function()
    local file = io.open("template.html", "rb")
    local content = file:read("*all")
    file:close()
    return content
  end,

  navbar = function(tbl, path)
    local txt = ""
    local tpl = '<a href="%s/index.html">%s</a>'
    if path ~= "" then
      txt = txt .. '<a class="back" href="../index.html">« Back</a>'
    end

    if not tbl or empty(tbl) then return txt end
    for name, _ in spairs(tbl) do
      txt = txt .. string.format(tpl, name, name)
    end
    return txt
  end,

  download = function(tbl)
    local txt = '<div class="download">'
    local tpl = '<a class="download" href="%s">'..icons.download..'<span class="caption">%s <small>(%s)</small></span></a>'
    if not tbl or empty(tbl) then return "" end
    for name, text in spairs(tbl) do
      local size = lfs.attributes(config.scanpath .. text).size
      if size then
        size = size > 1048576 and round(size / 1048576) .. " MB" or size > 1024 and round(size / 1024) .. " KB" or size .. " B"
        txt = txt .. string.format(tpl, name, name, size)
      end
    end
    return txt .. '</div>'
  end,

  gallery = function(tbl)
    local txt = '<div class="gallery">'
    local tpl = '<a class="gallery" href="%s"><img class="gallery" src="%s"/><br/>%s</a>'
    if not tbl or empty(tbl) then return "" end
    for name, text in spairs(tbl) do
      txt = txt .. string.format(tpl, name, name, name:match("^(.+)%..+$"))
    end
    return txt .. "</div>"
  end,

  content = function(tbl)
    local txt = ""
    local tpl = '<div id="%s" class="text">%s</div>'
    if not tbl or empty(tbl) then return "" end
    for name, text in spairs(tbl) do
      txt = txt .. string.format(tpl, name, markdown(text))
    end
    return txt
  end,

  footer = function()
    return os.date("%B %Y")
  end
}

-- content cache
local navbar = {}
local content = {}
local gallery = {}
local download = {}
local ignored = {}

local function scan(path, ls)
  local ls = ls or {}
  if not path then path = "" end

  local md = nil

  for name in lfs.dir(config.scanpath .. "/" .. path) do
    if name ~= "." and name ~= ".." then
      local full = path..'/'..name
      local attr = lfs.attributes(config.scanpath .. "/" .. full)
      local file = attr.mode == "file" and true or nil
      local ext = not file and "folder" or full:match("^.+(%..+)$") or ""

      local file_in = config.scanpath.."/"..full
      local file_out = config.www.."/"..full
      local dir_in = config.scanpath.."/"..path
      local dir_out = config.www.."/"..path

      lfs.mkdir(dir_out)
      ls[path] = full

      if ext == "folder" then
        local _, md = scan(full, ls)
        -- only create navbar entry when markdown is found
        if md then
          navbar[path] = navbar[path] or {}
          navbar[path][name] = full
        end
      elseif ext == ".md" then
        local file = io.open(file_in, "rb")
        content[path] = content[path] or {}
        content[path][name] = file:read("*all")
        file:close()
        md = true
      else
        if images[ext] then
          gallery[path] = gallery[path] or {}
           gallery[path][name] = full
        else
          download[path] = download[path] or {}
          download[path][name] = full
        end
        lfs.link(file_in, file_out)
      end
    end
  end

  return ls, md
end

-- create output directory if not yet existing
if not lfs.attributes(config.www) then
  lfs.mkdir(config.www)
end

-- iterate over all paths in content directory
for path in pairs(scan()) do
  -- keep all contents sorted
  table.sort(content)

  -- write new html files for each path
  local file = io.open(config.www .. path .. "/index.html", "w")
  file:write(string.format(html.page(), config.title, config.description,
    html.navbar(navbar[path], path),
    html.content(content[path]) .. html.gallery(gallery[path]) .. html.download(download[path]),
    html.footer()
  ))

  file:close()
end
