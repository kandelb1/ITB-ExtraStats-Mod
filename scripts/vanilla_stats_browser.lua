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
local MECH_SURFACE_SIZE = {W = 88, H = 68}
local defeatTextset = deco.textset(sdl.rgb(255, 0, 0), deco.colors.black, 2, false)
local victoryTextset = deco.textset(sdl.rgb(0, 255, 0), deco.colors.black, 2, false)
local selectedButton = nil


local function fetchGameHistory()
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

local function getMechSurface(mechId, colorIndex)
  local mech = _G[mechId]
  local animData = ANIMS[mech.Image]
  local noShadowImage = animData.Image:sub(0, #animData.Image - 4) .. "_ns.png"
  local surface = sdlext.getSurface({path = "img/" .. noShadowImage})
  if surface == nil then
    return sdlext.getSurface({path = "img/weapons/placeholder_mech.png"})
  end
  if colorIndex > 1 and colorIndex <= modApi.constants.VANILLA_SQUADS then
    local colorTable = {}
    for j = 1, #squadPalettes[1] do
      colorTable[(j - 1) * 2 + 1] = squadPalettes[1][j]
      colorTable[(j - 1) * 2 + 2] = squadPalettes[colorIndex][j]
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
    :orientation(false):vgap(60)
    :padding(20)
    :addTo(rightPane)

  for i = 0, 2 do
    local container = UiWeightLayout()
      :width(0.6):heightpx(25)
      :hgap(1)
      :decorate({
        DecoFrame(deco.colors.tooltipbg, deco.colors.buttonborder)
      })
      :addTo(rightPane.loadout)

    local pilotKey = "pilot" .. i
    local weaponIndices = {(i * 2) + 1, (i * 2) + 2}
    local mechIndex = i + 1
    local colorIndex = game["colors"][i+1] + 1

    local mechSurface = getMechSurface(game["mechs"][mechIndex], colorIndex)
    local pilotSurface = getPilotSurface(game[pilotKey]["id"])
    local weapon1 = getWeaponSurface(game["weapons"][weaponIndices[1]])
    local weapon2 = getWeaponSurface(game["weapons"][weaponIndices[2]])
    Ui()
      :width(0.2):height(1)
      -- :sizepx(PILOT_PORTRAIT_SIZE.W, PILOT_PORTRAIT_SIZE.H)
      :decorate({
        -- DecoFrame(sdl.rgba(0, 0, 0, 0), deco.colors.debugRed),
        DecoSurface(pilotSurface)
      })
      :addTo(container)
    local mech = Ui()
      :width(0.2):height(1)
      :decorate({
        -- DecoFrame(sdl.rgba(0, 0, 0, 0), deco.colors.debugGreen),
        DecoSurfaceOutlined(mechSurface)
      })
      :addTo(container)
    mech.ignoreMouse = true
    Ui()
      :width(0.2):height(1)
      :decorate({
        -- DecoFrame(sdl.rgba(0, 0, 0, 0), deco.colors.debugBlue),
        DecoSurface(weapon1)
      })
      :addTo(container)
    Ui()
      :width(0.2):height(1)
      :decorate({
        -- DecoFrame(sdl.rgba(0, 0, 0, 0), deco.colors.debugBlue),
        DecoSurface(weapon2)
      })
      :addTo(container)
    -- local images = Ui()
    --   :sizepx(PILOT_PORTRAIT_SIZE.W, PILOT_PORTRAIT_SIZE.H)
    --   :decorate({        
    --     DecoSurface(pilotSurface),
    --     DecoAlign(5, 0),
    --     DecoSurfaceOutlined(mechSurface),
    --     DecoAlign(5, 0),
    --     DecoSurface(weapon1),
    --     DecoAlign(5, 0),
    --     DecoSurface(weapon2),
    --   })
    --   :addTo(container)
    -- images.ignoreMouse = true
    
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
        DecoText("Victory!", nil, victoryTextset)
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
      DecoText("Defeat", nil, defeatTextset)
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
      -- modApi.squad_text doesn't contain text for random or custom squad, so gotta check manually
      if game["squad"] == 8 then squadName = "Random Squad" end
      if game["squad"] == 9 then squadName = "Custom Squad" end
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
        gameClicked(gameStats[self.gameId], rightPane)        
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

      -- show score
      Ui()
        :width(1):heightpx(15)
        :decorate({
          DecoText("Score: " .. score)
        })
        :addTo(right)

      if game["victory"] then -- display a medal if this game was a victory
        Ui()
          :widthpx(MEDAL_SMALL.W):heightpx(MEDAL_SMALL.H)
          :decorate({
            DecoAlign(MEDAL_X_OFFSETS[game["difficulty"] + 1], 0),
            DecoSurface(MEDAL_SURFACES[game["islands"]])
          })
          :clip()
          :addTo(right)
      else -- otherwise display 'Defeat'
        Ui()
          :heightpx(15)
          :decorate({            
            DecoText("Defeat", nil, defeatTextset)
          })
          :addTo(right)
      end

      i = i + 1
      game = gameStats["score" .. i]
    end
    LOG("LOOP OVER")

    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
  end)
end

sdlext.addModContent(
  "Vanilla Stats Browser",
  function() showStatsScreen(fetchGameHistory()) end,
  "View all previous games, showing just vanilla stats."
)