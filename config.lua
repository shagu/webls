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
  modules     = { "markdown", "git", "gallery", "download", "footer" }
}
