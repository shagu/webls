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

    if not tbl then return txt end
    for name, _ in spairs(tbl) do
      txt = txt .. string.format(tpl, name, name)
    end
    return txt
  end,

  download = function(tbl)
    local txt = ""
    local tpl = '<a class="download" href="%s">%s</a>'
    if not tbl then return txt end
    for name, text in spairs(tbl) do
      txt = txt .. string.format(tpl, name, name)
    end
    return txt
  end,

  gallery = function(tbl)
    local txt = ""
    local tpl = '<a class="gallery" href="%s"><img class="gallery" src="%s"/><br/>%s</a>'
    if not tbl then return txt end
    for name, text in spairs(tbl) do
      txt = txt .. string.format(tpl, name, name, name:match("^(.+)%..+$"))
    end
    return txt
  end,

  content = function(tbl)
    local txt = ""
    local tpl = '<div id="%s" class="content">%s</div>'
    if not tbl then return txt end
    for name, text in spairs(tbl) do
      txt = txt .. string.format(tpl, name, markdown(text))
    end
    return txt
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
    html.content(content[path]),
    html.gallery(gallery[path]),
    html.download(download[path])
  ))

  file:close()
end
