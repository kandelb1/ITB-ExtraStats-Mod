local function init(self)
  LOG("MOD INIT")
  -- create our finishedGames entry in modcontent.lua, if it doesn't exist already
  sdlext.config(
    "modcontent.lua",
    function(obj)
      if not obj["finishedGames"] then
        LOG("Creating finished games list in modcontent.lua")
        obj["finishedGames"] = {}
      end
    end
  )
  require(self.scriptPath .. "vanilla_stats_browser")
  require(self.scriptPath .. "modded_stats_browser")
  require(self.scriptPath .. "stat_tracker")
end

local function load(self, options, version)
  LOG("MOD LOAD")
end

return {
  id = "extra_stats",
  name = "Extra Stats",
  version = "0.1",
  dependencies = {
    modApiExt = "1.21",
    memedit = "1.1.4",
  },
  init = init,
  load = load,
}