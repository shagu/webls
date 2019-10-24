return {
  -- generic website options
  title       = "webls",
  description = "a simple website generator",
  website     = "https://example.org",

  -- folder that shall be scanned for content
  scanpath    = "content",

  -- the output directory that is later used as webroot
  www         = "www",

  -- modules that should be used for parsing
  modules     = { "markdown", "git", "gallery", "download", "footer" },

  -- define default colors
  colors      = {
    ["accent"]      = "#3a5",
    ["border"]      = "#eee",
    ["bg-page"]     = "#fafafa",
    ["bg-content"]  = "#fff",
    ["bg-sidebar"]  = "#fff",
    ["fg-page"]     = "#000",
    ["fg-sidebar"]  = "#222",
  },
}
