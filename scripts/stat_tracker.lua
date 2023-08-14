local function logStatIncrement(value, statsTableKey)
  if LOG_STAT_MESSAGES then
    LOG("+" .. value .. " " .. statsTableKey)
  end
end

local statsTable = {}

local vekSelfDamageTable = {}
local playerSelfDamageTable = {}
local beamWeaponDamageTable = {}
local lightningWeaponDamageTable = {}
local bomblingDamageTable = {}
local spiderlingDamageTable = {}
local prevGridHealth = nil
local skipFireStat = false
local defeated = false

math.randomseed(os.time())
local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function initializeStatsTable()
  local stats = {}
  -- GENERAL STATS
  stats["kills"] = 0
  stats["damageDealt"] = 0
  stats["damageTaken"] = 0
  stats["selfDamage"] = 0
  stats["healing"] = 0
  stats["gridResists"] = 0
  stats["gridDamage"] = 0
  stats["vekPushed"] = 0
  stats["vekBlocked"] = 0
  stats["vekDrowned"] = 0

  --SQUAD-SPECIFIC STATS
  -- rift walkers
  stats["punchDistance"] = 0

  -- zenith guard 
  stats["shields"] = 0
  stats["beamDamage"] = 0

  --steel judoka
  stats["vekSelfDamage"] = 0
  stats["vekSelfKills"] = 0

  -- rusting hulks
  stats["tilesSmoked"] = 0
  stats["attacksCancelled"] = 0

  -- blitzkrieg
  stats["lightningDamage"] = 0
  stats["lightningSelfDamage"] = 0
  stats["rocksLaunched"] = 0

  -- flame behemoths
  stats["unitsFired"] = 0
  stats["tilesFired"] = 0

  -- frozen titans
  stats["unitsFrozen"] = 0
  stats["damageBlockedWithIce"] = 0

  -- hazardous mechs
  stats["leapDistance"] = 0
  stats["acidApplied"] = 0

  -- bombermechs
  stats["bombsCreated"] = 0
  stats["bombDamage"] = 0

  -- mist eaters
  stats["tilesSmoked"] = 0
  stats["attacksCancelled"] = 0

  -- cataclysm
  stats["tilesCracked"] = 0
  stats["tilesDestroyed"] = 0
  stats["vekPitted"] = 0

  -- arachnophiles
  stats["spidersCreated"] = 0
  stats["spiderDamage"] = 0

  -- heat sinkers
  stats["boosts"] = 0 -- incomplete, waiting for the next version of modapiext for the pawnIsBoosted hook
  stats["unitsFired"] = 0
  stats["tilesFired"] = 0

  -- secret squad
  stats["ramDistance"] = 0

  -- OTHER
  stats["squadIndex"] = 0
  stats["difficulty"] = -1
  stats["islandsSecured"] = 0

  return stats
end

local function loadCurrentStats()
  return modApi:readProfileData("current") or initializeStatsTable() -- in the rare case that someone installs the mod and continues a current run
end

local function saveStats()
  modApi:writeProfileData("current", statsTable)
end

local function saveFinishedGameStats(gameId, victory, difficulty, islandsSecured, timeFinished)
  LOG("Finished game, recording extra stats under gameId " .. gameId)
  statsTable["gameId"] = gameId
  statsTable["victory"] = victory
  statsTable["difficulty"] = difficulty
  statsTable["islandsSecured"] = islandsSecured
  statsTable["timeFinished"] = timeFinished
  sdlext.config(
    modApi:getCurrentProfilePath() .. "modcontent.lua",
    function(obj)
      if not obj["finishedGames"] then obj["finishedGames"] = {} end
      local index = #obj["finishedGames"] + 1
      obj["finishedGames"][index] = statsTable
    end
  )
end

modApi.events.onMissionUpdate:subscribe(function()
  if IsTestMechScenario() then return end
  -- IsEvent() numbers come from ITB modding discord
  if Game:IsEvent(7) then -- grid damaged
    local currentGridHealth = Game:GetPower():GetValue()
    local damageTaken = prevGridHealth - currentGridHealth
    logStatIncrement(damageTaken, "gridDamage")
    statsTable["gridDamage"] = statsTable["gridDamage"] + damageTaken
    prevGridHealth = currentGridHealth
  end
  if Game:IsEvent(9) then -- grid resisted
    logStatIncrement(1, "gridResists")
    statsTable["gridResists"] = statsTable["gridResists"] + 1
  end
  if Game:IsEvent(16) then -- vek blocked
    logStatIncrement(1, "vekBlocked")
    statsTable["vekBlocked"] = statsTable["vekBlocked"] + 1
  end
  if Game:IsEvent(26) then -- forest set on fire
    if skipFireStat then -- it's hacky, but it totally works
      skipFireStat = false
    else
      logStatIncrement(1, "tilesFired")
      statsTable["tilesFired"] = statsTable["tilesFired"] + 1
    end    
  end
  if Game:IsEvent(27) then -- sand turned to smoke
    logStatIncrement(1, "tilesSmoked")
    statsTable["tilesSmoked"] = statsTable["tilesSmoked"] + 1
  end
  if Game:IsEvent(42) then -- attack cancelled with smoke
    logStatIncrement(1, "attacksCancelled")
    statsTable["attacksCancelled"] = statsTable["attacksCancelled"] + 1
  end

end)

modApi.events.onPreStartGame:subscribe(function() 
  -- starting new game, so get new stats and write them to the file
  statsTable = initializeStatsTable()
  saveStats()
end)

modApi.events.onPostStartGame:subscribe(function()
  statsTable["squadIndex"] = GAME.additionalSquadData.squadIndex
end)

-- this is fired on your first time loading into the game.
-- interestingly, if you go back to the main menu and then click 'continue', it won't fire
modapiext.events.onGameLoaded:subscribe(function(mission)
  statsTable = loadCurrentStats()
  prevGridHealth = Game:GetPower():GetValue()
end)

modApi.events.onContinueClicked:subscribe(function() 
  statsTable = loadCurrentStats()
end)

-- this is fired a LOT
modApi.events.onSaveGame:subscribe(function()
  saveStats()
end)

modApi.events.onGameVictory:subscribe(function(difficulty, islandsSecured, squadId)
  saveFinishedGameStats(uuid(), true, difficulty, islandsSecured, os.time())
end)

modApi.events.onMissionStart:subscribe(function(mission)
  -- grid power can change between missions, so update it on every mission start
  prevGridHealth = Game:GetPower():GetValue()
end)

modApi.events.onGameStateChanged:subscribe(function(newState, oldState)
  if oldState == GAME_STATE.ISLAND and newState == GAME_STATE.MAP then
    statsTable["islandsSecured"] = statsTable["islandsSecured"] + 1
  end
  if newState == GAME_STATE.HANGAR then
    defeated = false
  end
  if oldState == GAME_STATE.MAIN_MENU and (newState == GAME_STATE.MAP or newState == GAME_STATE.ISLAND or newState == GAME_STATE.MISSION) then
    prevGridHealth = Game:GetPower():GetValue()
  end
end)

modapiext.events.onPawnIsFire:subscribe(function(mission, pawn, isFire)
  if IsTestMechScenario() then return end
  if isFire then
    logStatIncrement(1, "unitsFired")
    statsTable["unitsFired"] = statsTable["unitsFired"] + 1
  end
end)

modapiext.events.onPawnIsFrozen:subscribe(function(mission, pawn, isFrozen)
  if IsTestMechScenario() then return end
  if isFrozen then
    logStatIncrement(1, "unitsFrozen")
    statsTable["unitsFrozen"] = statsTable["unitsFrozen"] + 1
  end
end)

modapiext.events.onPawnIsShielded:subscribe(function(mission, pawn, isShield)
  if IsTestMechScenario() then return end
  -- TODO: why make the distinction between player and enemy? we don't for fire or freeze
  if isShield and pawn:IsPlayer() then -- if a player unit gained a shield (we handle buildings later)
    logStatIncrement(1, "shields")
    statsTable["shields"] = statsTable["shields"] + 1
  end
end)

-- TODO: waiting for next release of ITB-ModUtils (aka modapiext)
-- modapiext.events.onPawnIsBoosted:subscribe(function(mission, pawn, isBoost)
--   if pawn:IsPlayer() and isBoost then
--     logStatIncrement(1, "boosts")
--     statsTable["boosts"] = statsTable["boosts"] + 1  
--   end  
-- end)

modapiext.events.onPawnIsAcid:subscribe(function(mission, pawn, isAcid)
  if IsTestMechScenario() then return end
  if isAcid and pawn:IsEnemy() then
    logStatIncrement(1, "acidApplied")
    statsTable["acidApplied"] = statsTable["acidApplied"] + 1
  end
end)

modapiext.events.onPawnDamaged:subscribe(function(mission, pawn, damageTaken)
  if IsTestMechScenario() then return end
  if pawn:IsEnemy() then
    logStatIncrement(damageTaken, "damageDealt")
    statsTable["damageDealt"] = statsTable["damageDealt"] + damageTaken
    if vekSelfDamageTable[pawn:GetId()] then
      logStatIncrement(damageTaken, "vekSelfDamage")
      statsTable["vekSelfDamage"] = statsTable["vekSelfDamage"] + damageTaken
      vekSelfDamageTable[pawn:GetId()] = nil
    end
  elseif pawn:IsPlayer() and pawn:GetMechName() ~= "Walking Bomb" and pawn:GetMechName() ~= "Arachnoid" then
    if playerSelfDamageTable[pawn:GetId()] then
      logStatIncrement(damageTaken, "selfDamage")
      statsTable["selfDamage"] = statsTable["selfDamage"] + damageTaken
      playerSelfDamageTable[pawn:GetId()] = nil
    end
    logStatIncrement(damageTaken, "damageTaken")   
    statsTable["damageTaken"] = statsTable["damageTaken"] + damageTaken
  end

  if beamWeaponDamageTable[pawn:GetId()] then
    logStatIncrement(damageTaken, "beamDamage")
    statsTable["beamDamage"] = statsTable["beamDamage"] + damageTaken
    beamWeaponDamageTable[pawn:GetId()] = nil
  end

  if lightningWeaponDamageTable[pawn:GetId()] then
    logStatIncrement(damageTaken, "lightningDamage")
    statsTable["lightningDamage"] = statsTable["lightningDamage"] + damageTaken
    if pawn:IsPlayer() then
      logStatIncrement(damageTaken, "lightningSelfDamage")
      statsTable["lightningSelfDamage"] = statsTable["lightningSelfDamage"] + damageTaken
    end
    lightningWeaponDamageTable[pawn:GetId()] = nil
  end

  if bomblingDamageTable[pawn:GetId()] then
    logStatIncrement(damageTaken, "bombDamage")
    statsTable["bombDamage"] = statsTable["bombDamage"] + damageTaken
    bomblingDamageTable[pawn:GetId()] = nil
  end

  if spiderlingDamageTable[pawn:GetId()] then
    logStatIncrement(damageTaken, "spiderDamage")
    statsTable["spiderDamage"] = statsTable["spiderDamage"] + damageTaken
    spiderlingDamageTable[pawn:GetId()] = nil
  end

end)

modapiext.events.onPawnHealed:subscribe(function(mission, pawn, healingTaken)
  if IsTestMechScenario() then return end
  if pawn:IsPlayer() then
    logStatIncrement(healingTaken, "healing")
    statsTable["healing"] = statsTable["healing"] + healingTaken
  end
end)

modapiext.events.onPawnKilled:subscribe(function(mission, pawn)
  if IsTestMechScenario() then return end
  if pawn:IsEnemy() then
    logStatIncrement(1, "kills")
    statsTable["kills"] = statsTable["kills"] + 1

    local terrain = Board:GetTerrain(pawn:GetSpace())
    local isFlying = _G[pawn:GetType()].Flying
    local isMassive = _G[pawn:GetType()].Massive
    if not isFlying then
      if not isMassive and (terrain == TERRAIN_ACID or terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA) then
        logStatIncrement(1, "vekDrowned")
        statsTable["vekDrowned"] = statsTable["vekDrowned"] + 1
      elseif terrain == TERRAIN_HOLE then
        logStatIncrement(1, "vekPitted")
        statsTable["vekPitted"] = statsTable["vekPitted"] + 1
      end
    end
  end
end)

local function checkEventForStats(pawn, weaponId, event)
  local isValid = Board:IsValid(event.loc)
  local targetPawn = Board:GetPawn(event.loc)
  if isValid then
    if event.iSmoke == EFFECT_CREATE then
      if pawn:IsPlayer() and not Board:IsSmoke(event.loc) then
        logStatIncrement(1, "tilesSmoked")
        statsTable["tilesSmoked"] = statsTable["tilesSmoked"] + 1
      end
    end
    if event.iFire == EFFECT_CREATE then
      if pawn:IsPlayer() and Board:GetFireType(event.loc) == 0 then -- if there's not already fire on this tile
        logStatIncrement(1, "tilesFired")
        statsTable["tilesFired"] = statsTable["tilesFired"] + 1
        -- if this event will damage a forest tile, then we will incorrectly record an extra +1 tilesFired
        if event.iDamage > 0 and Board:GetTerrain(event.loc) == TERRAIN_FOREST then
          skipFireStat = true -- it's hacky, but it totally works
        end
      end
    end
    if event.iShield == EFFECT_CREATE then
      if pawn:IsPlayer() and Board:IsBuilding(event.loc) and not Board:IsShield(event.loc) then
        logStatIncrement(1, "shields")
        statsTable["shields"] = statsTable["shields"] + 1
      end
    end
    if event.iCrack == EFFECT_CREATE then
      local terrain = Board:GetTerrain(event.loc)
      -- IsCrackable() returns true for mountains and ice tiles, but it's the wrong kind of cracking, so we need to do some more checks
      if pawn:IsPlayer() and Board:IsCrackable(event.loc) and terrain ~= TERRAIN_ICE and terrain ~= TERRAIN_MOUNTAIN then
        logStatIncrement(1, "tilesCracked")
        statsTable["tilesCracked"] = statsTable["tilesCracked"] + 1
      end
    end
    if event.iPush ~= DIR_NONE and event.iPush ~= DIR_FLIP and targetPawn then
      -- check if a vek is being pushed onto a valid space
      local endPoint = event.loc + DIR_VECTORS[event.iPush]
      if pawn:IsPlayer() and targetPawn:IsEnemy() and not targetPawn:IsGuarding() and Board:IsValid(endPoint) then
        logStatIncrement(1, "vekPushed")        
        statsTable["vekPushed"] = statsTable["vekPushed"] + 1
      end
    end
    if event.iDamage > 0 then
      if targetPawn then
        if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Prime_Lasermech") then
          beamWeaponDamageTable[targetPawn:GetId()] = true
        end

        if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Prime_Lightning") then
          lightningWeaponDamageTable[targetPawn:GetId()] = true
        end

        if pawn:IsPlayer() and targetPawn:IsPlayer() and not targetPawn:IsShield()
        and targetPawn:GetMechName() ~= "Walking Bomb" and targetPawn:GetMechName() ~= "Arachnoid" then
          playerSelfDamageTable[targetPawn:GetId()] = true
        end
        
        if pawn:IsEnemy() and targetPawn:IsEnemy() and not targetPawn:IsShield() then
          vekSelfDamageTable[targetPawn:GetId()] = true
          if Board:IsDeadly(event, targetPawn) then
            -- we miss out on vek with weapons that can shoot through shields, but I don't think any of those exist (maybe in other mods?)
            logStatIncrement(1, "vekSelfKills")
            statsTable["vekSelfKills"] = statsTable["vekSelfKills"] + 1
          end
        end

        if targetPawn:IsFrozen() and not targetPawn:IsShield() then -- we'll handle buildings a little further down
          logStatIncrement(event.iDamage, "damageBlockedWithIce")
          statsTable["damageBlockedWithIce"] = statsTable["damageBlockedWithIce"] + event.iDamage
        end

        if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "DeployUnit_SelfDamage") and pawn:GetId() ~= targetPawn:GetId() then
          bomblingDamageTable[targetPawn:GetId()] = true
        end

        if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "DeployUnit_AracnoidAtk") and pawn:GetId() ~= targetPawn:GetId() then
          spiderlingDamageTable[targetPawn:GetId()] = true
        end

        if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Ranged_Arachnoid") and event.bKO_Effect then
          logStatIncrement(1, "spidersCreated")
          statsTable["spidersCreated"] = statsTable["spidersCreated"] + 1
        end

      else
        if Board:IsFrozen(event.loc) and not Board:IsShield(event.loc) then
          logStatIncrement(event.iDamage, "damageBlockedWithIce")
          statsTable["damageBlockedWithIce"] = statsTable["damageBlockedWithIce"] + event.iDamage
        end
      end

      if Board:IsCracked(event.loc) then
        logStatIncrement(1, "tilesDestroyed")
        statsTable["tilesDestroyed"] = statsTable["tilesDestroyed"] + 1
      end

    end

  end
end

local function handleSkillStart(mission, pawn, weaponId, p1, p2)
  -- LOG("handleSkillStart: " .. pawn:GetMechName() .. " is using weaponId " .. weaponId)
  local fx = _G[weaponId]:GetSkillEffect(p1, p2)
  if modapiext.weapon:isTipImage() or IsTestMechScenario() then return end -- don't record stats when playing animated tooltips or in the testing scenario
  
  -- loop through effects, which are typically player attacks
  for eventIndex = 1, fx.effect:size() do
    local event = fx.effect:index(eventIndex)
    checkEventForStats(pawn, weaponId, event)
  end

  -- loop through queued effects, which are typically vek attacks
  for eventIndex = 1, fx.q_effect:size() do
    local event = fx.q_effect:index(eventIndex)
    checkEventForStats(pawn, weaponId, event)
  end

  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Ranged_Rockthrow") then
    logStatIncrement(1, "rocksLaunched")
    statsTable["rocksLaunched"] = statsTable["rocksLaunched"] + 1
  end

  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Prime_Leap") then
    local distanceTraveled = p1:Manhattan(p2)
    logStatIncrement(distanceTraveled, "leapDistance")
    statsTable["leapDistance"] = statsTable["leapDistance"] + distanceTraveled
  end

  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Prime_Punchmech") then
    local distanceTraveled = p1:Manhattan(p2)
    if Board:GetPawn(p2) or Board:IsBuilding(p2) then
      -- if you target a pawn/building, then the punch mech will travel to the tile just before the target, so subtract 1 to get the actual distance traveled
      distanceTraveled = distanceTraveled - 1
    end
    if distanceTraveled > 0 then
      logStatIncrement(distanceTraveled, "punchDistance")
      statsTable["punchDistance"] = statsTable["punchDistance"] + distanceTraveled
    end
  end

  -- works the same as punchDistance
  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Vek_Beetle") then
    local distanceTraveled = p1:Manhattan(p2)
    if Board:GetPawn(p2) or Board:IsBuilding(p2) then distanceTraveled = distanceTraveled - 1 end
    if distanceTraveled > 0 then
      logStatIncrement(distanceTraveled, "ramDistance")
      statsTable["ramDistance"] = statsTable["ramDistance"] + distanceTraveled
    end
  end

  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Ranged_DeployBomb") then
    -- the upgrade to shoot 2 bombs makes it a 2-click weapon, which we handle under a different hook
    logStatIncrement(1, "bombsCreated")
    statsTable["bombsCreated"] = statsTable["bombsCreated"] + 1
  end
end

local function handle2ClickSkillStart(mission, pawn, weaponId, p1, p2, p3)
  -- LOG("handle2ClickSkillStart: " .. pawn:GetMechName() .. " is using " .. weaponId .. " at " .. p2:GetString() .. " and " .. p3:GetString())
  if modapiext.weapon:isTipImage() or IsTestMechScenario() then return end -- don't record stats when playing animated tooltips or in the testing scenario
  if pawn:IsPlayer() and modApi:stringStartsWith(weaponId, "Ranged_DeployBomb") then
    logStatIncrement(2, "bombsCreated")
    statsTable["bombsCreated"] = statsTable["bombsCreated"] + 2
  end
end

modApi.events.onFrameDrawn:subscribe(function()
  if not Game then return end
  if defeated then return end

  local currentGridHealth = Game:GetPower():GetValue()
  if currentGridHealth <= 0 then
    -- we normally check for grid damage in onMissionUpdate(), but that event stops firing when you lose the game.
    -- we need to check here if grid health changed so we can correctly record the last bit of grid damage
    if currentGridHealth ~= prevGridHealth then
      local damageTaken = prevGridHealth - currentGridHealth
      logStatIncrement(damageTaken, "gridDamage")
      statsTable["gridDamage"] = statsTable["gridDamage"] + damageTaken
    end
    defeated = true
    local gameId = uuid()
    local difficulty = GetDifficulty()
    local time = os.time()
    LOG("GAME OVER, difficulty is " .. difficulty .. " and we secured " .. statsTable["islandsSecured"] .. " islands")
    saveFinishedGameStats(gameId, false, difficulty, statsTable["islandsSecured"], time)
  end

  local mission = GetCurrentMission()
  if Board and mission then
    local missionId = mission["ID"]
    if modApi:stringStartsWith(missionId, "Mission_Final") then -- the final mission has two phases, "Mission_Final" and "Mission_Final_Cave"
      local playerPawns = Board:GetPawns(TEAM_PLAYER)
      local deadCount = 0
      for i = 1, playerPawns:size() do
        local pawn = Board:GetPawn(playerPawns:index(i))
        if pawn:IsMech() and pawn:IsDead() then
          deadCount = deadCount + 1
        end
      end
      if deadCount == 3 then
        defeated = true
        local gameId = uuid()
        local difficulty = GetDifficulty()
        local time = os.time()
        LOG("GAME OVER, difficulty is " .. difficulty .. " and we secured " .. statsTable["islandsSecured"] .. " islands")
        saveFinishedGameStats(gameId, false, difficulty, statsTable["islandsSecured"], time)
      end 
    end
  end

end)

modapiext.events.onSkillStart:subscribe(handleSkillStart)
modapiext.events.onQueuedSkillStart:subscribe(handleSkillStart)
modapiext.events.onFinalEffectStart:subscribe(handle2ClickSkillStart)

modApi.events.onMainMenuEntered:subscribe(function()
  statsTable = nil
  defeated = false
end)