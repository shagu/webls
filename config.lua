return {
  -- generic website options
  title       = "webls",
  description = "a simple website generator",
  website     = "https://example.org",
  cname       = nil,
  head        = nil,

  -- add "index.html" to the end of each link
  pagesuffix  = true,

  -- folder that shall be scanned for content
  scanpath    = "content",

  -- the output directory that is later used as webroot
  www         = "www",

  -- modules that should be used for parsing
  modules     = { "html", "markdown", "git", "gallery", "download", "footer" },

  --[[
  -- module options
  html = {
    extensions = { ".xhtml", ".html" }
  },
  markdown = {
    extensions = { ".md" }
  },
  gallery = {
    extensions = { ".png", ".jpg" }
  },
  download = {
    extensions = { ".pdf", ".xz", ".zstd" }
  },
  ]]--

  -- define default colors
  colors      = {
    ["accent"]      = "#3a5",
    ["border"]      = "#eee",
    ["bg-page"]     = "#fafafa",
    ["bg-content"]  = "#fff",
    ["bg-sidebar"]  = "#fff",
    ["fg-page"]     = "#000",
    ["fg-sidebar"]  = "#222",
    ["customcss"]   = "",
  },
}
