local mod	= DBM:NewMod("Hakkar", "DBM-ZG", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))
mod:SetCreatureID(14834)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED"
)

local warnSiphonSoon	= mod:NewSoonAnnounce(24324)
local warnInsanity		= mod:NewTargetAnnounce(24327)
local warnBlood			= mod:NewTargetAnnounce(24328)

local timerSiphon		= mod:NewNextTimer(90, 24324)
local timerInsanity		= mod:NewTargetTimer(10, 24327)
local timerInsanityCD	= mod:NewCDTimer(35, 24327)
local timerBlood		= mod:NewTargetTimer(10, 24328)

local specWarnBlood		= mod:NewSpecialWarningYou(24328)

local enrageTimer		= mod:NewBerserkTimer(585)

function mod:OnCombatStart(delay)
	enrageTimer:Start(-delay)
	warnSiphonSoon:Schedule(80-delay)
	timerSiphon:Start(-delay)
	timerInsanityCD:Start(17-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 24327 then
		warnInsanity:Show(args.destName)
		timerInsanity:Start(args.destName)
		timerInsanityCD:Start()
	elseif args.spellId == 24328 then
		warnBlood:Show(args.destName)
		timerBlood:Start(args.destName)
		if args:IsPlayer() then
			specWarnBlood:Show()
		end
	elseif args.spellId == 24324 then
		warnSiphonSoon:Cancel()
		warnSiphonSoon:Schedule(80)
		timerSiphon:Start()
	end
end
		