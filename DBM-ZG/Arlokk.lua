local mod	= DBM:NewMod("Arlokk", "DBM-ZG", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))
mod:SetCreatureID(14515)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnMark		= mod:NewTargetAnnounce(24210)
local warnVanish	= mod:NewSpellAnnounce(24223)
local warnPain		= mod:NewTargetAnnounce(24212)

local timerPain		= mod:NewTargetTimer(18, 24212)
local timerGouge	= mod:NewTargetTimer(12, 12540)
local timerGougeCD	= mod:NewCDTimer(12, 12540)

local specWarnMark	= mod:NewSpecialWarningYou(24210)
local vanished

function mod:OnCombatStart(delay)
	vanished = false
	timerGougeCD:Start()
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(24210) then
		warnMark:Show(args.destName)
		if args:IsPlayer() then
			specWarnMark:Show()
		end
	elseif args:IsSpellID(24212) then
		warnPain:Show(args.destName)
		timerPain:Start(args.destName)
	elseif args:IsSpellID(12540) then
		timerGouge:Start(args.destName)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spell)

	if(spell == 'Vanish Visual') then
		vanished = not vanished;
		
		if vanished then
			warnVanish:Show()
		else
			timerGougeCD:Start()
		end
	end

end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(24212) then
		timerPain:Cancel(args.destName)
	elseif args:IsSpellID(12540) then
		timerGouge:Cancel(args.destName)
	end
end