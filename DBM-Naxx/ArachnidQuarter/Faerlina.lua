local mod	= DBM:NewMod("Faerlina", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016190115")
mod:SetCreatureID(15953)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28798 54100 28732 54097 28794 54099",
	"SPELL_AURA_REFRESH 28732 54097",
	"SPELL_CAST_SUCCESS 28796 54098",
	"UNIT_DIED"
)

local warnEmbraceActive			= mod:NewSpellAnnounce(28732, 1)
local warnEmbraceExpired		= mod:NewFadesAnnounce(28732, 3)
local warnEnrageNow			= mod:NewSpellAnnounce(28131, 4)

local specWarnEnrage			= mod:NewSpecialWarningDefensive(28131, nil, nil, nil, 3, 2)
local specWarnGTFO			= mod:NewSpecialWarningGTFO(28794, nil, nil, nil, 1, 8)

local timerEmbrace			= mod:NewBuffActiveTimer(30, 28732, nil, nil, nil, 6)
local timerEnrage			= mod:NewCDTimer(60, 28131, nil, nil, nil, 6)
local timerPoisonVolleyCD		= mod:NewCDTimer(7, 54098, nil, nil, nil, 5)

local function EnrageFail(self)

	timerEnrage:Start(30)
	self:Schedule(30, EnrageFail, self)
end

function mod:OnCombatStart(delay)
	timerEnrage:Start(-delay)
	timerPoisonVolleyCD:Start(7-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28798, 54100) then			-- Frenzy
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnEnrage:Show()
			specWarnEnrage:Play("defensive")
		else
			warnEnrageNow:Show()
		end
	elseif args:IsSpellID(28732, 54097) and args:GetDestCreatureID() == 15953 and self:AntiSpam(5, 2) then	-- Widow's Embrace
		warnEmbraceExpired:Cancel()
		timerEnrage:Stop()

		timerEmbrace:Start()
		warnEmbraceActive:Show()
		warnEmbraceExpired:Schedule(30)
	elseif args:IsSpellID(28794, 54099) and args:IsPlayer() then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:SPELL_AURA_REFRESH(args)
	if args:IsSpellID(28732, 54097) and args:GetDestCreatureID() == 15953 and self:AntiSpam(5, 2) then	-- Widow's Embrace
		warnEmbraceExpired:Cancel()
		timerEnrage:Stop()
		timerEmbrace:Stop()

		timerEmbrace:Start()
		warnEmbraceActive:Show()
		warnEmbraceExpired:Schedule(30)
	end
end


function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28796, 54098) then -- Poison Bolt Volley
		timerPoisonVolleyCD:Start(7)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 15953 then
		warnEmbraceExpired:Cancel()
	end
end
