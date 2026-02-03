local mod	= DBM:NewMod("Patchwerk", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20190417005949")
mod:SetCreatureID(16028)

mod:RegisterCombat("combat_yell", L.yell1, L.yell2)

mod:RegisterEventsInCombat(
	"SPELL_DAMAGE 28308 59192",
	"SPELL_MISSED 28308 59192"
)

local enrageTimer	= mod:NewBerserkTimer(360)
local timerAchieve	= mod:NewAchievementTimer(180, 1857)

local warnHateful	= mod:NewTargetNoFilterAnnounce(28308, 4)

local prevHateful

function mod:OnCombatStart(delay)
	enrageTimer:Start(-delay)
	timerAchieve:Start(-delay)
end

function mod:SPELL_DAMAGE(_, _, _, _, destName, _, spellId, _, _, amount)
	if (spellId == 28308 or spellId == 59192) and (not prevHateful or prevHateful ~= destName)then
		prevHateful = destName
		warnHateful:Show(destName)
	end
end

function mod:SPELL_MISSED(_, _, _, _, destName, _, spellId, _, _, missType)
	if (spellId == 28308 or spellId == 59192) and (not prevHateful or prevHateful ~= destName)then
		prevHateful = destName
		warnHateful:Show(destName)
	end
end
