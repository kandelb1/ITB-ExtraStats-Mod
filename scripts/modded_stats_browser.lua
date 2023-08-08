local squadSpecificLabels = {
  -- TODO: double check these indices are correct
  -- rift walkers
  [1] = {
    ["punchDistance"] = "Distance Traveled with Punch",
  },
  -- zenith guard
  [2] = {
    ["shields"] = "Shields Applied",
    ["beamDamage"] = "Beam Weapon Damage",
  },
  -- steel judoka
  [3] = {
    ["vekSelfDamage"] = "Vek Self Damage",
    ["vekSelfKills"] = "Vek Self Kills",
  },
  -- rusting hulks
  [4] = {
    ["tilesSmoked"] = "Tiles Smoked",
    ["attacksCancelled"] = "Attacks Cancelled",
    ["stormDamage"] = "Storm Damage (WIP)",
  },
  -- blitzkrieg
  [5] = {
    ["lightningDamage"] = "Lightning Weapon Damage",
    ["lightningSelfDamage"] = "Lightning Weapon Self Damage",
    ["rocksLaunched"] = "Rocks Launched",
  },
  -- flame behemoths
  [6] = {
    ["tilesFired"] = "Tiles Set on Fire",
    ["unitsFired"] = "Units Set on Fire",
    ["fireDamage"] = "Fire Damage (WIP)",
  },
  -- frozen titans
  [7] = {
    ["unitsFrozen"] = "Units Frozen",
    ["damageBlockedWithIce"] = "Damage Blocked With Ice",
  },
  -- hazardous mechs
  [8] = {
    ["leapDistance"] = "Distance Traveled With Leap"
  },
  -- bombermechs
  [9] = {
    ["bombsCreated"] = "Bombs Created",
    ["bombDamage"] = "Bomb Damage",
  },
  -- mist eaters
  [10] = {
    -- NADA
  },
  -- cataclysm
  [11] = {
    ["tilesCracked"] = "Tiles Cracked",
    ["tilesDestroyed"] = "Tiles Destroyed",
    ["vekPitted"] = "Vek Pitted",
  },
  -- arachnophiles
  [12] = {
    ["spidersCreated"] = "Spiders Created",
    -- ["richochetDoubleKills"] = "Richochet Weapon Double Kills (WIP)"
  },
  -- heat sinkers
  [13] = {
    ["unitsFired"] = "Units Set on Fire",
    ["tilesFired"] = "Tiles Set on Fire",
    ["boosts"] = "Mech Boosts (WIP)",
    ["fireDamage"] = "Fire Damage (WIP)",
  },
  -- secret squad
  [14] = {
    -- NADA
  },
}

-- Medal spritesheet x offsets for # of islands secured
local MEDAL_X_OFFSETS = {-25, -50, -75, -100}
local MEDAL_SMALL = {W = 25, H = 34}
local MEDAL_SURFACES = {[2] = sdlext.getSurface({path = "img/ui/hangar/victory_2.png"}),
                        [3] = sdlext.getSurface({path = "img/ui/hangar/victory_3.png"}),
                        [4] = sdlext.getSurface({path = "img/ui/hangar/victory_4.png"})}

-- gets the list of previous games from modcontent.lua. games are sorted by date from oldest-newest by default
local function fetchGameHistory()
  return modApi:readModData("finishedGames")
end

local function showGameStatsInRightPane(statsTable, rightPane)
  local function createGeneralLabel(text, key)
    if statsTable[key] then
      Ui()
        :width(1):heightpx(15)
        :decorate({
          DecoText(text .. ": " .. statsTable[key])
        })
        :addTo(rightPane.statsBox.generalStats)
    end 
  end

  local function createSquadSpecificLabel(text, key)
    if statsTable[key] then
      Ui()
        :width(1):heightpx(15)
        :decorate({
          DecoText(text .. ": " .. statsTable[key])
        })
        :addTo(rightPane.statsBox.specificStats)
    end 
  end

  rightPane.statsBox:detach()
  rightPane.statsBox = UiWeightLayout()
    :width(1):height(1)
    :orientation(false):vgap(1)
    :addTo(rightPane)
  rightPane.statsBox.generalStats = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(5)
    :addTo(rightPane.statsBox)
  rightPane.statsBox.generalStats.padt = 10
  Ui()
    :width(1):heightpx(15)
    :decorate({
      DecoText("GENERAL STATS")
    })
  :addTo(rightPane.statsBox.generalStats)
  rightPane.statsBox.specificStats = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(5)
    :addTo(rightPane.statsBox)
  rightPane.statsBox.specificStats.padt = 10
  Ui()
    :width(1):heightpx(15)
    :decorate({
      DecoText("SQUAD-SPECIFIC STATS")
    })
  :addTo(rightPane.statsBox.specificStats)
  
  createGeneralLabel("Kills", "kills")
  createGeneralLabel("Damage Dealt", "damageDealt")
  createGeneralLabel("Damage Taken", "damageTaken")
  createGeneralLabel("Self Damage", "selfDamage")
  createGeneralLabel("Healing", "healing")  
  createGeneralLabel("Vek Pushed", "vekPushed")
  createGeneralLabel("Vek Spawns Blocked", "vekBlocked")
  createGeneralLabel("Vek Drowned", "vekDrowned")
  createGeneralLabel("Vek Pitted", "vekPitted")

  for k, v in pairs(squadSpecificLabels[statsTable.squadId]) do
    createSquadSpecificLabel(v, k)    
  end
  
end

local function showGameHistoryWindow()
  sdlext.showDialog(function(ui, quit)
    local maxW = 0.8 * ScreenSizeX()
    local maxH = 0.8 * ScreenSizeY()
    local frame = sdlext.buildSimpleDialog("Previous Games", {
      maxW = maxW,
      maxH = maxH,
      compactW = true,
      compactH = true,
    })

    local box = UiWeightLayout()
    :orientation(true) -- horizontal
    :hgap(1)
    :width(1)
    :heightpx(maxH)
    :addTo(frame)

    local leftPane = UiWeightLayout()
    :width(0.33):height(1):vgap(1)
    :addTo(box)
    leftPane.scroll = UiScrollArea():width(1):height(1):padding(5):addTo(leftPane)

    local rightPane = UiWeightLayout()
    :width(0.77):height(1):vgap(1)
    :addTo(box)
    rightPane.statsBox = UiWeightLayout()
      :width(1)
      :vgap(10)

    local gameHistory = UiBoxLayout()
      :width(1):height(1):vgap(3):anchorH("center")
      :addTo(leftPane.scroll)

    local games = fetchGameHistory()
    local squadPalettes = sdlext.squadPalettes()
    -- since games go from oldest-newest, lets loop through backwards so the first item in the list is the most recent game
    -- TODO: implement sorting by other stats, like score/kills/damage
    for i = #games, 1, -1 do
      local game = games[i]
      local squadId = game["squadId"]
      local path = modApi.squad_icon[squadId]
      local surface
      if path ~= nil then
        -- LOG(path)
        surface = sdlext.getSurface({path = path})
        if squadId > 1 and squadId <= modApi.constants.VANILLA_SQUADS then
          local colorTable = {}
          for j = 1, #squadPalettes[1] do
            colorTable[(j - 1) * 2 + 1] = squadPalettes[1][j]
            colorTable[(j - 1) * 2 + 2] = squadPalettes[squadId][j]
          end
          surface = sdl.colormapped(surface, colorTable)
        end      
      end
      if surface == nil then
        surface = sdlext.getSurface({path = "img/units/placeholder_mech.png"})
      end
      local bgColor
      if game.victory then
        bgColor = deco.colors.buttonhlcolor
      else
        bgColor = deco.colors.tooltipbg
      end
      local buttonBox = UiWeightLayout()
      :width(1):heightpx(100):hgap(1)
      :decorate({
        DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), nil),
        DecoButton(),
      })
      :addTo(gameHistory)
      buttonBox.onclicked = function() showGameStatsInRightPane(game, rightPane) return true end

      local left = UiWeightLayout()
      :width(0.4)
      :height(1)
      :decorate({
        -- DecoFrame(bgColor, deco.colors.debugYellow, 2),
        -- DecoText("#" .. i + 1),
        DecoSurfaceOutlined(surface),
      })
      :addTo(buttonBox)
      left.ignoreMouse = true

      local right = UiWeightLayout()
        :width(0.6)
        :height(1)
        :orientation(false):vgap(1)
        :decorate({
          -- DecoFrame(bgColor, deco.colors.debugRed, 2),
        })
        :addTo(buttonBox)
      right.ignoreMouse = true
    
      local date = os.date("*t", game.timeFinished)
      local dateText = date.month .. "/" .. date.day .. "/" .. date.year .. " " .. date.hour .. ":" .. date.min .. ":" .. date.sec
      Ui()
        :width(1):heightpx(15)
        :decorate({
          -- DecoFrame(bgColor, deco.colors.debugRed, 2),
          -- DecoCAlign(),
          DecoText(dateText)
        })
        :addTo(right)
      
      local victoryText = "Defeat"
      if game.victory then victoryText = "Victory!" end
      Ui()
        :width(0.5):heightpx(15)
        :decorate({
          -- DecoFrame(bgColor, deco.colors.debugGreen, 2),
          -- DecoAlign(0, 0),
          DecoCAlign(),
          DecoText(victoryText)
        })
        :anchorH("center")
        :addTo(right)
      
      if game.victory then
        Ui()
          :widthpx(MEDAL_SMALL.W):heightpx(MEDAL_SMALL.H)
          :decorate({
            DecoAlign(MEDAL_X_OFFSETS[game.difficulty + 1], 0),
            DecoSurface(MEDAL_SURFACES[game.islandsSecured])
          })
          :clip()
          :addTo(right)
      end    
    end
    
    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
  end)
end

sdlext.addModContent(
  "Extra Stats Browser",
  function() showGameHistoryWindow() end,
  "View all previous games that have extra stats recorded."
)