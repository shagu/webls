return {
  -- generic website options
  title       = "webls",
  description = "a simple website generator",
  website     = "https://example.org",
  cname       = nil,

  -- add "index.html" to the end of each link
  pagesuffix  = true,

  -- folder that shall be scanned for content
  scanpath    = "content",

  -- the output directory that is later used as webroot
  www         = "www",

  -- modules that should be used for parsing
  modules     = { "html", "markdown", "git", "gallery", "download", "footer" },

  -- define default colors
  colors      = {
    ["accent"]      = "#3fc",
    ["border"]      = "#1a1a1a",
    ["bg-page"]     = "#000",
    ["bg-content"]  = "#000",
    ["bg-sidebar"]  = "#111",
    ["fg-page"]     = "#fff",
    ["fg-sidebar"]  = "#eee",
    ["customcss"]   = "",
  },
}
