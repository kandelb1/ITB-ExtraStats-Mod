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


local function fetchGameHistory()
  LOG("TEST FETCH GAME HISTORY")
  local path = GetSavedataLocation() .. "profile_" .. Settings.last_profile .. "/profile.lua"
  local stats = modApi:loadIntoEnv(path).Profile.stat_tracker
  return stats
end

-- update the right panel's information
-- note for later: medal grid size is 25 x 34
local function gameClicked(game, rightPane)
  -- LOG(gameId .. " clicked! modifying rightPane... " .. tostring(rightPane))
  local squadId = game["squad"] + 1
  local squadName = modApi.squad_text[squadId * 2 - 1] or "N/A"
  rightPane.topHalf.title:caption(squadName)
  local medalSurface = sdlext.getSurface({path = "img/ui/hangar/ml_victory_2.png"})
  rightPane.topHalf.medal.surface = medalSurface
  rightPane:relayout()
end

local function showStatsScreen(gameStats)
  sdlext.showDialog(function(ui, quit)
    LOG("SHOWING DIALOG")

    local maxW = 0.8 * ScreenSizeX()
    local maxH = 0.8 * ScreenSizeY()
    local frame = sdlext.buildSimpleDialog("Extra Statistics", {
      maxW = maxW,
      maxH = maxH,
    })
    -- frame:decorate({
    --   DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugMagenta, 5)
    -- })
    
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
      :width(0.33)
      :height(1)
      :vgap(1)
      :decorate({
        -- DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugMagenta, 2)
      })
      :addTo(box)
    leftPane.scroll = UiScrollArea()
      :width(1)
      :height(1)
      :padding(5)
      :addTo(leftPane)

    local rightPane = UiWeightLayout()
      :width(0.66):height(1)
      :vgap(1)
      :orientation(false)
      :decorate({
        DecoFrame(bgColor, deco.colors.debugYellow, 2),
      })
      :addTo(box)
    
    local gameHistory = UiBoxLayout()
      :width(1)
      :height(1)
      :vgap(3)
      :decorate({
        -- DecoFrame(deco.colors.buttonhlcolor, deco.colors.debugTeal, 2)
      })
      :anchorV("center")
      :addTo(leftPane.scroll)

    local index = 0
    for squadId, squad in pairs(modApi.mod_squads_by_id) do
      LOG("index, squadId, squad: " .. index .. ", " .. squadId .. ", " .. dump(squad))
      index = index + 1
    end

    -- local stats = fetchGameHistory()
    local squadPalettes = sdlext.squadPalettes()
    local i = 0
    local game = gameStats["score" .. i]
    LOG(modApi.constants.VANILLA_SQUADS)
    while game ~= nil do
      local squadId = game["squad"] + 1
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
      -- LOG(dump(game))      
      local squadName = modApi.squad_text[squadId * 2 - 1] or "N/A"
      local score = game["score"]
      local bgColor
      if game["victory"] then
        bgColor = deco.colors.buttonhlcolor
      else
        bgColor = deco.colors.tooltipbg
      end
      local buttonBox = UiWeightLayout()
        :width(1)
        :heightpx(100)
        :hgap(1)
        :decorate({
          DecoFrame(bgColor, deco.colors.debugTeal, 2),
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
          -- DecoFrame(bgColor, deco.colors.debugYellow, 2),
          DecoText("#" .. i + 1),
          DecoSurfaceOutlined(surface),
        })
        :addTo(buttonBox)
      left.ignoreMouse = true

      local right = UiWeightLayout()
        :width(0.6)
        :height(1)
        :vgap(5)
        :decorate({
          -- DecoFrame(bgColor, deco.colors.debugRed, 2),
        })
        :addTo(buttonBox)
      right.ignoreMouse = true
      
      local titleHolder = UiWeightLayout()
        :height(0.3)
        :width(1)
        :hgap(1)
        :addTo(right)

      Ui()
        :width(1)
        :addTo(titleHolder)
        :setTranslucent(true)
      local txt = UiWrappedText(squadName)
        :addTo(titleHolder)
      txt.textAlign = "center"
      Ui()
        :width(1)
        :addTo(titleHolder)
        :setTranslucent(true)

      i = i + 1
      game = gameStats["score" .. i]
    end
    LOG("LOOP OVER")

    
    rightPane.topHalf = UiWeightLayout()
      :height(0.5):width(1)
      :decorate({
        DecoFrame(bgColor, deco.colors.debugMagenta, 2),
      })
      :addTo(rightPane)

    rightPane.topHalf.title = Ui()
      :caption("HELLO TEST")
      :decorate({
        DecoCaption(),
      })
      :addTo(rightPane.topHalf)
    
    rightPane.topHalf.medal = Ui()
      :widthpx(20):heightpx(20)
      :decorate({
        DecoSurface(nil)
      })
      :addTo(rightPane.topHalf)

    rightPane.botHalf = UiWeightLayout()
      :height(0.5):width(1)
      :decorate({
        DecoFrame(bgColor, deco.colors.debugTeal, 2),
      })
      :addTo(rightPane)

    rightPane.botHalf.titleHolder = UiWeightLayout()
      :height(0.2):width(1)
      :hgap(1)
      :addTo(rightPane.botHalf)

    Ui()
      :width(1)
      :addTo(rightPane.botHalf.titleHolder)
      :setTranslucent(true)
    local txt = UiWrappedText("Squad-Specific Stats")
      :addTo(rightPane.botHalf.titleHolder)
    txt.textAlign = "center"
    Ui()
      :width(1)
      :addTo(rightPane.botHalf.titleHolder)
      :setTranslucent(true)
    
    
    -- rightPane.botHalf.titleHolder
    
    frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
  end)
end

local function buildTestButton(gameStats)
  local btn  = MainMenuButton("long")
    :pospx(100, 100)
    :caption("OMG TEST BUTTON")
  btn.visible = false

  -- modApi.events.onGameWindowResized:subscribe(function(screen, oldSize)
  -- btn:pospx(0, ScreenSizeY() - 186)
  -- end)

  btn.onclicked = function(self, button)
    if button == 1 then
      LOG("TEST BUTTON CLICKED")
      showStatsScreen(gameStats)
    end
    return true
  end

  return btn
end

local gameStats = fetchGameHistory()
local testButton = buildTestButton(gameStats)


modApi.events.onUiRootCreating:subscribe(function(screen, uiRoot)
  LOG("ON RUIT ROOT CREATING...")
end)

modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
  LOG("ON UI ROOT CREATED")
  -- if testButton then return end
  -- testButton = buildTestButton()
  -- -- testButton.visible = true
  testButton:addTo(uiRoot)
end)

modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
  LOG("ENTERED MAIN MENU")
  LOG(testButton)
  if not testButton.visible or wasGame then
		testButton.visible = true
		testButton.animations.slideIn:start()
	end
end)

modApi.events.onMainMenuExited:subscribe(function(screen)
  LOG("EXITED MAIN MENU")
	testButton.visible = false
end)