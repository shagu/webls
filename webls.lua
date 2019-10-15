#!/bin/env lua
-- depends: lua-filesystem

local config = require("config")
local lfs = require("lfs")
local markdown = require("markdown/markdown")

-- core functions
local function strsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[#fields+1] = c end)
  return unpack(fields)
end

local function strrepeat(str, count)
  local txt = ""
  for i=1,count do
    txt = txt .. str
  end

  return txt
end

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

-- elements
local icons = {
  ["download"] = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M20.54 5.23l-1.39-1.68C18.88 3.21 18.47 3 18 3H6c-.47 0-.88.21-1.16.55L3.46 5.23C3.17 5.57 3 6.02 3 6.5V19c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6.5c0-.48-.17-.93-.46-1.27zM12 17.5L6.5 12H10v-2h4v2h3.5L12 17.5zM5.12 5l.81-1h12l.94 1H5.12z"/><path d="M0 0h24v24H0z" fill="none"/></svg>',
}

local parser = {
  ["footer"] = {
    extensions = {},
    build = function()
      return string.format('<div class="footer">%s - powered by <a href="https://gitlab.com/shagu/webls">webls</a></div>', os.date("%B %Y"))
    end
  },

  ["markdown"] = {
    extensions = { ".md", ".txt" },
    prepare = function(self, path, name, fin, fout)
      local file = io.open(fin, "rb")
      self.cache = self.cache or {}
      self.cache[path] = self.cache[path] or {}
      self.cache[path][name]= file:read("*all")
      file:close()
    end,

    build = function(self, path)
      local txt = ""
      local tpl = '<div id="%s" class="text">%s</div>'
      if not self.cache[path] or empty(self.cache[path]) then return "" end

      for name, text in spairs(self.cache[path]) do
        txt = txt .. string.format(tpl, name, markdown(text))
      end
      return txt
    end
  },

  ["gallery"] = {
    extensions = { ".png", ".jpg", ".jpeg", ".webp", ".gif" },
    prepare = function(self, path, name, fin, fout)
      self.cache = self.cache or {}
      self.cache[path] = self.cache[path] or {}
      self.cache[path][name] = path..'/'..name
      lfs.link(fin, fout)
    end,

    build = function(self, path)
      local txt = '<div class="gallery">'
      local tpl = '<a href="%s"><img src="%s"/><span>%s</span></a>'
      if not self.cache[path] or empty(self.cache[path]) then return "" end

      for name, text in spairs(self.cache[path]) do
        txt = txt .. string.format(tpl, name, name, name:match("^(.+)%..+$"))
      end
      return txt .. "</div>"
    end
  },

  ["download"] = {
    extensions = { ".tar", ".gz", ".bz2", ".xz", ".zip", ".rar" },
    prepare = function(self, path, name, fin, fout)
      self.cache = self.cache or {}
      self.cache[path] = self.cache[path] or {}
      self.cache[path][name] = path..'/'..name
      lfs.link(fin, fout)
    end,

    build = function(self, path)
      local txt = '<div class="download">'
      local tpl = '<a href="%s">'..icons.download..'<span>%s <small>(%s)</small></span></a>'
      if not self.cache[path] or empty(self.cache[path]) then return "" end

      for name, text in spairs(self.cache[path]) do
        local size = lfs.attributes(config.scanpath .. text).size
        if size then
          size = size > 1048576 and round(size / 1048576) .. " MB" or size > 1024 and round(size / 1024) .. " KB" or size .. " B"
          txt = txt .. string.format(tpl, name, name, size)
        end
      end
      return txt .. '</div>'
    end
  },
}

-- content cache
local folders = {}
local function scan(path, ls)
  local ls = ls or {}
  if not path then path = "" end

  local valid = nil

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
        local _, valid = scan(full, ls)
        if valid then
          folders[path] = folders[path] or {}
          folders[path][name] = full
        end
      end

      for _, m in pairs(config.modules) do
        if not parser[m] then -- throw error on non-existing module
          print(string.format('ERROR: module "%s" could not be found. Check your configuration file', m))
          return
        else
          -- check for compatible parsers based on extension
          for _, mext in pairs(parser[m].extensions) do
            if ext == mext then
              parser[m]:prepare(path, name, file_in, file_out)
              valid = true
            end
          end
        end
      end
    end
  end

  return ls, valid
end

-- create output directory if not yet existing
if not lfs.attributes(config.www) then
  lfs.mkdir(config.www)
end

-- iterate over all paths in content directory
for path in pairs(scan()) do
  -- load template layout
  local file = io.open("template.html", "rb")
  local template = file:read("*all")
  file:close()

  -- load all content modules
  local page = ""
  for _, m in pairs(config.modules) do
    page = page .. parser[m]:build(path)
  end

  -- load sidebar
  local sidebar = path == "" and "" or '<a class="back" href="../index.html">« Back</a>'
  if folders[path] and not empty(folders[path]) then
    for name, _ in spairs(folders[path]) do
      sidebar = sidebar .. string.format('<a href="%s/index.html">%s</a>', name, name)
    end
  end

  -- load navbar
  local navbar = path == "" and "" or '<div class="navigation">'
  local elements = { strsplit('/', path) }
  local max = #elements
  for i, name in pairs(elements) do
    if i < max then
      navbar = navbar .. '» <a href="' .. strrepeat("../", max - i) .. 'index.html">' .. name .. '</a> '
    else
      navbar = navbar .. '» <span>' .. name .. '</span>'
    end
  end
  navbar = navbar == "" and "" or navbar .. '</div>'

  -- write new html files for each path
  local file = io.open(config.www .. path .. "/index.html", "w")
  file:write(string.format(template, config.website, config.title, config.description,
    sidebar, navbar, page
  ))

  file:close()
end
