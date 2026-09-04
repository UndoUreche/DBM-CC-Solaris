local mod	= DBM:NewMod("Mimiron", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221011214859")
mod:SetCreatureID(33432)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)
mod:SetHotfixNoticeRev(20220823000000)

mod:RegisterCombat("combat_yell", L.YellPull)
mod:RegisterCombat("yell", L.YellHardPull)
mod:RegisterKill("yell", L.YellKilled)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 63631 64529 62997 64570 64623 64383",
	"SPELL_CAST_SUCCESS 63414 65192",
	"SPELL_AURA_APPLIED 63666 65026 64529 62997 64616 64570 64533",
	"SPELL_AURA_REMOVED 63666 65026",
	"SPELL_SUMMON 64444",
	"UNIT_SPELLCAST_SUCCEEDED",
	"CHAT_MSG_LOOT"
)

--General
local timerEnrage					= mod:NewBerserkTimer(900)
local timerP0toP1					= mod:NewTimer(8, "TimeToPhase1", nil, nil, nil, 6) -- From YellPhase1 to IEEU
local timerP1toP2					= mod:NewTimer(42.5, "TimeToPhase2", nil, nil, nil, 6) -- From YellPhase2 to IEEU
local timerP2toP3					= mod:NewTimer(17, "TimeToPhase3", nil, nil, nil, 6) -- From YellPhase3 to IEEU
local timerP3toP4					= mod:NewTimer(27, "TimeToPhase4", nil, nil, nil, 6) -- From YellPhase4 to IEEU

mod:AddRangeFrameOption("6")

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..L.MobPhase1)
local warnNapalmShell				= mod:NewTargetNoFilterAnnounce(63666, 2, nil, "Healer")
local warnPlasmaBlast				= mod:NewTargetNoFilterAnnounce(64529, 4, nil, "Tank|Healer")
local warnProximityMines			= mod:NewSpellAnnounce(63027, 4)

local specWarnShockBlast			= mod:NewSpecialWarningRun(63631, "Melee", nil, nil, 4, 2)
local specWarnPlasmaBlast			= mod:NewSpecialWarningDefensive(64529, nil, nil, nil, 1, 2)

local timerProximityMines			= mod:NewNextTimer(8, 63027, nil, nil, nil, 3)
local timerShockBlast				= mod:NewCastTimer(4, 63631, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerNextShockBlast			= mod:NewNextTimer(30, 63631, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerNapalmShell				= mod:NewBuffActiveTimer(8, 63666, nil, "Healer", 2, 5, nil, DBM_COMMON_L.IMPORTANT_ICON..DBM_COMMON_L.HEALER_ICON)
local timerPlasmaBlastCD			= mod:NewNextTimer(22, 64529, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)

mod:AddSetIconOption("SetIconOnNapalm", 63666, false, false, {1, 2, 3, 4, 5, 6, 7})
mod:AddSetIconOption("SetIconOnPlasmaBlast", 64529, false, false, {8})

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..L.MobPhase2)
local specWarnP3Wx2LaserBarrage		= mod:NewSpecialWarningDodge(63274, nil, nil, nil, 3, 2)
local specWarnRocketStrike			= mod:NewSpecialWarningDodge(64402, nil, nil, nil, 2, 2)

local warnHeatWave					= mod:NewSpellAnnounce(64533, 3)

local timerP3Wx2LaserBarrageCast	= mod:NewCastTimer(10, 63274, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerNextP3Wx2LaserBarrage	= mod:NewNextTimer(48, 63274, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerRocketStrikeCD			= mod:NewNextTimer(22.5, 64402, nil, nil, nil, 3)
local timerHeatWave					= mod:NewCDTimer(10, 64533, nil, nil, nil, 3)

-- Stage Three
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3)..": "..L.MobPhase3)
local warnLootMagneticCore			= mod:NewAnnounce("MagneticCore", 1, 64444, nil, nil, nil, 64444)
local warnBombBotSpawn				= mod:NewAnnounce("WarnBombSpawn", 3, 63811, nil, nil, nil, 63811)

local timerBombBotSpawn				= mod:NewNextTimer(15, 63811, nil, nil, nil, 1)
local timerDowned					= mod:NewBuffActiveTimer(20, 64444, nil, nil, nil, 1)

mod:AddBoolOption("AutoChangeLootToFFA", true, nil, nil, nil, nil, 64444)

-- Stage Four
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(4)..": "..L.MobPhase4)
local timerSelfRepair				= mod:NewCastSourceTimer(15, 64383, nil, nil, nil, 7, nil, DBM_COMMON_L.IMPORTANT_ICON)

-- Hard Mode
mod:AddTimerLine(DBM_COMMON_L.HEROIC_ICON..DBM_CORE_L.HARD_MODE)
local warnFlamesSoon				= mod:NewSoonAnnounce(64566, 1)

local timerNextFlames				= mod:NewNextTimer(30, 64566, nil, nil, nil, 7, nil, DBM_COMMON_L.IMPORTANT_ICON)

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..L.MobPhase1)
local timerFlameSuppressantP1Debuff	= mod:NewBuffActiveTimer(8, 64570, nil, nil, nil, 3)
local timerNextFlameSuppressantP1	= mod:NewNextTimer(60, 64570, nil, nil, nil, 3)
local warnFlameSuppressantP1		= mod:NewSpellAnnounce(64570, 3)

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..L.MobPhase2)
local warnFrostBomb					= mod:NewSpellAnnounce(64623, 3)

local timerFrostBombExplosion		= mod:NewCastTimer(15, 65333, nil, nil, nil, 3)
local timerNextFrostBomb			= mod:NewNextTimer(45, 64623, nil, nil, nil, 3, nil, DBM_COMMON_L.HEROIC_ICON, true)
local timerNextFlameSuppressantP2	= mod:NewNextTimer(13, 65192, nil, nil, nil, 3)

-- Stage Three
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3)..": "..L.MobPhase3)
local specWarnDeafeningSiren		= mod:NewSpecialWarningMove(64616, nil, nil, nil, 1, 2)

-- Stage Four
-- mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(4)..": "..L.MobPhase4)
-- nothing new to add

mod:GroupSpells(63274, 63293) -- Spinning Up and P3Wx2 Laser Barrage
mod:GroupSpells(64623, 65333) -- Frost Bomb, Frost Bomb Explosion

local lootmethod, _, masterlooterRaidID
mod.vb.hardmode = false
mod.vb.napalmShellIcon = 7
local napalmShellTargets = {}
mod.vb.is_spinningUp = false
mod.vb.rocketStrikeReset =   {0, 3.5, 0, 3, 0, 3, 6, 0, 3, 0, 3, 0} --unit cast events are unreliable. Using theater scheduling, and adjusting with unitCast
mod.vb.rocketStrikeResetP4 = {0, 1, 2, 3, 4, 5, 5, 6, 0, 1, 2, 3, 3}
mod.vb.barrageWave = 1
mod.vb.lastRocketWarn = 0

local function ResetRange(self)
	if self.Options.RangeFrame then
		DBM.RangeCheck:DisableBossMode()
	end
end

local function Flames(self)	-- Flames -- UNIT_SPELLCAST_SUCCEEDED does not show on etrace
	timerNextFlames:Start()
	self:Schedule(30, Flames, self)
	warnFlamesSoon:Schedule(25)
end

local function warnNapalmShellTargets(self)
	warnNapalmShell:Show(table.concat(napalmShellTargets, "<, >"))
	table.wipe(napalmShellTargets)
	self.vb.napalmShellIcon = 7
end

local function show_warning_for_spinup(self)
	if self.vb.is_spinningUp then
		specWarnP3Wx2LaserBarrage:Show()
		specWarnP3Wx2LaserBarrage:Play("watchstep")
		specWarnP3Wx2LaserBarrage:ScheduleVoice(1, "keepmove")
	end
end

local function show_warning_for_rocket(self)
	
	mod.vb.lastRocketWarn = GetTime()
	
	specWarnRocketStrike:Show()
	specWarnRocketStrike:Play("watchstep")
	
	
	if self.vb.phase == 2 then
		timerRocketStrikeCD:Start()
		self:Schedule(22.5, show_warning_for_rocket, self)
	else
		timerRocketStrikeCD:Start(20.5)
		self:Schedule(20.5, show_warning_for_rocket, self)
	end
end

local function NextPhase(self)
	self:SetStage(0)
	
	if self.vb.phase == 1 then
		if self.Options.HealthFrame then
			DBM.BossHealth:Clear()
			DBM.BossHealth:AddBoss(33432, L.MobPhase1)
		end
	elseif self.vb.phase == 2 then
		timerShockBlast:Stop()
		timerNextShockBlast:Unschedule()
		timerNextShockBlast:Stop()
		timerProximityMines:Stop()
		timerNextFlameSuppressantP1:Stop()
		timerPlasmaBlastCD:Stop()
		
		warnProximityMines:Cancel()
		
		mod.vb.barrageWave = 1
		
		timerP1toP2:Start()
		
		timerNextP3Wx2LaserBarrage:Schedule(42, 33)
		timerRocketStrikeCD:Schedule(42, 17)
		timerHeatWave:Schedule(42, 11)
		
		self:Schedule(59, show_warning_for_rocket, self)
		
		if self.Options.HealthFrame then
			DBM.BossHealth:Clear()
			DBM.BossHealth:AddBoss(33651, L.MobPhase2)
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
		if self.vb.hardmode then
			timerNextFrostBomb:Schedule(42, 3.5)
			timerNextFlameSuppressantP2:Schedule(42, 8.5)
		end
	elseif self.vb.phase == 3 then
		if self.Options.AutoChangeLootToFFA and DBM:GetRaidRank() == 2 then
			SetLootMethod("freeforall")
		end
		
		timerRocketStrikeCD:Cancel()
		self:Unschedule(show_warning_for_rocket)
		
		timerP3Wx2LaserBarrageCast:Cancel()
		timerNextP3Wx2LaserBarrage:Cancel()
		timerNextFrostBomb:Cancel()
		
		timerP2toP3:Start()
		
		timerBombBotSpawn:Schedule(18, 16)
		
		if self.Options.HealthFrame then
			DBM.BossHealth:Clear()
			DBM.BossHealth:AddBoss(33670, L.MobPhase3)
		end
	elseif self.vb.phase == 4 then
		if self.Options.AutoChangeLootToFFA and DBM:GetRaidRank() == 2 then
			if masterlooterRaidID then
				SetLootMethod(lootmethod, "raid"..masterlooterRaidID)
			else
				SetLootMethod(lootmethod)
			end
		end
		
		timerBombBotSpawn:Cancel()
		
		mod.vb.barrageWave = 1
		
		timerP3toP4:Start()
		warnProximityMines:Schedule(33)

		timerNextShockBlast:Schedule(27, 21)
		timerProximityMines:Schedule(27, 6)
		timerNextP3Wx2LaserBarrage:Schedule(27, 33)
		timerRocketStrikeCD:Schedule(27, 17)
		
		self:Schedule(44, show_warning_for_rocket, self)
		
		if self.Options.HealthFrame then
			DBM.BossHealth:Show(L.name)
			DBM.BossHealth:AddBoss(33670, L.MobPhase3)
			DBM.BossHealth:AddBoss(33651, L.MobPhase2)
			DBM.BossHealth:AddBoss(33432, L.MobPhase1)
		end
		if self.vb.hardmode then
			timerNextFrostBomb:Schedule(27, 1)
		end
	end
end

function mod:OnCombatStart()
	self.vb.phase = 0
	self.vb.is_spinningUp = false
	self.vb.napalmShellIcon = 7
	mod.vb.barrageWave = 1
	table.wipe(napalmShellTargets)
	
	NextPhase(self)
	
	if DBM:GetRaidRank() == 2 then
		lootmethod, _, masterlooterRaidID = GetLootMethod()
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(6)
	end
end

function mod:OnCombatEnd()
	self:Unschedule(Flames)
	self:Unschedule(show_warning_for_rocket)
	if self.Options.HealthFrame then
		DBM.BossHealth:Hide()
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.AutoChangeLootToFFA and DBM:GetRaidRank() == 2 then
		if masterlooterRaidID then
			SetLootMethod(lootmethod, "raid"..masterlooterRaidID)
		else
			SetLootMethod(lootmethod)
		end
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	
	if spellId == 63631 then
		specWarnShockBlast:Show()
		specWarnShockBlast:Play("runout")
		
		timerShockBlast:Start()
		timerNextShockBlast:Schedule(4, 26)
		timerProximityMines:Start(8)
		warnProximityMines:Schedule(8)

		
		if self.Options.RangeFrame then
			DBM.RangeCheck:SetBossRange(15, self:GetBossUnitByCreatureId(33432))
			self:Schedule(4.5, ResetRange, self)
		end
	elseif args:IsSpellID(64529, 62997) then	-- Plasma Blast
		if self:IsTanking("player", DBM:GetUnitIdFromCID(33432, false), nil, true) then
			specWarnPlasmaBlast:Show()
			specWarnPlasmaBlast:Play("defensive")
		end
		timerPlasmaBlastCD:Start()
	elseif spellId == 64570 then	-- Flame Suppressant (phase 1)
		--timerNextFlameSuppressantP1:Start()
		warnFlameSuppressantP1:Show()
	elseif spellId == 64623 then	-- Frost Bomb
		warnFrostBomb:Show()
		timerFrostBombExplosion:Start()
		timerNextFrostBomb:Start()
	elseif spellId == 64383 then -- Self Repair (phase 4)
		-- REVIEW! Makes sense to cancel timers when each part dies? Or timers are continuous?
		timerSelfRepair:Start(args.sourceName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 63414 then			-- Spinning UP (before Dark Glare)
		self.vb.is_spinningUp = true
		timerP3Wx2LaserBarrageCast:Schedule(4)
		self:Schedule(0.15, show_warning_for_spinup, self)	-- wait 0.15 and then announce it, otherwise it will sometimes fail
		
		timerRocketStrikeCD:Cancel()
		self:Unschedule(show_warning_for_rocket)
		
		local barrageWaveOffset
		if self.vb.phase == 2 then
			barrageWaveOffset = mod.vb.rocketStrikeReset[mod.vb.barrageWave]
			timerNextP3Wx2LaserBarrage:Schedule(14)			-- 4 (cast spinup) + 10 sec (cast dark glare)
		else
			barrageWaveOffset = mod.vb.rocketStrikeResetP4[mod.vb.barrageWave]
			timerNextP3Wx2LaserBarrage:Schedule(14, 46)			-- laser in p4 comes 2s earlier
		end
			
		self:Schedule(14 + barrageWaveOffset, show_warning_for_rocket, self)
		timerRocketStrikeCD:Schedule(14, barrageWaveOffset)
		
		mod.vb.barrageWave = mod.vb.barrageWave + 1
		
	elseif spellId == 65192 then	-- Flame Suppressant CD (phase 2)
		timerNextFlameSuppressantP2:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args:IsSpellID(63666, 65026) and args:IsDestTypePlayer() then	-- Napalm Shell
		napalmShellTargets[#napalmShellTargets + 1] = args.destName
		timerNapalmShell:Start()
		if self.Options.SetIconOnNapalm and self.vb.napalmShellIcon > 0 then
			self:SetIcon(args.destName, self.vb.napalmShellIcon, 6)
		end
		self.vb.napalmShellIcon = self.vb.napalmShellIcon - 1
		self:Unschedule(warnNapalmShellTargets)
		self:Schedule(0.3, warnNapalmShellTargets, self)
	elseif args:IsSpellID(64529, 62997) then	-- Plasma Blast
		warnPlasmaBlast:Show(args.destName)
		if self.Options.SetIconOnPlasmaBlast then
			self:SetIcon(args.destName, 8, 6)
		end
	elseif spellId == 64616 and args:IsPlayer() then	-- Deafening Siren (Hard Mode)
		specWarnDeafeningSiren:Show()
	elseif spellId == 64570 and args:IsPlayer() then	-- Flame Suppressant (phase 1)
		timerFlameSuppressantP1Debuff:Start()
	elseif spellId == 64533 and args:IsPlayer()then
		self:SendSync("HeatWave")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(63666, 65026) then -- Napalm Shell
		if self.Options.SetIconOnNapalm then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPull or msg:find(L.YellPull) then -- register Normal Mode
		self.vb.hardmode = false
		
		timerP0toP1:Start()
		
		warnProximityMines:Schedule(14)
		
		timerPlasmaBlastCD:Schedule(8, 10)
		timerNextShockBlast:Schedule(8, 21)
		timerProximityMines:Schedule(8, 6)
		
		timerEnrage:Schedule(8, 892)
	elseif msg == L.YellHardPull or msg:find(L.YellHardPull) then -- register HARD Mode
		self.vb.hardmode = true
		
		self:SetWipeTime(10)
		timerP0toP1:Start(13)

		warnProximityMines:Schedule(19)
		
		timerPlasmaBlastCD:Schedule(13, 10)
		timerNextFlameSuppressantP1:Schedule(13, 65)
		timerProximityMines:Schedule(13, 6)
		timerNextShockBlast:Schedule(13, 21)
		
		timerNextFlames:Start(7)
		self:Schedule(7, Flames, self)
		warnFlamesSoon:Schedule(2)
		
		if self:IsDifficulty("normal10") then
			timerEnrage:Start(480) 
		else
			timerEnrage:Start(600)
		end
	elseif msg == L.YellPhase2 or msg:find(L.YellPhase2) then -- register Phase 2
		NextPhase(self)
	elseif msg == L.YellPhase3 or msg:find(L.YellPhase3) then -- register Phase 3
		NextPhase(self)
	elseif msg == L.YellPhase4 or msg:find(L.YellPhase4) then -- register Phase 4
		NextPhase(self)
	end
end

function mod:CHAT_MSG_LOOT(msg)
	local player, itemID = msg:match(L.LootMsg)
	if player and itemID and tonumber(itemID) == 46029 and self:IsInCombat() then
		player = DBM:GetUnitFullName(player) or UnitName("player")
		self:SendSync("LootMsg", player)
	end
end

function mod:SPELL_SUMMON(args)
	if args:IsSpellID(64444) then
		timerDowned:Schedule(3)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(63811) then
		self:SendSync("BombBot")
	elseif spellName == GetSpellInfo(63041) then
		self:SendSync("Rocket")
	end
end

function mod:OnSync(event, args)
	if event == "LootMsg" and args and self:AntiSpam(2, 1) then
		warnLootMagneticCore:Show(args)
	elseif event == "HeatWave" and self:AntiSpam(3, 1) then
		warnHeatWave:Show()
		timerHeatWave:Start()
	elseif event == "BombBot" and self:AntiSpam(3, 1) then
		warnBombBotSpawn:Show()
		timerBombBotSpawn:Start()
	elseif event == "Rocket" and self:AntiSpam(3, 1) then
		
		if GetTime() - mod.vb.lastRocketWarn > 5 then
			specWarnRocketStrike:Show()
			specWarnRocketStrike:Play("watchstep")
		end
		
		self:Unschedule(show_warning_for_rocket)
		timerRocketStrikeCD:Cancel()
		
		if self.vb.phase == 2 then
			timerRocketStrikeCD:Start()
			self:Schedule(22.5, show_warning_for_rocket, self)
		else
			timerRocketStrikeCD:Start(20.5)
			self:Schedule(20.5, show_warning_for_rocket, self)
		end
	end
end
