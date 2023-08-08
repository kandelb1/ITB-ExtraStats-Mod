local function metadata(self)
  modApi:addGenerationOption(
    "logStatMessages",
    "Log Stat Increment Messages",
    "Enable to see increases in statistics in the console, ie. '+1 damageDealt'",
    { enabled = true }
  )
end

local function init(self, options)
  -- create our finishedGames entry in modcontent.lua, if it doesn't exist already
  sdlext.config(
    "modcontent.lua",
    function(obj)
      if not obj["finishedGames"] then
        obj["finishedGames"] = {}
        LOG("Created finishedGames entry in modcontent.lua")
      end
    end
  )
  require(self.scriptPath .. "vanilla_stats_browser")
  require(self.scriptPath .. "modded_stats_browser")
  require(self.scriptPath .. "stat_tracker")
end

local function load(self, options, version)
  if options["logStatMessages"] then
    LOG_STAT_MESSAGES = options["logStatMessages"]["enabled"]  
  else
    LOG("Error reading logStatMessages option, setting LOG_STAT_MESSAGES to false.")
    LOG_STAT_MESSAGES = false
  end
end

return {
  id = "extra_stats",
  name = "Extra Stats",
  version = "0.1",
  modApiVersion = "2.9.2",
  gameVersion = "1.2.88",
  dependencies = {
    modApiExt = "1.21",
    memedit = "1.1.4",
  },
  metadata = metadata,
  init = init,
  load = load,
}