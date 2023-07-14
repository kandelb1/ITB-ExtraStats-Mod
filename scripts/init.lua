local function init(self)
  LOG("MOD INIT")
  sdlext.config(
    "modcontent.lua",
    function(obj)
      if not obj["finishedGames"] then
        LOG("Creating finished games list in modcontent.lua")
        obj["finishedGames"] = {}
      end
    end
  )
  require(self.scriptPath .. "statistics_screen")
  require(self.scriptPath .. "modded_stats_browser")
  require(self.scriptPath .. "stat_tracker")
end

local function load(self, options, version)
  LOG("MOD LOAD")
  for i = 1, modApi.constants.VANILLA_SQUADS do
    local squadName = modApi.squad_text[i * 2 - 1] or "N/A"
    LOG(i .. " " .. squadName)
  end
end

return {
  id = "my_test_mod",
  name = "My Test Mod!!!",
  version = "0.1",
  dependencies = {
    modApiExt = "1.21",
    memedit = "1.1.4",
  },
  init = init,
  load = load,
}