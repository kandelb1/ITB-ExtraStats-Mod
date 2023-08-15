-- maps squad index (modloader-based indices) to labels we should display
local squadSpecificLabels = {
  -- rift walkers
  [1] = {
    ["punchDistance"] = "Distance Traveled with Punch",
  },
  -- rusting hulks
  [2] = {
    ["tilesSmoked"] = "Tiles Smoked",
    ["attacksCancelled"] = "Attacks Cancelled",
  },
  -- zenith guard
  [3] = {
    ["shields"] = "Shields Applied",
    ["beamDamage"] = "Beam Weapon Damage",
  },
  -- blitzkrieg
  [4] = {
    ["lightningDamage"] = "Lightning Weapon Damage",
    ["lightningSelfDamage"] = "Lightning Weapon Self Damage",
    ["rocksLaunched"] = "Rocks Launched",
  },
  -- steel judoka
  [5] = {
    ["vekSelfDamage"] = "Vek Self Damage",
    ["vekSelfKills"] = "Vek Self Kills",
  },
  -- flame behemoths
  [6] = {
    ["tilesFired"] = "Tiles Set on Fire",
    ["unitsFired"] = "Units Set on Fire",
  },
  -- frozen titans
  [7] = {
    ["unitsFrozen"] = "Units Frozen",
    ["damageBlockedWithIce"] = "Damage Blocked With Ice",
  },
  -- hazardous mechs
  [8] = {
    ["leapDistance"] = "Distance Traveled With Leap",
    ["acidApplied"] = "Acid Applied to Vek"
  },
  -- secret squad
  [9] = {
    ["ramDistance"] = "Distance Traveled with Ram"
  },
  -- bombermechs
  [10] = {
    ["bombsCreated"] = "Bomblings Created",
    ["bombDamage"] = "Bombling Damage",
  },
  -- arachnophiles
  [11] = {
    ["spidersCreated"] = "Spiderlings Created",
    ["spiderDamage"] = "Spiderling Damage"
  },
  -- mist eaters
  [12] = {
    ["tilesSmoked"] = "Tiles Smoked",
    ["attacksCancelled"] = "Attacks Cancelled",
  },
  -- heat sinkers
  [13] = {
    ["boosts"] = "Mech Boosts (WIP)",
    ["unitsFired"] = "Units Set on Fire",
    ["tilesFired"] = "Tiles Set on Fire",
  },
  -- cataclysm
  [14] = {
    ["tilesCracked"] = "Tiles Cracked",
    ["tilesDestroyed"] = "Tiles Destroyed",
    ["vekPitted"] = "Vek Pitted",
  },
}

local squadPalettes = sdlext.squadPalettes()
-- Medal spritesheet x offsets for # of islands secured
local MEDAL_X_OFFSETS = {-25, -50, -75, -100}
local MEDAL_SMALL = {W = 25, H = 34}
local MEDAL_SURFACES = {[2] = sdlext.getSurface({path = "img/ui/hangar/victory_2.png"}),
                        [3] = sdlext.getSurface({path = "img/ui/hangar/victory_3.png"}),
                        [4] = sdlext.getSurface({path = "img/ui/hangar/victory_4.png"})}
local defeatTextset = deco.textset(sdl.rgb(255, 0, 0), deco.colors.black, 2, false)
local victoryTextset = deco.textset(sdl.rgb(0, 255, 0), deco.colors.black, 2, false)
local selectedButton = nil

-- gets the list of previous games from the current profile's modcontent.lua. games are sorted by date from oldest-newest by default
local function fetchGameHistory()
  return modApi:readProfileData("finishedGames") or {}
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
      DecoText("GENERAL STATS", deco.fonts.tooltipTitle, deco.uifont.title.set)
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
      DecoText("SQUAD-SPECIFIC STATS", deco.fonts.tooltipTitle, deco.uifont.title.set)
    })
  :addTo(rightPane.statsBox.specificStats)
  
  createGeneralLabel("Kills", "kills")
  createGeneralLabel("Damage Dealt", "damageDealt")
  createGeneralLabel("Damage Taken", "damageTaken")
  createGeneralLabel("Self Damage", "selfDamage")
  createGeneralLabel("Healing", "healing")  
  createGeneralLabel("Grid Damage Taken", "gridDamage")
  createGeneralLabel("Grid Resists", "gridResists")
  createGeneralLabel("Vek Pushed", "vekPushed")
  createGeneralLabel("Vek Spawns Blocked", "vekBlocked")
  createGeneralLabel("Vek Drowned", "vekDrowned")

  if squadSpecificLabels[statsTable["squadIndex"]] then -- random/custom squads have a squadIndex of -1. There are no labels for them.
    for k, v in pairs(squadSpecificLabels[statsTable["squadIndex"]]) do
      createSquadSpecificLabel(v, k)    
    end
  end
end

local function showGameHistoryWindow(games)
  sdlext.showDialog(function(ui, quit)
    local maxW = 0.8 * ScreenSizeX()
    local maxH = 0.8 * ScreenSizeY()
    local frame = sdlext.buildSimpleDialog("Previous Games", {
      maxW = maxW,
      maxH = maxH,
      compactW = true,
      compactH = true,
    })
    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
    if #games == 0 then -- there aren't any games in the list
      Ui()
        :decorate({          
          DecoAlign((maxW / 2) - 160, -maxH / 2),
          DecoText("No games available.", deco.uifont.title.font, deco.uifont.title.set)
        })
        :addTo(frame)
      return
    end

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
      :width(1):height(1):vgap(3)
      :addTo(leftPane.scroll)

    -- since games go from oldest-newest, lets loop through backwards so the first item in the list is the most recent game
    -- TODO: implement sorting by other stats, like score/kills/damage
    for i = #games, 1, -1 do
      local game = games[i]
      local squadIndex = game["squadIndex"]
      local path = modApi.squad_icon[squadIndex]
      local surface
      if path ~= nil then
        surface = sdlext.getSurface({path = path})
        if squadIndex > 1 and squadIndex <= modApi.constants.VANILLA_SQUADS then
          local colorTable = {}
          for j = 1, #squadPalettes[1] do
            colorTable[(j - 1) * 2 + 1] = squadPalettes[1][j]
            colorTable[(j - 1) * 2 + 2] = squadPalettes[squadIndex][j]
          end
          surface = sdl.colormapped(surface, colorTable)
        end      
      end
      if surface == nil then
        surface = sdlext.getSurface({path = "img/units/placeholder_mech.png"})
      end
      local bgColor = deco.colors.tooltipbg
      if game["victory"] then
        bgColor = deco.colors.buttonhlcolor
      end

      local buttonBox = UiWeightLayout()
      :width(1):heightpx(100):hgap(0)
      :decorate({
        DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), 2),
        DecoButton(),
      })
      :addTo(gameHistory)
      buttonBox.onclicked = function() 
        showGameStatsInRightPane(game, rightPane) 
        if selectedButton then -- reset border of previously selected button
          selectedButton.decorations[2].bordercolor = deco.colors.buttonborder
        end
        buttonBox.decorations[2].bordercolor = deco.colors.buttonborderhl -- highlight this button
        selectedButton = buttonBox
        return true
      end

      local left = UiWeightLayout()
        :width(0.4)
        :height(1)
        :decorate({
          DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), nil),
          DecoSurfaceOutlined(surface),
        })
        :addTo(buttonBox)
        left.ignoreMouse = true

      local right = UiWeightLayout()
        :width(0.6)
        :height(1)
        :orientation(false):vgap(1)
        :decorate({
          DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), nil),
        })
        :addTo(buttonBox)
      right.ignoreMouse = true
    
      local date = os.date("*t", game.timeFinished)
      local dateText = date.month .. "/" .. date.day .. "/" .. date.year .. " " .. date.hour .. ":" .. date.min .. ":" .. date.sec
      Ui()
        :width(1):heightpx(15)
        :decorate({
          DecoText(dateText)
        })
        :addTo(right)
      
      local victoryText = "Defeat"
      local textset = defeatTextset
      if game.victory then 
        victoryText = "Victory!" 
        textset = victoryTextset 
      end
      Ui()
        :width(0.5):heightpx(15)
        :decorate({
          DecoCAlign(),
          DecoText(victoryText, nil, textset)
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
    
  end)
end

sdlext.addModContent(
  "Extra Stats Browser",
  function() showGameHistoryWindow(fetchGameHistory()) end,
  "View all previous games that have extra stats recorded."
)