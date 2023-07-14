local squadSpecificLabels = {
  -- rift walkers
  [1] = {
    ["vekPushed"] = "Vek Pushed",
    ["pushDamage"] = "Total Push Damage",
  },
  -- rusting hulks
  [2] = {
    ["tilesSmoked"] = "Tiles Smoked",
    ["attacksCancelled"] = "Attacks Cancelled",
    ["stormDamage"] = "Total Storm Damage",
  },
  -- zenith guard
  [3] = {
    ["selfDamage"] = "Total Self Damage",
    ["shields"] = "Shields Applied",
    ["beamDamage"] = "Total Beam Weapon Damage",
  },
  -- blitzkrieg MEH ALL BORING
  [4] = {
    ["lightningDamage"] = "Tiles Smoked",
    ["idk"] = "idk",
    ["idk"] = "idk",
  },
  -- steel judoka
  [5] = {
    ["vekPushed"] = "Vek Pushed",
    ["vekSelfDamage"] = "Vek Self Damage",
    ["vekSelfKills"] = "Vek Self Kills",
  },
  -- flame behemoths
  [6] = {
    ["tilesFired"] = "Tiles Set on Fire",
    ["unitsFired"] = "Units Set on Fire",
    ["fireDamage"] = "Fire Damage",
  },
  -- frozen titans
  [7] = {
    ["unitsFrozen"] = "Units Frozen",
    ["pushDamage"] = "Push Damage",
    ["idk"] = "idk",
  },
  -- hazardous mechs
  [8] = {
    ["idk"] = "idk",
    ["idk"] = "idk",
    ["idk"] = "idk",
  },
  -- secret squad
  [9] = {
    ["idk"] = "idk",
    ["idk"] = "idk",
    ["idk"] = "idk",
  },
  -- bombermechs
  [10] = {
    ["bombsCreated"] = "Bombs Created",
    ["bombDamage"] = "Bomb Damage",
    ["idk"] = "idk",
  },
  -- arachnophiles
  [11] = {
    ["spidersCreated"] = "Spiders Created",
    ["idk"] = "idk",
    ["idk"] = "idk",
  },
  -- mist eaters
  [12] = {
    ["idk"] = "idk",
    ["tilesSmoked"] = "Tiles Smoked",
    ["attacksCancelled"] = "Attacks Cancelled",
  },
  -- heat sinkers
  [13] = {
    ["boosts"] = "Mech Boosts",
    ["fireDamage"] = "Fire Damage",
    ["unitsFired"] = "Units Set on Fire",
  },
  -- cataclysm
  [14] = {
    ["tilesCracked"] = "Tiles Cracked",
    ["tilesDestroyed"] = "Tiles Destroyed",
    ["vekPitted"] = "Vek Pitted",
  },
}

local function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

-- Spritesheet x offsets for medals for each difficulty (easy, normal, hard, unfair)
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
      local text = UiWrappedText(text .. ": " .. statsTable[key])
      :width(1)      
      :addTo(rightPane.statsBox.generalStats)
      text.textAlign = "center"  
    end 
  end

  local function createSquadSpecificLabel(text, key)
    if statsTable[key] then
      local text = UiWrappedText(text .. ": " .. statsTable[key])
      :width(1)      
      :addTo(rightPane.statsBox.specificStats)
      text.textAlign = "center"  
    end 
  end

  rightPane.statsBox:detach()
  rightPane.statsBox = nil
  LOG("showing game stats for squad " .. statsTable.squadId)
  rightPane.statsBox = UiWeightLayout()
    :width(1):height(1)
    :orientation(false):vgap(1)
    :addTo(rightPane)
  rightPane.statsBox.generalStats = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(5)
    :decorate({
      DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugMagenta, 2)
    })
    :addTo(rightPane.statsBox)
  rightPane.statsBox.specificStats = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(5)
    :decorate({
      DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugYellow, 2)
    })
    :addTo(rightPane.statsBox)
  
  createGeneralLabel("Kills", "kills")
  createGeneralLabel("Damage Dealt", "damageDealt")
  createGeneralLabel("Vek Pushed", "vekPushed")
  createGeneralLabel("Vek Blocked", "vekBlocked")
  createGeneralLabel("Grid Damage", "gridDamage")
  createGeneralLabel("Grid Resists", "gridResists")
  -- createGeneralLabel("Damage Taken", "damageTaken")
  -- createGeneralLabel("Self Damage", "selfDamage")    
  -- createGeneralLabel("Vek Self Damage", "vekSelfDamage")
  -- createGeneralLabel("Vek Self Kills", "vekSelfKills")

  for k, v in pairs(squadSpecificLabels[statsTable.squadId]) do
    createSquadSpecificLabel(v, k)    
  end
  
end

local function showGameHistoryWindow()
  sdlext.showDialog(function(ui, quit)
    LOG("SHOWING PREVIOUS GAMES DIALOG")
    local maxW = 0.8 * ScreenSizeX()
    local maxH = 0.8 * ScreenSizeY()
    local frame = sdlext.buildSimpleDialog("Previous Games", {
      maxW = maxW,
      maxH = maxH,
    })

    local box = UiWeightLayout()
    :orientation(true) -- horizontal
    :hgap(1)
    :width(1)
    :heightpx(maxH)
    :decorate({
      -- DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugGreen, 5)
    })
    -- :anchor("center", "center")
    :addTo(frame)

    local leftPane = UiWeightLayout()
    :width(0.33):height(1):vgap(1)
    :decorate({
      DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugMagenta, 2)
    })
    :addTo(box)
    leftPane.scroll = UiScrollArea():width(1):height(1):padding(5):addTo(leftPane)

    local rightPane = UiWeightLayout()
    :width(0.77):height(1):vgap(1)
    :decorate({
      DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugRed, 2)
    })
    :addTo(box)
    rightPane.statsBox = UiWeightLayout()
      :width(1)
      :vgap(10)

    local gameHistory = UiBoxLayout()
      :width(1):height(1):vgap(3):anchorH("center")
      :decorate({
      DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugTeal, 2)
    })
    :addTo(leftPane.scroll)

    local games = fetchGameHistory()
    local squadPalettes = sdlext.squadPalettes()
    -- since games go from oldest-newest, lets loop through backwards so the first item in the list is the most recent game
    -- TODO: if we want to sort by other stats, then we'll have to change this (just modify fetchGameHistory)
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
        DecoFrame(bgColor, nil, 2),
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
        local medal = Ui()
        :widthpx(MEDAL_SMALL.W):heightpx(MEDAL_SMALL.H)
        :decorate({
          -- DecoFrame(bgColor, deco.colors.debugYellow, 2),
          DecoAlign(MEDAL_X_OFFSETS[game.difficulty + 1], 0),
          DecoSurface(MEDAL_SURFACES[game.islandsSecured])
        })
        :clip()
        :addTo(right)
      end    
    end

    -- sdfasdfsdf
    
    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
  end)
end

local mainMenuButton = MainMenuButton("tiny")
  :pospx(412, 674)
  :caption("View Game History")
mainMenuButton.visible = false
mainMenuButton.onclicked = function() showGameHistoryWindow() return true end

modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
  mainMenuButton:addTo(uiRoot)
end)

modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
  if not mainMenuButton.visible or wasGame then
		mainMenuButton.visible = true
		mainMenuButton.animations.slideIn:start()
	end
end)

modApi.events.onMainMenuExited:subscribe(function(screen)
  LOG("EXITED MAIN MENU")
	mainMenuButton.visible = false
end)