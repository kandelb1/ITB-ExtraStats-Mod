local game = nil
local statsTable = {}

local vekSelfDamageTable = {}
local playerSelfDamageTable = {}
local beamWeaponDamageTable = {}
local lightningWeaponDamageTable = {}
local prevGridHealth = nil

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

-- local function getCurrentTime()
--   return os.time()
-- end

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
  local answer = {}
  --SQUAD-SPECIFIC STATS

  -- rift walkers
  answer["vekPushed"] = 0
  answer["environmentKills"] = 0
  answer["pushDamage"] = 0

  -- zenith guard COMPLETE
  answer["selfDamage"] = 0
  answer["shields"] = 0
  answer["beamDamage"] = 0 

  --steel judoka
  answer["vekPushed"] = 0
  answer["vekSelfDamage"] = 0
  answer["vekSelfKills"] = 0 -- incomplete

  -- rusting hulks
  answer["tilesSmoked"] = 0
  answer["stormDamage"]= 0 -- incomplete
  answer["attacksCancelled"] = 0

  -- blitzkrieg
  answer["lightningDamage"] = 0 -- complete
  -- answer["chainSelfDamage"] = 0 -- incomplete
  -- answer["rocksLaunched"] = 0 -- incomplete

  -- flame behemoths
  answer["unitsFired"] = 0
  answer["tilesFired"] = 0
  answer["fireDamage"] = 0 -- incomplete
  answer["teleportDistance"] = 0 -- incomplete

  -- frozen titans
  answer["unitsFrozen"] = 0
  answer["pushDamage"]= 0
  answer["damageBlockedWithIce"] = 0 -- incomplete

  -- bombermechs
  answer["vekBlocked"] = 0
  answer["bombsCreated"] = 0 -- incomplete
  answer["bombDamage"] = 0 -- incomplete

  -- mist eaters
  answer["healing"] = 0
  answer["tilesSmoked"] = 0
  answer["attacksCancelled"] = 0

  -- cataclysm
  answer["tilesCracked"] = 0 -- incomplete
  answer["tilesDestroyed"] = 0
  answer["vekPitted"] = 0

  -- hazardous mechs
  answer["selfDamage"] = 0
  answer["healing"] = 0
  answer["pushDamage"] = 0

  -- arachnophiles
  answer["vekBlocked"] = 0
  answer["spidersCreated"] = 0 -- incomplete
  answer["richocetDoubleKills"] = 0 -- incomplete

  -- heat sinkers
  answer["boosts"] = 0 -- incomplete
  answer["unitsFired"] = 0
  answer["fireDamage"] = 0 -- incomplete

  -- secret squad
  -- ??????
  
  -- GENERAL STATS
  answer["kills"] = 0 -- complete
  answer["damage"] = 0 -- complete
  answer["damageTaken"] = 0 -- complete
  answer["selfDamage"] = 0 -- complete
  answer["healing"] = 0 -- complete
  answer["gridResists"] = 0 -- complete
  answer["gridDamage"] = 0 -- incomplete BUG: grid can change between missions, so make sure to update it in onMissionChanged or whatever
  answer["vekPushed"] = 0 -- complete
  answer["vekBlocked"] = 0 -- complete
  answer["vekDrowned"] = 0 -- complete
  answer["vekPitted"] = 0 -- complete

  -- OTHER
  answer["squadId"] = -1
  answer["difficulty"] = -1
  answer["islandsSecured"] = 0

  return answer
end


modApi.events.onMissionUpdate:subscribe(function()
  if Game:IsEvent(7) then -- grid damaged
    -- TODO: if you take grid damage that causes you to lose the game, the games ends before this event is fired
    -- so maybe we need to manually add 1 to gridDamage when we lose??
    local currentGridHealth = game:GetPower():GetValue()
    local damageTaken = prevGridHealth - currentGridHealth
    LOG("+" .. damageTaken .. " grid damage taken!")
    statsTable["gridDamage"] = statsTable["gridDamage"] + damageTaken
    prevGridHealth = currentGridHealth
  end
  if Game:IsEvent(9) then -- grid resisted
    LOG("+1 grid resists!")
    statsTable["gridResists"] = statsTable["gridResists"] + 1
  end
  if Game:IsEvent(16) then -- vek blocked
    LOG("+1 to vekBlocked")
    statsTable["vekBlocked"] = statsTable["vekBlocked"] + 1
  end
  if Game:IsEvent(26) then -- forest set on fire
    LOG("+1 to tilesFired")
    statsTable["tilesFired"] = statsTable["tilesFired"] + 1
  end
  if Game:IsEvent(27) then -- sand turned to smoke
    LOG("+1 to tilesSmoked")
    statsTable["tilesSmoked"] = statsTable["tilesSmoked"] + 1
  end
	-- EVENT_SOMETHING_WITH_SKILL_TARGETING_1 = 1
	-- -- EVENT_ENEMY_KILLED = 2
	-- -- EVENT_MOUNTAIN_DESTROYED = 3
	-- EVENT_ENEMY_TURN = 4
	-- EVENT_PLAYER_TURN = 5
	-- EVENT_GRID_RESISTED = 9
	-- EVENT_GRID_DAMAGED = 7
	-- EVENT_SOMETHING_WITH_SKILL_TARGETING_2 = 11
	-- EVENT_MINOR_ENEMY_KILLED = 12
	-- EVENT_SOMETHING_WITH_UNIT = 13
	-- EVENT_TURN_START = 14
	-- -- EVENT_SPAWNBLOCKED = 16
	-- EVENT_1_GRID_REMAINING = 17
	-- -- EVENT_ACID_DESTROYED = 18
	-- EVENT_ENEMY_DAMAGED = 19
	-- EVENT_ENEMY_KILLED_2 = 21
	-- EVENT_MECH_DAMAGED = 24
	-- EVENT_MECH_DESTROYED = 25
	-- EVENT_FOREST_SET_ON_FIRE = 26
	-- EVENT_DESERT_TURNED_TO_SMOKE = 27
	-- EVENT_UNIT_DESTROYED = 28
	-- EVENT_MECH_REDUCED_TO_1_HP = 29
	-- EVENT_MECH_DESTROYED_2 = 30
	-- EVENT_MECH_REVIVED = 31
	-- EVENT_MECH_REPAIRED = 32
	-- EVENT_1_2_GRID_REMAINING = 34
	-- EVENT_POD_DESTROYED = 37
	-- EVENT_ATTACK_CANCELED_WITH_SMOKE = 42
	-- EVENT_ENEMY_STEPPED_ON_MINE = 43
	-- EVENT_UNIQUE_BUILDING_DESTROYED = 55
	-- -- EVENT_REPAIR_PICKUP = 72
	-- -- EVENT_REPAIR_UNDO = 73
  
  -- the only one I can see needing is ATTACK_CANCELLED_WITH_SMOKE, but I think I can do that by myself anyway
end)

local function saveStats()
  LOG("saveStats is saving: " .. dump(statsTable))
  modApi:writeModData("current", statsTable)
end

local function saveFinishedGameStats(gameId, victory, difficulty, islandsSecured, timeFinished)
  LOG("finished game, recording stats under gameId game" .. gameId)
  statsTable["gameId"] = gameId
  statsTable["victory"] = victory
  statsTable["difficulty"] = difficulty
  statsTable["islandsSecured"] = islandsSecured
  statsTable["timeFinished"] = timeFinished
  sdlext.config(
    "modcontent.lua",
    function(obj)
      -- obj["finishedGames"] SHOULD always exist (see init.lua)
      local index = #obj["finishedGames"] + 1
      obj["finishedGames"][index] = statsTable
    end
  )
-- modApi:writeModData("game" .. gameId, statsTable)
end

local function loadStats()
  local answer = modApi:readModData("current")
  LOG("loadStats returning: " .. dump(answer))
  return answer
end

modApi.events.onGameClassInitialized:subscribe(function(gameClass, theGame)
  LOG("onGameClassInitialized!")
  game = theGame
end)

modApi.events.onPreStartGame:subscribe(function() 
  LOG("onPreStartGame EVENT")
  -- starting new game, so get new stats and write them to the file
  statsTable = initializeStatsTable()
  saveStats()
end)

modApi.events.onPostStartGame:subscribe(function() 
  LOG("onPostStartGame EVENT")
  LOG("setting squad id to " .. GAME.additionalSquadData.squadIndex) 
  statsTable["squadId"] = GAME.additionalSquadData.squadIndex
end)

-- loading into game
modapiext.events.onGameLoaded:subscribe(function(mission)
  LOG("onGameLoaded EVENT")
  statsTable = loadStats()
  LOG("setting prevGridHealth to " .. game:GetPower():GetValue())
  prevGridHealth = game:GetPower():GetValue()
end)

-- saving game (which happens after every action?)
modApi.events.onSaveGame:subscribe(function() 
  LOG("onSaveGame EVENT")
  -- RegionData is sometimes nil???
  if RegionData then
    statsTable["islandsSecured"] = 0
    for i = 0, 3 do
      if RegionData["island"..i].secured then
        statsTable["islandsSecured"] = statsTable["islandsSecured"] + 1
      end
    end
  end
  saveStats()
end)

modApi.events.onGameVictory:subscribe(function(difficulty, islandsSecured, squadId)
  saveFinishedGameStats(uuid(), true, difficulty, islandsSecured, os.time())
end)

modApi.events.onMissionStart:subscribe(function(mission)
  prevGridHealth = game:GetPower():GetValue()
  LOG("updating grid power to " .. prevGridHealth)
end)

-- fires on mission win
modApi.events.onMissionEnd:subscribe(function(mission)
  LOG("onMissionEnd()")
  -- maybe we can detect if the final mission is lost by checking if all player mechs are dead here?
end)

-- this fires on mission loss
modApi.events.onMissionChanged:subscribe(function(mission)
  LOG("onMissionChanged(), power level is ".. game:GetPower():GetValue())
  if game:GetPower():GetValue() <= 0 then
    LOG("YOU LOST THE GAME")
    local gameId = uuid()
    local difficulty = GetDifficulty()
    -- local islandsSecured = 0
    -- for i = 0, 3 do
    --   if GAME.RegionData["island"..i].secured then
    --     islandsSecured = islandsSecured + 1
    --   end
    -- end
    -- local timeFinished = os.time(os.date("!*t")) -- TODO: not sure if this works
    local timeFinished = os.time()
    saveFinishedGameStats(gameId, false, difficulty, statsTable["islandsSecured"], timeFinished)
  end
end)

modApi.events.onGameStateChanged:subscribe(function(currentGameState, oldGameState)
  LOG("game state changing from " .. oldGameState .. " to " .. currentGameState)
end)

-- subscribe to the events we need to
modapiext.events.onPawnIsFire:subscribe(function(mission, pawn, isFire)
  if isFire then
    LOG("+1 to unitsFired")
    statsTable["unitsFired"] = statsTable["unitsFired"] + 1
  end
end)

modapiext.events.onPawnIsFrozen:subscribe(function(mission, pawn, isFrozen)
  if isFrozen then
    LOG("+1 to unitsFrozen")
    statsTable["unitsFrozen"] = statsTable["unitsFrozen"] + 1
  end
end)

modapiext.events.onPawnIsShielded:subscribe(function(mission, pawn, isShield)
  -- TODO: why make the distinction between player and enemy? we don't for fire or freeze
  if isShield and pawn:IsPlayer() then -- if a player unit gained a shield (we handle buildings later)
    LOG("+1 to shields")
    statsTable["shields"] = statsTable["shields"] + 1
  end
end)

modapiext.events.onPawnDamaged:subscribe(function(mission, pawn, damageTaken)
  LOG("onPawnDamaged()")
  if pawn:IsEnemy() then
    LOG("+" .. damageTaken .. " damage")
    statsTable["damage"] = statsTable["damage"] + damageTaken
    if vekSelfDamageTable[pawn:GetId()] then
      LOG("+" .. damageTaken .. " to vek self damage!")
      statsTable["vekSelfDamage"] = statsTable["vekSelfDamage"] + damageTaken
      vekSelfDamageTable[pawn:GetId()] = nil
    end
  elseif pawn:IsPlayer() then
    if playerSelfDamageTable[pawn:GetId()] then
      LOG("+" .. damageTaken .. " self damage!")
      statsTable["selfDamage"] = statsTable["selfDamage"] + 1
      playerSelfDamageTable[pawn:GetId()] = nil
    end
    LOG("+" .. damageTaken .. " to damage taken!")    
    statsTable["damageTaken"] = statsTable["damageTaken"] + damageTaken
  end

  if beamWeaponDamageTable[pawn:GetId()] then
    LOG("+" .. damageTaken .. " to beam weapon damage")
    statsTable["beamDamage"] = statsTable["beamDamage"] + damageTaken
    beamWeaponDamageTable[pawn:GetId()] = nil
  end

  if lightningWeaponDamageTable[pawn:GetId()] then
    LOG("+" .. damageTaken .. " to lightning weapon damage")
    statsTable["lightningDamage"] = statsTable["lightningDamage"] + damageTaken
    lightningWeaponDamageTable[pawn:GetId()] = nil
  end

end)

modapiext.events.onPawnHealed:subscribe(function(mission, pawn, healingTaken)
  if pawn:IsPlayer() then
    LOG("+" .. healingTaken .. " healing")
    statsTable["healing"] = statsTable["healing"] + healingTaken
  end
end)

modapiext.events.onPawnKilled:subscribe(function(mission, pawn)
  if pawn:IsEnemy() then
    LOG("+1 to kills")
    statsTable["kills"] = statsTable["kills"] + 1

    local terrain = Board:GetTerrain(pawn:GetSpace())
    local isFlying = _G[pawn:GetType()].Flying
    local isMassive = _G[pawn:GetType()].Massive
    if not isFlying then
      if not isMassive and (terrain == TERRAIN_ACID or terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA) then
        LOG("+1 to vekDrowned")
        statsTable["vekDrowned"] = statsTable["vekDrowned"] + 1
      elseif terrain == TERRAIN_HOLE then
        LOG("+1 to vekPitted")
        statsTable["vekPitted"] = statsTable["vekPitted"] + 1
      end
    end
  end
end)

-- pawn: the pawn using the skill
-- event: one of the events of the skill
local function checkEventForStats(pawn, weaponId, event)
  local isValid = Board:IsValid(event.loc)
  local targetPawn = Board:GetPawn(event.loc)
  if isValid then
    -- TODO: make it a chain of elseifs? because if an attack is applying smoke, it will cancel the fire but we are still recording +1 tilesFired
    if event.iSmoke == EFFECT_CREATE then
      if pawn:IsPlayer() and not Board:IsSmoke(event.loc) then
        LOG("+1 to tilesSmoked")
        statsTable["tilesSmoked"] = statsTable["tilesSmoked"] + 1
      end
      if targetPawn and targetPawn:GetQueued() and not targetPawn:IsIgnoreSmoke() then -- TODO: aren't some enemies immune to smoke?
        -- spider enemy can spawn spiderlings which are immune to smoke
        LOG("+1 to attacksCancelled")
        statsTable["attacksCancelled"] = statsTable["attacksCancelled"] + 1
      end
    end
    if event.iFire == EFFECT_CREATE then
      -- we have a pawnIsFire hook, so we can check 
      if pawn:IsPlayer() and Board:GetFireType(event.loc) == 0 then
        LOG("+1 to tilesFired")
        statsTable["tilesFired"] = statsTable["tilesFired"] + 1
      end
    end
    if event.iShield == EFFECT_CREATE then
      if pawn:IsPlayer() and Board:IsBuilding(event.loc) and not Board:IsShield(event.loc) then
        LOG("+1 to shields")
        statsTable["shields"] = statsTable["shields"] + 1
      end
    end
    if event.iCrack == EFFECT_CREATE then
      -- TODO: IsCrackable() is not 100% reliable
      -- iscrackable returns true for mountains and ice tiles but those can't be cracked
      if pawn:IsPlayer() and Board:IsCrackable(event.loc) then
        LOG("+1 to tilesCracked")
        statsTable["tilesCracked"] = statsTable["tilesCracked"] + 1
      end
    end
    if event.iPush ~= 4 and targetPawn then
      -- check if a vek is being pushed onto a valid space
      local endPoint = event.loc + DIR_VECTORS[event.iPush]
      if targetPawn:IsEnemy() and not targetPawn:IsGuarding() and Board:IsValid(endPoint) then
        LOG("+1 to vekPushed")
        statsTable["vekPushed"] = statsTable["vekPushed"] + 1
        
        -- now check if the vek will drown or fall into a pit
        -- if not targetPawn:IsFlying() then
        --   local terrain = Board:GetTerrain(endPoint)
        --   if not targetPawn:IsMassive() and (terrain == TERRAIN_ACID or terrain == TERRAIN_LAVA or terrain == TERRAIN_WATER) then
        --     LOG("+1 to vekDrowned")
        --     statsTable["vekDrowned"] = statsTable["vekDrowned"] + 1
        --   elseif terrain == TERRAIN_HOLE then
        --     LOG("+1 to vekPitted")
        --     statsTable["vekPitted"] = statsTable["vekPitted"] + 1
        --   end
        -- end
      end
    end
    if event.iDamage > 0 then

      -- test for player self damage and vek self damage
      if targetPawn then
        if modApi:stringStartsWith(weaponId, "Prime_Lasermech") then        
          LOG("marking pawn " .. targetPawn:GetMechName() .. " for beam weapon damage")
          beamWeaponDamageTable[targetPawn:GetId()] = true
        end

        if modApi:stringStartsWith(weaponId, "Prime_Lightning") then
          LOG("marking pawn " .. targetPawn:GetMechName() .. " for lightning weapon damage")
          lightningWeaponDamageTable[targetPawn:GetId()] = true
        end

        if pawn:IsPlayer() and targetPawn:IsPlayer() and not targetPawn:IsShield() then
          LOG("marking targetPawn " .. targetPawn:GetMechName() .. " to record self damage")
          playerSelfDamageTable[targetPawn:GetId()] = true
        end
        if pawn:IsEnemy() and targetPawn:IsEnemy() and not targetPawn:IsShield() then
          LOG("marking targetPawn " .. targetPawn:GetMechName() .. " to record vek self damage")
          vekSelfDamageTable[targetPawn:GetId()] = true
        end
      end

      -- test for damaging a cracked tile
      if Board:IsCracked(event.loc) then
        LOG("+1 to tilesDestroyed")
        statsTable["tilesDestroyed"] = statsTable["tilesDestroyed"] + 1
      end

      -- test for creating smoke from a sand tile or creating fire from a forest tile
      -- if Board:GetTerrain(event.loc) == TERRAIN_SAND then
      --   LOG("+1 to tilesSmoked")
      --   statsTable["tilesSmoked"] = statsTable["tilesSmoked"] + 1
      -- elseif Board:GetTerrain(event.loc) == TERRAIN_FOREST then
      --   LOG("+1 to tilesFired")
      --   statsTable["tilesFired"] = statsTable["tilesFired"] + 1
      -- end
    end
  end
end

local function handleSkillStart(mission, pawn, weaponId, p1, p2)
  LOG("custom handler handleSkillStart: " .. pawn:GetMechName() .. " is using weaponId " .. weaponId)
  local fx = _G[weaponId]:GetSkillEffect(p1, p2)
  LOG("Looping through " .. fx.effect:size() .. " events")
  for eventIndex = 1, fx.effect:size() do
    local event = fx.effect:index(eventIndex)
    checkEventForStats(pawn, weaponId, event)
  end
  LOG("Next, looping through " .. fx.q_effect:size() .. " queued events")
  for eventIndex = 1, fx.q_effect:size() do
    local event = fx.q_effect:index(eventIndex)
    checkEventForStats(pawn, weaponId, event)
  end
end

modapiext.events.onSkillStart:subscribe(handleSkillStart)
modapiext.events.onQueuedSkillStart:subscribe(handleSkillStart)

modApi.events.onMainMenuEntered:subscribe(function()
  game = nil
  statsTable = nil
end)