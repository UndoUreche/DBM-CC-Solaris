local mod	= DBM:NewMod("Jeklik", "DBM-ZG", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))
mod:SetCreatureID(14517)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_HEALTH"
)

local warnPhase2Soon	= mod:NewAnnounce("WarnPhase2Soon", 1)
local warnPhase2		= mod:NewPhaseAnnounce(2)

local warnSonicBurst	= mod:NewSpellAnnounce(23918)
local warnScreech		= mod:NewSpellAnnounce(22884)
local warnPain			= mod:NewTargetAnnounce(23952)
local warnHeal			= mod:NewCastAnnounce(23954, 4)

local timerSonicBurst	= mod:NewBuffActiveTimer(10, 23918)
local timerScreech		= mod:NewBuffActiveTimer(4, 22884)
local timerPain			= mod:NewTargetTimer(18, 23952)
local timerHeal			= mod:NewCastTimer(4, 23954)
local timerHealCD		= mod:NewNextTimer(25, 23954)

local timerCdFlyingBats	= mod:NewTimer(10, "TimerBats")

local warned_preP2
local phase

function mod:OnCombatStart(delay)
	warned_preP2 = false
	phase = 1
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(23954) then
		timerHeal:Start()
		timerHealCD:Start()
		warnHeal:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(23918) then
		timerSonicBurst:Start()
		warnSonicBurst:Show()
	elseif args:IsSpellID(22884) and self:IsInCombat() then
		timerScreech:Start()
		warnScreech:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(23952) then
		timerPain:Start(args.destName)
		warnPain:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(23952) then
		timerPain:Cancel(args.destName)
	end
end

function mod:UNIT_HEALTH(uId)
	if phase == 1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 14517 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.61 then
		warned_preP2 = true
		warnPhase2Soon:Show()	
	elseif phase == 1 and warned_preP2 and self:GetUnitCreatureId(uId) == 14517 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.51 then
		phase = 2;
		warnPhase2:Show()
		
		timerHealCD:Start()
		timerCdFlyingBats:Cancel()
		timerCdFlyingBats:Start()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.SummonBats then
		timerCdFlyingBats:Cancel()
		timerCdFlyingBats:Start()
	end
end