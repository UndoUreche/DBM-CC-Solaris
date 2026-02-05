local mod	= DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220806123502")
mod:SetCreatureID(15932)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 54427",
	"SPELL_CAST_SUCCESS 28375"
)

local warnDecimateSoon		= mod:NewSoonAnnounce(28374, 2)
local warnDecimateNow		= mod:NewSpellAnnounce(28374, 3)

local specWarnEnrage		= mod:NewSpecialWarningDispel(19451, "RemoveEnrage", nil, nil, 1, 6)

local timerEnrage		= mod:NewNextTimer(22, 19451, nil, nil, nil, 5, nil, DBM_COMMON_L.ENRAGE_ICON)
local timerDecimate		= mod:NewNextTimer(104, 28374, nil, nil, nil, 2)
local enrageTimer		= mod:NewBerserkTimer(360)

function mod:OnCombatStart(delay)
	enrageTimer:Start(420 - delay)
	timerEnrage:Start(22-delay)

	if self:IsDifficulty("normal10") then
		timerDecimate:Start(110-delay)
		warnDecimateSoon:Schedule(100-delay)
	else
		timerDecimate:Start(90-delay)
		warnDecimateSoon:Schedule(80-delay)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 54427 then
		specWarnEnrage:Show(args.destName)
		specWarnEnrage:Play("enrage")
		timerEnrage:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28375) then
		warnDecimateNow:Show()
		if self:IsDifficulty("normal10") then
			timerDecimate:Start(110)
			warnDecimateSoon:Schedule(100)
		else
			timerDecimate:Start(90)
			warnDecimateSoon:Schedule(80)
		end
	end
end
