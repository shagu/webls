#!/usr/bin/env lua
-- depends: lua-filesystem

local config = require("config")
local lfs = require("lfs")
local markdown = require("markdown/markdown")

-- simple helper functions
local function strsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[#fields+1] = c end)
  return unpack(fields)
end

local function escape(str)
  return (string.gsub(str, "%%", "%%%%"))
end

local function empty(tbl)
  for _ in pairs(tbl) do return nil end
  return true
end

local function round(num)
  return math.floor(num * 100 + .5)/100
end

local function spairs(t, index, reverse)
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end
  table.sort(keys)

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
  ["file"] = [[
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
      <path d="M20.54 5.23l-1.39-1.68C18.88 3.21 18.47 3 18 3H6c-.47 0-.88.21-1.16.55L3.46 5.23C3.17 5.57 3 6.02 3
      6.5V19c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6.5c0-.48-.17-.93-.46-1.27zM12 17.5L6.5 12H10v-2h4v2h3.5L12 17.5zM5.12
      5l.81-1h12l.94 1H5.12z"/><path d="M0 0h24v24H0z" fill="none"/>
    </svg>
  ]],
  ["git"] = [[
    <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 97 97" enable-background="new 0 0 97 97" xml:space="preserve"><g>
      <path fill="#F05133" d="M92.71,44.408L52.591,4.291c-2.31-2.311-6.057-2.311-8.369,0l-8.33,8.332L46.459,23.19
      c2.456-0.83,5.272-0.273,7.229,1.685c1.969,1.97,2.521,4.81,1.67,7.275l10.186,10.185c2.465-0.85,5.307-0.3,7.275,1.671
      c2.75,2.75,2.75,7.206,0,9.958c-2.752,2.751-7.208,2.751-9.961,0c-2.068-2.07-2.58-5.11-1.531-7.658l-9.5-9.499v24.997
      c0.67,0.332,1.303,0.774,1.861,1.332c2.75,2.75,2.75,7.206,0,9.959c-2.75,2.749-7.209,2.749-9.957,0c-2.75-2.754-2.75-7.21,0-9.959
      c0.68-0.679,1.467-1.193,2.307-1.537V36.369c-0.84-0.344-1.625-0.853-2.307-1.537c-2.083-2.082-2.584-5.14-1.516-7.698
      L31.798,16.715L4.288,44.222c-2.311,2.313-2.311,6.06,0,8.371l40.121,40.118c2.31,2.311,6.056,2.311,8.369,0L92.71,52.779
      C95.021,50.468,95.021,46.719,92.71,44.408z"/>
    </g></svg>
  ]],
}

local parser = {
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
      if not self.cache or not self.cache[path] or empty(self.cache[path]) then return "" end

      local txt = ""
      local tpl = '<div id="%s" class="text">%s</div>'

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
      if not self.cache or not self.cache[path] or empty(self.cache[path]) then return "" end

      local txt = '<div class="gallery">'
      local tpl = '<a href="%s"><img src="%s"/><span>%s</span></a>'

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
      if not self.cache or not self.cache[path] or empty(self.cache[path]) then return "" end

      local txt = '<div class="download">'
      local tpl = '<a href="%s">'..icons.file..'<span>%s <small>(%s)</small></span></a>'

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

  ["git"] = {
    passive = true,
    extensions = { "*" },
    prepare = function(self, path, name, fin, fout)
      self.cache = self.cache or {}
      if not self.cache[path] then
        local file = io.open(config.scanpath .. path .. "/.git/config", "rb")
        if not file then return nil end
        local remote, _ = file:read("*all")
        _, _, remote = string.find(remote, ".+url = (.-)\n.+")

        local zip
        if string.find(remote, "//gitlab.com") then
          zip = remote .. "/-/archive/master" .. remote:match("^.+(/.+)$") .. "-master.zip"
        elseif string.find(remote, "//github.com") then
          zip = remote .. "/archive/master.zip"
        end

        self.cache[path] = { ["remote"] = remote, ["zip"] = zip }
        file:close()
      end
    end,

    build = function(self, path)
      if not self.cache or not self.cache[path] then return "" end
      local html = '<div class="git"><div id="container"><span id="icon">%s</span><span id="url"><code>%s</code></span>%s</div>%s</div>'
      local zip = self.cache[path].zip and '<span id="download"><a href=' .. self.cache[path].zip .. '>Download</a></span>' or ""
      local history = self.cache[path].history and '<span id="history"><a href=' .. self.cache[path].history .. '>History</a></span>' or ""
      return string.format(html, icons.git, self.cache[path].remote, zip, history)
    end
  },

  ["footer"] = {
    build = function()
      return string.format('<div class="footer">%s - powered by <a href="https://gitlab.com/shagu/webls">webls</a></div>', os.date("%B %Y"))
    end
  },
}

-- content cache
local folders, pages = {}, {}
local function scan(path)
  local path = path or ""

  for name in lfs.dir(config.scanpath .. "/" .. path) do
    if name ~= "." and name ~= ".." then
      local full = path..'/'..name
      local attr = lfs.attributes(config.scanpath .. "/" .. full)
      local file = attr.mode == "file" and true or nil
      local ext = not file and "folder" or full:match("^.+(%..+)$") or ""
      local file_in = config.scanpath.."/"..full
      local file_out = config.www.."/"..full

      -- make sure directory exists
      lfs.mkdir(config.www.."/"..path)

      if ext == "folder" then
        scan(full)
        if pages[full] then
          folders[path] = folders[path] or {}
          folders[path][name] = full
        end
      end

      for _, m in pairs(config.modules) do
        if not parser[m] then -- throw error on non-existing module
          print(string.format('ERROR: module "%s" could not be found. Check your configuration file', m))
          return
        elseif parser[m].extensions then
          -- check for compatible parsers based on extension
          for _, mext in pairs(parser[m].extensions) do
            if ext == mext or mext == "*" then
              parser[m]:prepare(path, name, file_in, file_out)
              if not parser[m].passive then
                pages[path] = true
              end
            end
          end
        end
      end
    end
  end

  return pages
end

-- iterate over all paths in content directory
for path in pairs(scan()) do
  -- load basepath
  local elements = { strsplit('/', path) }
  local basepath = string.rep("../", #elements)
  local pagesuffix = config.pagesuffix and "index.html" or ""

  -- write stylesheet into the root directory
  if #elements == 0 then

    if config.cname then
      -- write CNAME file in order to allow custom domains
      local cname = io.open(config.www .. path .. "/CNAME", "w")
      cname:write(config.cname)
      cname:close()
    end

    local file = io.open("style.css", "rb")
    local content = file:read("*all")
    file:close()

    -- replace by config colors
    content = string.gsub(content, "(--accent: )#.-;",      "%1" .. config.colors["accent"] .. ";")
    content = string.gsub(content, "(--border: )#.-;",      "%1" .. config.colors["border"] .. ";")
    content = string.gsub(content, "(--bg: )#.-;",          "%1" .. config.colors["bg-page"] .. ";")
    content = string.gsub(content, "(--bg%-content: )#.-;", "%1" .. config.colors["bg-content"] .. ";")
    content = string.gsub(content, "(--bg%-sidebar: )#.-;", "%1" .. config.colors["bg-sidebar"] .. ";")
    content = string.gsub(content, "(--fg: )#.-;",          "%1" .. config.colors["fg-page"] .. ";")
    content = string.gsub(content, "(--fg%-sidebar: )#.-;", "%1" .. config.colors["fg-sidebar"] .. ";")

    local out = io.open(config.www .. path .. "/style.css", "w")
    out:write(content)
    out:close()
  end

  -- load template layout
  local file = io.open("template.html", "rb")
  local website = file:read("*all")
  file:close()

  -- load all content modules
  local page = ""
  for _, m in pairs(config.modules) do
    page = page .. parser[m]:build(path)
  end

  -- load sidebar
  local sidebar = path == "" and "" or '<a class="back sidelink" href="../' .. pagesuffix .. '">« Back</a>'
  if folders[path] and not empty(folders[path]) then
    for name, _ in spairs(folders[path]) do
      sidebar = sidebar .. string.format('<a class="sidelink" href="%s/' .. pagesuffix .. '">%s</a>', name, name)
    end
  end

  -- load navbar
  local navbar = path == "" and "" or '<div class="navigation">'
  for i, name in pairs(elements) do
    if i < #elements then
      navbar = navbar .. '» <a href="' .. string.rep("../", #elements - i) .. pagesuffix .. '">' .. name .. '</a> '
    else
      navbar = navbar .. '» <span>' .. name .. '</span>'
    end
  end
  navbar = navbar == "" and "" or navbar .. '</div>'

  -- write all contents
  website = string.gsub(website, "%%%%basepath%%%%", escape(basepath))
  website = string.gsub(website, "%%%%pagesuffix%%%%", escape(pagesuffix))
  website = string.gsub(website, "%%%%title%%%%", escape(config.title))
  website = string.gsub(website, "%%%%description%%%%", escape(config.description))
  website = string.gsub(website, "%%%%sidebar%%%%", escape(sidebar))
  website = string.gsub(website, "%%%%navbar%%%%", escape(navbar))
  website = string.gsub(website, "%%%%page%%%%", escape(page))

  -- write new generated website
  local out = io.open(config.www .. path .. "/index.html", "w")
  out:write(website)
  out:close()
end
