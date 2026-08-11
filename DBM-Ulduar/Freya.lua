local mod	= DBM:NewMod("Freya", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221031103116")

mod:SetCreatureID(32906)
--mod:RegisterCombat("combat")
mod:RegisterCombat("yell", L.YellPullNormal, L.YellPullHard)
mod:RegisterKill("yell", L.YellKill)
mod:SetUsedIcons(4, 5, 6, 7, 8)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 62437 62859",
	"SPELL_CAST_SUCCESS 62678 62873 62619 63571 62589 64587 64650 62451 62865",
	"SPELL_AURA_APPLIED 62283 62438 62439 62861 62862 62930 62451 62865",
	"SPELL_AURA_REMOVED 62519 62861 62438 63571 62589",
	"UNIT_DIED",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_EMOTE"
)

-- Trash: 33430 Guardian Lasher (flower)
-- 33355 (nymph)
-- 33354 (tree)

--
-- Elder Stonebark (ground tremor / fist of stone)
-- Elder Brightleaf (unstable sunbeam)

-- General
local warnSimulKill				= mod:NewAnnounce("WarnSimulKill", 1)

local timerEnrage				= mod:NewBerserkTimer(600)

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnNatureFury			= mod:NewTargetAnnounce(63571, 2)

local specWarnLifebinder		= mod:NewSpecialWarningSwitch(62584, "Dps", nil, nil, 1, 2)
local specWarnNatureFury		= mod:NewSpecialWarningMoveAway(63571, nil, nil, nil, 1, 2)
local yellNatureFury			= mod:NewYell(63571)

local timerAlliesOfNature		= mod:NewNextTimer(60, 62678, nil, nil, nil, 1, 62947, DBM_COMMON_L.IMPORTANT_ICON..DBM_COMMON_L.DAMAGE_ICON)
local timerSimulKill			= mod:NewTimer(11, "TimerSimulKill", nil, nil, nil, 5, DBM_COMMON_L.DAMAGE_ICON, nil, nil, nil, nil, nil, nil, 62678)
local timerNatureFury			= mod:NewTargetTimer(10, 63571, nil, nil, nil, 3)
local timerLifebinderCD			= mod:NewNextTimer(45, 62584, nil, nil, nil, 1, nil, DBM_COMMON_L.IMPORTANT_ICON)

mod:AddRangeFrameOption(8, 63571)
mod:AddSetIconOption("SetIconOnFury", 63571, false, false, {7, 8})

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnPhase2				= mod:NewPhaseAnnounce(2, 3, nil, nil, nil, nil, nil, 2)

local specWarnNatureBombSummon	= mod:NewSpecialWarningMove(64604)

local timerNextNatureBombSummon	= mod:NewNextTimer(12, 64604, nil, nil, nil, 2)
local timerNatureBombExplosion	= mod:NewCastTimer(6, 64587, 34539, nil, nil, 2)

-- Hard Mode
mod:AddTimerLine(DBM_COMMON_L.HEROIC_ICON..DBM_CORE_L.HARD_MODE)
local warnIronRoots				= mod:NewTargetNoFilterAnnounce(62438, 2) -- Hard mode Elder Ironbranch Alive

local yellIronRoots				= mod:NewYell(62438)
local specWarnGroundTremor		= mod:NewSpecialWarningCast(62859, "SpellCaster", nil, 2, 1, 2)	-- Hard mode Elder Stonebark Alive
local specWarnUnstableBeam		= mod:NewSpecialWarningMove(62865, nil, nil, nil, 1, 2)	-- Hard mode Elder Brightleaf Alive

local timerGroundTremorCD		= mod:NewCDTimer(25, 62859, nil, nil, nil, 2)
local timerIronRootsCD			= mod:NewCDTimer(45, 62438, nil, nil, nil, 3) 
local timerUnstableBeamCD		= mod:NewCDTimer(38, 62865, nil, nil, nil, 2) -- Hard mode Sun Beam.

mod:AddSetIconOption("SetIconOnRoots", 62438, false, false, {6, 5, 4})

mod:GroupSpells(64587, 64604) -- Nature Bomb, internal Nature Bomb summon ID

local adds = {}
mod.vb.altIcon = true
mod.vb.iconId = 6
mod.vb.waves = 0
mod.vb.isHardMode = false
mod.vb.waveTreshold = 0
mod.vb.currentWave = 0

function mod:OnCombatStart(delay)
	self.vb.altIcon = true
	self.vb.iconId = 6
	
	self.vb.waves = 0
	mod.vb.currentWave = 0
	mod.vb.waveTreshold = 0
	
	self:SetStage(1)
	
	timerEnrage:Start(-delay)
	timerAlliesOfNature:Start(10-delay)
	timerLifebinderCD:Start(30-delay)
	
	table.wipe(adds)
end

function mod:OnCombatEnd(wipe)
	if not wipe then
		if DBT:GetBar(L.TrashRespawnTimer) then
			DBT:CancelBar(L.TrashRespawnTimer)
		end
	end
	if self.Options.HealthFrame then
		DBM.BossHealth:Hide()
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(62437, 62859) then
		specWarnGroundTremor:Show()
		specWarnGroundTremor:Play("stopcast")
		timerGroundTremorCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(63571, 62589) then -- Nature's Fury
		if self.Options.SetIconOnFury then
			self.vb.altIcon = not self.vb.altIcon	--Alternates between Skull and X
			self:SetIcon(args.destName, self.vb.altIcon and 7 or 8, 10)
		end
		if args:IsPlayer() then -- only cast on players; no need to check destFlags
			specWarnNatureFury:Show()
			specWarnNatureFury:Play("runout")
			yellNatureFury:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(8)
			end
		else
			warnNatureFury:Show(args.destName)
		end
		timerNatureFury:Start(args.destName)
	elseif args:IsSpellID(64587, 64650) then -- Nature Bomb
		if self:AntiSpam(5, 64650) and self:IsInCombat() then

			specWarnNatureBombSummon:Schedule(12)
			timerNatureBombExplosion:Schedule(12)
			timerNextNatureBombSummon:Start()
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(62283, 62438, 62439, 62861, 62862, 62930) then --  Roots
		warnIronRoots:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			yellIronRoots:Yell()
		end
		self.vb.iconId = self.vb.iconId - 1
		if self.Options.SetIconOnRoots then
			self:SetIcon(args.destName, self.vb.iconId, 15)
		end
	elseif args:IsSpellID(62451, 62865) then -- Unstable Energy (Sun Beam)
	
		if args:IsPlayer() then
			specWarnUnstableBeam:Show()
			specWarnUnstableBeam:Play("runaway")
		end
		
		if self:AntiSpam(10, 2) then 
			timerUnstableBeamCD:Start()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 62519 then
		self:SetStage(2)
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		
		timerAlliesOfNature:Cancel()
		
		timerNextNatureBombSummon:Start(5)
		
		specWarnNatureBombSummon:Schedule(5)
		timerNatureBombExplosion:Schedule(5)
		
	elseif args:IsSpellID(62861, 62438) then -- Roots
		if self.Options.SetIconOnRoots then
			self:RemoveIcon(args.destName)
		end
		self.vb.iconId = self.vb.iconId + 1
	elseif args:IsSpellID(63571, 62589) then -- Nature's Fury
		if self.Options.SetIconOnFury then
			self:RemoveIcon(args.destName)
		end
		if args:IsPlayer() and self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 33202 or cid == 32916 or cid == 32919 then -- elementals
	
		adds[cid] = nil
		mod.vb.waveTreshold = mod.vb.waveTreshold - 1
	
		if mod.vb.waveTreshold == 0 then 
			timerSimulKill:Stop()
			timerAlliesOfNature:Start(16)
		end
	
		if self.Options.HealthFrame then
			DBM.BossHealth:RemoveBoss(cid)
		end
		if self:AntiSpam(11, 1) then
			timerSimulKill:Start()
			warnSimulKill:Show()
		end

	elseif cid == 32918 then -- detonating lasher
		mod.vb.waveTreshold = mod.vb.waveTreshold - 1
		
		if mod.vb.waveTreshold == 0 then 
			timerAlliesOfNature:Start(5)
		end
	elseif cid == 33203 then -- ancient conservator
		mod.vb.waveTreshold = mod.vb.waveTreshold - 1
		
		if mod.vb.waveTreshold == 0 then 
			timerAlliesOfNature:Start(5)
		end
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg, mobName)
	if msg == L.Ress then

		if mobName == L.StormLasher then
			mod.vb.waveTreshold = mod.vb.waveTreshold + 1
			DBM.BossHealth:AddBoss(32919, L.StormLasher)
			
		elseif mobName == L.Snaplasher then
			mod.vb.waveTreshold = mod.vb.waveTreshold + 1
			DBM.BossHealth:AddBoss(32916, L.Snaplasher)
			
		elseif mobName == L.WaterSpirit then
			mod.vb.waveTreshold = mod.vb.waveTreshold + 1
			DBM.BossHealth:AddBoss(33202, L.WaterSpirit)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPullNormal then
		self.vb.isHardMode = false
	
	elseif msg == L.YellPullHard then
		self.vb.isHardMode = true
		timerGroundTremorCD:Start(35)
		timerIronRootsCD:Start(20)
		timerUnstableBeamCD:Start(60)
		
	elseif msg == L.SpawnYell then -- elementals
		timerAlliesOfNature:Start()
		mod.vb.waveTreshold = 3
		mod.vb.currentWave = 1
		
		if self.Options.HealthFrame then
			DBM.BossHealth:AddBoss(33202, L.WaterSpirit)
			DBM.BossHealth:AddBoss(32916, L.Snaplasher)
			DBM.BossHealth:AddBoss(32919, L.StormLasher)
		end
		adds[33202] = true
		adds[32916] = true
		adds[32919] = true
		
	elseif msg == L.YellAdds1 then -- ancient conservator
		timerAlliesOfNature:Start()
		mod.vb.waveTreshold = 1
		mod.vb.currentWave = 2
		
	elseif msg == L.YellAdds2 then -- detonating lashers
		timerAlliesOfNature:Start()
		mod.vb.waveTreshold = 10
		mod.vb.currentWave = 3
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)

	if strmatch(msg, L.EmoteIronRoot) then
		timerIronRootsCD:Start()
		
	elseif strmatch(msg, L.EmoteLGift) then
		specWarnLifebinder:Show()
		specWarnLifebinder:Play("targetchange")
		timerLifebinderCD:Start()
	end
end