local mod	= DBM:NewMod("Felmyst", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(25038)
mod:SetUsedIcons(8, 7)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 45866",
	"SPELL_CAST_START 45855",
	"SPELL_SUMMON 45392",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_SPELLCAST_SUCCEEDED"
	)

local warnEncaps		= mod:NewTargetAnnounce(45665, 4)
local warnPhase			= mod:NewAnnounce("WarnPhase", 1, 31550)

local specWarnGas		= mod:NewSpecialWarningSpell(45855, "Healer", nil, nil, 1, 2)
local specWarnCorrosion		= mod:NewSpecialWarningTaunt(45866, nil, nil, nil, 1, 2)
local specWarnEncaps		= mod:NewSpecialWarningYou(45665, nil, nil, nil, 1, 2)
local yellEncaps		= mod:NewYell(45665)
local specWarnEncapsNear	= mod:NewSpecialWarningClose(45665, nil, nil, nil, 1, 2)
local specWarnVapor		= mod:NewSpecialWarningSpell(45402, nil, nil, nil, 1, 2)
local specWarnBreath		= mod:NewSpecialWarningCount(45717, nil, nil, nil, 3, 2)

local timerGasCast		= mod:NewCastTimer(1, 45855)
local timerGasCD		= mod:NewNextTimer(18, 45855, nil, nil, nil, 3)
local timerCorrosion		= mod:NewTargetTimer(10, 45866, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerEncaps		= mod:NewTargetTimer(7, 45665, nil, nil, nil, 3)
local timerEncapsCD		= mod:NewNextTimer(18, 45665, nil, nil, nil, 3)
local timerBreath		= mod:NewCDCountTimer(17, 45717, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerPhase		= mod:NewTimer(60, "TimerPhase", 31550, nil, nil, 6)

local berserkTimer		= mod:NewBerserkTimer(mod:IsTimewalking() and 500 or 600)

mod:AddSetIconOption("EncapsIcon", 45665, true, false, {7})
mod:AddSetIconOption("VaporIcon", 45402, true, true, {8})

mod.vb.breathCounter = 0
mod.vb.groundingTime = 0
mod.vb.isFirstCleave = true

function mod:EncapsulateTarget(targetname)
	if not targetname then 
		return 
	end
	
	timerEncapsCD:Schedule(7)
	timerEncaps:Start(targetname)
	if self.Options.EncapsIcon then
		self:SetIcon(targetname, 7, 6)
	end
	if targetname == UnitName("player") then
		specWarnEncaps:Show()
		specWarnEncaps:Play("targetyou")
		yellEncaps:Yell()
	elseif self:CheckNearby(21, targetname) then
		specWarnEncapsNear:Show(targetname)
		specWarnEncapsNear:Play("runaway")
	else
		warnEncaps:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.breathCounter = 0
	self.vb.isFirstCleave = true
	self.vb.groundingTime = GetTime()-delay
	
	timerGasCD:Start(17-delay)
	timerPhase:Start(-delay, L.Air)
	berserkTimer:Start(-delay)
	timerEncapsCD:Start(25-delay)
end

function mod:adjustGroundTimersIfFirstCast(realElapsed) 
	if self.vb.isFirstCleave == true then
		self.vb.isFirstCleave = false 
		
		local timerElapsed = GetTime() - self.vb.groundingTime
		
		timerGasCD:AddTime(-18+timerElapsed+18-realElapsed)
		timerEncapsCD:AddTime(-25+timerElapsed+25-realElapsed)
		timerPhase:AddTime(-60+timerElapsed+60-realElapsed, L.Air)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45866 then
		self:adjustGroundTimersIfFirstCast(12)
	
		timerCorrosion:Start(args.destName)
		if not args:IsPlayer() then -- validate
			specWarnCorrosion:Show(args.destName)
			specWarnCorrosion:Play("tauntboss")
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 45392 then
		specWarnVapor:Show()
		specWarnVapor:Play("runaway")
		
		if self.Options.VaporIcon then
			self:SetIcon(args.sourceName, 8, 10)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 45855 then
		timerGasCast:Start()
		timerGasCD:Schedule(1, 17)
		specWarnGas:Show()
		specWarnGas:Play("helpdispel")
	end
end

function mod:Groundphase()
	self.vb.breathCounter = 0
	self.vb.isFirstCleave = true
	self.vb.groundingTime = GetTime()
	
	warnPhase:Show(L.Ground)
	timerGasCD:Start(17)
	timerPhase:Start(60, L.Air)
	timerEncapsCD:Start(25)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.AirPhase or msg:find(L.AirPhase) then
		self.vb.breathCounter = 0
		warnPhase:Show(L.Air)
		timerGasCD:Cancel()
		timerEncapsCD:Cancel()
		timerEncapsCD:Unschedule()
		
		timerBreath:Start(42, 1)
		timerPhase:Start(104, L.Ground)
		self:ScheduleMethod(104, "Groundphase")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.Breath or msg:find(L.Breath) then
		self.vb.breathCounter = self.vb.breathCounter + 1
		specWarnBreath:Show(self.vb.breathCounter)
		specWarnBreath:Play("breathsoon")
		if self.vb.breathCounter < 3 then
			timerBreath:Start(nil, self.vb.breathCounter+1)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(19983) then
		self:adjustGroundTimersIfFirstCast(8)
		
	elseif spellName == GetSpellInfo(45661) and self:AntiSpam(2, 1) then
		self:BossTargetScanner(25038, "EncapsulateTarget", 0.05, 10)
	end
end
