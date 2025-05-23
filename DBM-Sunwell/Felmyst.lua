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
local specWarnEncaps		= mod:NewSpecialWarningYou(45665, nil, nil, nil, 1, 2)
local yellEncaps		= mod:NewYell(45665)
local specWarnEncapsNear	= mod:NewSpecialWarningClose(45665, nil, nil, nil, 1, 2)
local specWarnVapor		= mod:NewSpecialWarningSpell(45402, nil, nil, nil, 1, 2)
local specWarnBreath		= mod:NewSpecialWarningCount(45717, nil, nil, nil, 3, 2)

local timerGasCast		= mod:NewCastTimer(1, 45855)
local timerCorrosion		= mod:NewTargetTimer(10, 45866, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerEncaps		= mod:NewTargetTimer(7, 45665, nil, nil, nil, 3)
local timerBreath		= mod:NewCDCountTimer(17, 45717, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerPhase		= mod:NewTimer(60, "TimerPhase", 31550, nil, nil, 6)

local berserkTimer		= mod:NewBerserkTimer(mod:IsTimewalking() and 500 or 600)

mod:AddSetIconOption("EncapsIcon", 45665, true, false, {7})
mod:AddSetIconOption("VaporIcon", 45402, true, true, {8})

mod.vb.breathCounter = 0
mod.vb.groundingTime = 0
mod.vb.isFirstCast = true

function mod:EncapsulateTarget(targetname)
	if not targetname then 
		return 
	end
	
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
	self.vb.isFirstCast = true
	self.vb.groundingTime = GetTime()-delay
	
	timerPhase:Start(-delay, L.Air)
	berserkTimer:Start(-delay)
end

function mod:adjustGroundTimersIfFirstCast(realElapsed) 
	if self.vb.isFirstCast == true then
		self.vb.isFirstCast = false 
		
		local timerElapsed = GetTime() - self.vb.groundingTime
		timerPhase:AddTime(-60+timerElapsed+60-realElapsed, L.Air)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45866 then
	
		self:adjustGroundTimersIfFirstCast(12)
	
		timerCorrosion:Start(args.destName)
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
		specWarnGas:Show()
		specWarnGas:Play("helpdispel")
	end
end

function mod:Groundphase()
	self.vb.breathCounter = 0
	self.vb.isFirstCast = true
	self.vb.groundingTime = GetTime()
	
	warnPhase:Show(L.Ground)
	timerPhase:Start(60, L.Air)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.AirPhase or msg:find(L.AirPhase) then
		self.vb.breathCounter = 0
		warnPhase:Show(L.Air)
		
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
