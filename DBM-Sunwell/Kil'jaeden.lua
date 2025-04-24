local mod	= DBM:NewMod("Kil", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(25315)
mod:SetUsedIcons(4, 5, 6, 7, 8)

mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 45641",
	"SPELL_AURA_REMOVED 45641",
	"SPELL_CAST_START 46605 45737 46680",
	"SPELL_CAST_SUCCESS 45680 45848 45892 46589",
	"SPELL_DAMAGE 45680",
	"CHAT_MSG_MONSTER_YELL"
)

local warnBloom			= mod:NewTargetAnnounce(45641, 2)
local warnDarkOrb		= mod:NewAnnounce("WarnDarkOrb", 4, 45109)
local warnDart			= mod:NewSpellAnnounce(45740, 3)
local warnBlueOrb		= mod:NewAnnounce("WarnBlueOrb", 1, 45109)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnPhase3		= mod:NewPhaseAnnounce(3)
local warnPhase4		= mod:NewPhaseAnnounce(4)

local specWarnSpike		= mod:NewSpecialWarningSpell(46589)
local specWarnBloom		= mod:NewSpecialWarningYou(45641, nil, nil, nil, 1, 2)
local yellBloom			= mod:NewYellMe(45641)
local specWarnBomb		= mod:NewSpecialWarningMoveTo(46605, nil, nil, nil, 3, 2)--findshield
local specWarnShield		= mod:NewSpecialWarningSpell(45848)
local specWarnDarkOrb		= mod:NewSpecialWarning("SpecWarnDarkOrb", false)
local specWarnBlueOrb		= mod:NewSpecialWarning("SpecWarnBlueOrb", false)

local timerBloomCD		= mod:NewCDTimer(40, 45641, nil, nil, nil, 2)
local timerDartCD		= mod:NewCDTimer(7, 45740, nil, nil, nil, 2)--Targeted or aoe?
local timerBomb			= mod:NewCastTimer(9, 46605, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerBombCD		= mod:NewCDTimer(45, 46605, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerSpike		= mod:NewCastTimer(28, 46589, nil, nil, nil, 3)
local timerBlueOrb		= mod:NewTimer(35, "TimerBlueOrb", 45109, nil, nil, 5)

mod:AddRangeFrameOption("12")
mod:AddSetIconOption("BloomIcon", 45641, true, false, {4, 5, 6, 7, 8})

local bloomTimer = 38
local warnBloomTargets = {}
local orbGUIDs = {}
mod.vb.bloomIcon = 8

local function showBloomTargets(self)
	warnBloom:Show(table.concat(warnBloomTargets, "<, >"))
	table.wipe(warnBloomTargets)
	self.vb.bloomIcon = 8
	timerBloomCD:Start(bloomTimer)
end

function mod:OnCombatStart(delay)
	table.wipe(warnBloomTargets)
	table.wipe(orbGUIDs)
	self.vb.bloomIcon = 8
	self:SetStage(1)
	timerBloomCD:Start(9-delay)
	bloomTimer = 38
	
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show()
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45641 then
		warnBloomTargets[#warnBloomTargets + 1] = args.destName
		self:Unschedule(showBloomTargets)
		if self.Options.BloomIcon then
			self:SetIcon(args.destName, self.vb.bloomIcon)
		end
		self.vb.bloomIcon = self.vb.bloomIcon - 1
		if args:IsPlayer() then
			specWarnBloom:Show()
			specWarnBloom:Play("targetyou")
			yellBloom:Yell()
		end
		if #warnBloomTargets >= 5 then
			showBloomTargets(self)
		else
			self:Schedule(0.3, showBloomTargets, self)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 45641 then
		if self.Options.BloomIcon then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 46605 then
		specWarnBomb:Show(SHIELDSLOT)
		specWarnBomb:Play("findshield")
		timerBomb:Start()
		if self.vb.phase == 4 then
			timerBombCD:Start(25)
		else
			timerBombCD:Start()
		end
	elseif args.spellId == 45737 then
		warnDart:Show()
		timerDartCD:Start()
	elseif args.spellId == 46680 then
		timerSpike:Start()
		specWarnSpike:Show()
	end
end

function mod:SPELL_DAMAGE(sourceGUID, _, _, _, _, _, spellId) --this should be done on SPELL_CAST_SUCCESS

	if spellId == 45680 and not orbGUIDs[sourceGUID] then
		orbGUIDs[sourceGUID] = true
		if self:AntiSpam(5, 1) then
			warnDarkOrb:Show()
			specWarnDarkOrb:Show()
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 45848 then
		specWarnShield:Show()
		
	elseif args.spellId == 45892 and self:AntiSpam(5) then --phase change
		self:SetStage(0)
		
		if self.vb.phase == 2 then
			warnPhase2:Show()
			
			timerBloomCD:Cancel()
			
			timerBloomCD:Start(37)
			timerBlueOrb:Start()
			timerDartCD:Start(32)
			timerBombCD:Start(45)
		elseif self.vb.phase == 3 then
			warnPhase3:Show()
			
			timerBloomCD:Cancel()
			timerBlueOrb:Cancel()
			timerDartCD:Cancel()
			timerBombCD:Cancel()
			
			timerBloomCD:Start(37)
			timerBlueOrb:Start()
			timerBombCD:Start(42)
		elseif self.vb.phase == 4 then
			warnPhase4:Show()
			bloomTimer = 18
		
			timerBloomCD:Cancel()
			timerBlueOrb:Cancel()
			timerBombCD:Cancel()
			
			timerBloomCD:Start(47)
			timerBlueOrb:Start(60)
			timerBombCD:Start(58)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.OrbYell1 or msg:find(L.OrbYell1) or msg == L.OrbYell2 or msg:find(L.OrbYell2) or msg == L.OrbYell3 or msg:find(L.OrbYell3) or msg == L.OrbYell4 or msg:find(L.OrbYell4) then
		warnBlueOrb:Show()
		specWarnBlueOrb:Show()
	end
end
