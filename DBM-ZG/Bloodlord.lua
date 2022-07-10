local mod = DBM:NewMod("Bloodlord", "DBM-ZG", 1)
local L = mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))

mod:SetCreatureID(11382, 14988)
mod:RegisterCombat("combat")
mod:SetBossHealthInfo(
	11382, L.Bloodlord,
	14988, L.Ohgan
)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS"
)

local warnFrenzy	= mod:NewSpellAnnounce(24318)
local warnGaze		= mod:NewTargetAnnounce(24314)
local specWarnGaze = mod:NewSpecialWarningYou(24314)
local warnMortal	= mod:NewTargetAnnounce(16856)
local timerGaze 	= mod:NewTargetTimer(6, 24314)
local timerMortal	= mod:NewTargetTimer(5, 16856)
local warnWhirlWind	= mod:NewSpellAnnounce(13736)
local timerWhirlWind = mod:NewTimer(22, "TimerWhirlWind")

function mod:OnCombatStart(delay)
	timerWhirlWind:Start(24)
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(24314) then
		if args:IsPlayer() then
			specWarnGaze:Show()
		end
		warnGaze:Show(args.unitTarget)
		timerGaze:Start(args.destName)
	elseif args:IsSpellID(24318) then
		warnFrenzy:Show(args.destName)
	elseif args:IsSpellID(16856) and self:IsInCombat() and args:IsDestTypePlayer() then
		warnMortal:Show(args.destName)
		timerMortal:Start(args.destName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(13736) then
		warnWhirlWind:Show()
		timerWhirlWind:Start()
	end
end