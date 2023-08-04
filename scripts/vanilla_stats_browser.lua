local squadPalettes = sdlext.squadPalettes()
-- copied from mod_loader/modui/pilot_deck_selector.lua
local ADVANCED_PILOTS = {"Pilot_Arrogant", "Pilot_Caretaker", "Pilot_Chemical", "Pilot_Delusional"}
-- Medal spritesheet x offsets for # of islands secured
local MEDAL_X_OFFSETS = {-25, -50, -75, -100}
local MEDAL_SMALL = {W = 25, H = 34}
local MEDAL_SURFACES = {[2] = sdlext.getSurface({path = "img/ui/hangar/victory_2.png"}),
                        [3] = sdlext.getSurface({path = "img/ui/hangar/victory_3.png"}),
                        [4] = sdlext.getSurface({path = "img/ui/hangar/victory_4.png"})}
local PILOT_PORTRAIT_SIZE = {W = 61, H = 61}

local function fetchGameHistory()
  LOG("TEST FETCH GAME HISTORY")
  local path = GetSavedataLocation() .. "profile_" .. Settings.last_profile .. "/profile.lua"
  local stats = modApi:loadIntoEnv(path).Profile.stat_tracker
  return stats
end

-- copied from mod_loader/modui/pilot_deck_selector.lua
local function getPilotSurface(pilotId)
  local portrait = _G[pilotId].Portrait
  local path
  if portrait == "" then
    local advanced = list_contains(ADVANCED_PILOTS, pilotId)
    local prefix = advanced and "img/advanced/portraits/pilots/" or "img/portraits/pilots/"
    path = prefix .. pilotId .. ".png"
  else
    path = "img/portraits/" .. portrait .. ".png"
  end
  local surface = sdlext.getSurface({path = path})
  if surface == nil then
    return sdlext.getSurface({path = "img/portraits/pilots/pilot_todo.png"})
  end
  return surface
end

local function getWeaponSurface(weaponId)
  if weaponId == "" then return nil end
  local weapon = _G[weaponId]
  local surface = sdlext.getSurface({path = "img/" .. weapon.Icon})
  if surface == nil then
    return sdlext.getSurface({path = "img/weapons/placeholder_weapon.png"})
  end
  return surface
end

local function getMechSurface(mechId, squadIndex)
  local mech = _G[mechId]
  local animData = ANIMS[mech.Image]
  local surface = sdlext.getSurface({path = "img/" .. animData.Image})
  if surface == nil then
    return sdlext.getSurface({path = "img/weapons/placeholder_mech.png"})
  end
  if squadIndex > 1 and squadIndex <= modApi.constants.VANILLA_SQUADS then
    local colorTable = {}
    for j = 1, #squadPalettes[1] do
      colorTable[(j - 1) * 2 + 1] = squadPalettes[1][j]
      colorTable[(j - 1) * 2 + 2] = squadPalettes[squadIndex][j]
    end
    surface = sdl.colormapped(surface, colorTable)
  end
  return surface
end

-- update the right side of the window with the loadout used, score, kills, etc.
local function gameClicked(game, rightPane)
  rightPane.loadout:detach()
  rightPane.loadout = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(10)
    :padding(20)
    :addTo(rightPane)

  for i = 0, 2 do
    local container = UiWeightLayout()
      :width(1):heightpx(PILOT_PORTRAIT_SIZE.H + 5)
      :hgap(10)
      :addTo(rightPane.loadout)

    local pilotKey = "pilot" .. i
    local weaponIndices = {(i * 2) + 1, (i * 2) + 2}
    local mechIndex = i + 1
    local squadIndex = modApi:squadChoice2Index(game["squad"])
    local color = game["colors"][i+1] -- TODO: use this color instead of the squad's color

    local mechSurface = getMechSurface(game["mechs"][mechIndex], squadIndex)
    local pilotSurface = getPilotSurface(game[pilotKey]["id"])
    local weapon1 = getWeaponSurface(game["weapons"][weaponIndices[1]])
    local weapon2 = getWeaponSurface(game["weapons"][weaponIndices[2]])
    Ui()
      :sizepx(PILOT_PORTRAIT_SIZE.W, PILOT_PORTRAIT_SIZE.H)
      :decorate({        
        DecoSurface(pilotSurface),
        DecoAlign(5, 0),
        DecoSurfaceOutlined(mechSurface),
        DecoAlign(5, 0),
        DecoSurface(weapon1),
        DecoAlign(5, 0),
        DecoSurface(weapon2),
      })
      :addTo(container)
  end

  rightPane.otherStats:detach()
  rightPane.otherStats = UiWeightLayout()
    :width(1):height(0.5)
    :orientation(false):vgap(5)
    :addTo(rightPane)

  local kills = game["kills"]
  local score = game["score"]
  local failedObjectives = game["failures"]
  local gameLength = game["time"] -- I have no idea how they are converting this value into the format you see in the normal statistics page
  local victory = game["victory"]

  if victory then
    local victoryContainer = UiWeightLayout()
      :width(1):heightpx(MEDAL_SMALL.H)
      :hgap(1)
      :addTo(rightPane.otherStats)
    Ui()
      :widthpx(80):height(1)
      :decorate({
        DecoText("Victory!")
      })
      :addTo(victoryContainer)
    Ui()
      :widthpx(MEDAL_SMALL.W):heightpx(MEDAL_SMALL.H)
      :decorate({
        DecoAlign(MEDAL_X_OFFSETS[game["difficulty"] + 1], 0),
        DecoSurface(MEDAL_SURFACES[game["islands"]])
      })
      :clip()
      :addTo(victoryContainer)
  else
    Ui()
    :heightpx(15)
    :decorate({
      DecoText("Defeat")
    })
    :addTo(rightPane.otherStats)
  end  
  Ui()
    :heightpx(15)
    :decorate({
      DecoText("Score: " .. score)
    })
    :addTo(rightPane.otherStats)
  Ui()
    :heightpx(15)
    :decorate({
      DecoText("Kills: " .. kills)
    })
    :addTo(rightPane.otherStats)
  Ui()
    :heightpx(15)
    :decorate({
      DecoText("Failed Objectives: " .. failedObjectives)
    })
    :addTo(rightPane.otherStats)

end

local function showStatsScreen(gameStats)
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
      :width(0.33)
      :height(1)
      :vgap(1)
      :addTo(box)
    leftPane.scroll = UiScrollArea()
      :width(1)
      :height(1)
      :padding(5)
      :addTo(leftPane)

    local rightPane = UiWeightLayout()
      :width(0.66):height(1)
      :orientation(false):vgap(10)
      :addTo(box)
    rightPane.loadout = UiWeightLayout()
      :width(1):height(0.5)
      :orientation(false):vgap(10)
      :addTo(rightPane)
    rightPane.otherStats = UiWeightLayout()
      :width(1):height(0.5)
      :orientation(false):vgap(5)
      :padding(20)
      :addTo(rightPane)
    
    local gameHistory = UiBoxLayout()    
      :width(1):height(1)
      :vgap(5)
      :addTo(leftPane.scroll)

    local i = 0
    local game = gameStats["score" .. i]
    while game ~= nil do
      local squadIndex = modApi:squadChoice2Index(game["squad"])
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
      local squadName = modApi.squad_text[squadIndex * 2 - 1] or "N/A"
      local score = game["score"]
      local bgColor = deco.colors.tooltipbg
      if game["victory"] then
        bgColor = deco.colors.buttonhlcolor
      end

      local buttonBox = UiWeightLayout()
        :width(1)
        :heightpx(100)
        :hgap(0)
        :decorate({
          DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), 2),
          DecoButton(),
        })
        :addTo(gameHistory)
      buttonBox.gameId = "score" .. i
      buttonBox.onclicked = function(self, button)
        LOG(self.gameId .. " CLICKED!")
        gameClicked(gameStats[self.gameId], rightPane)
        return true
      end
      
      local left = UiWeightLayout()
        :width(0.4)
        :height(1)
        :decorate({
          DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), nil),
          DecoText("#" .. i + 1),
          DecoSurfaceOutlined(surface),
        })
        :addTo(buttonBox)
      left.ignoreMouse = true

      local right = UiWeightLayout()
        :width(0.6):height(1)
        :orientation(false):vgap(5)
        :addTo(buttonBox)
        :decorate({
          DecoFrame(bgColor, sdl.rgba(0, 0, 0, 0), nil),
        })
      right.ignoreMouse = true

      -- show squad name
      Ui()
      :width(1):heightpx(15)
      :decorate({
        DecoText(squadName)
      })
      :anchorH("center")
      :addTo(right)

      -- show a medal if this game was a victory
      if game["victory"] then
        Ui()
          :widthpx(MEDAL_SMALL.W):heightpx(MEDAL_SMALL.H)
          :decorate({
            DecoAlign(MEDAL_X_OFFSETS[game["difficulty"] + 1], 0),
            DecoSurface(MEDAL_SURFACES[game["islands"]])
          })
          :clip()
          :addTo(right)
      end

      -- show score
      Ui()
      :width(1):heightpx(15)
      :decorate({
        DecoText("Score: " .. score)
      })
      :addTo(right)

      i = i + 1
      game = gameStats["score" .. i]
    end
    LOG("LOOP OVER")

    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
  end)
end

local gameStats = fetchGameHistory()

sdlext.addModContent(
  "Vanilla Stats Browser",
  function() showStatsScreen(gameStats) end,
  "View all previous games, showing just vanilla stats."
)