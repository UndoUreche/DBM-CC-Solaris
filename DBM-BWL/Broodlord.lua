local mod	= DBM:NewMod("Broodlord", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 168 $"):sub(12, -3))
mod:SetCreatureID(12017)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"UNIT_THREAT_SITUATION_UPDATE"
)

local warnBlastWave	= mod:NewSpellAnnounce(23331)
local warnKnockAway	= mod:NewSpellAnnounce(18670)
local warnMortal	= mod:NewTargetAnnounce(24573)

local timerMortal	= mod:NewTargetTimer(5, 24573)

function mod:OnCombatStart(delay)
end

--It's unfortunate this is a shared spellid.
--cause you are almost always in combat before pulling this boss which breaks "IsInCombat" detection
--these 2 of these warnings will never work.

function mod:SPELL_CAST_SUCCESS(args)

	if args.spellId == 23331 then
		warnBlastWave:Show()
	elseif args.spellId == 18670 and self:IsInCombat() then
		warnKnockAway:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 24573 and self:IsInCombat() then
		warnMortal:Show(args.destName)
		timerMortal:Start(args.destName)
	end
end

function mod:UNIT_THREAT_SITUATION_UPDATE(unit)
	if UnitExists("boss1") then
		local playerTanking = UnitDetailedThreatSituation("player", "boos1")
		
		print(playerTanking)
		
		if unit == "player" and playerTanking then
			print("pula2")
		end
	end
end