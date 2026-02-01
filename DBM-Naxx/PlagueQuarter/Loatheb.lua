local mod	= DBM:NewMod("Loatheb", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221022102923")
mod:SetCreatureID(16011)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_SUMMON 29234",
	"SPELL_CAST_SUCCESS 29204 55052",
	"SPELL_AURA_APPLIED 55593"
)

local warnSporeNow	= mod:NewCountAnnounce(32329, 2)
local warnSporeSoon	= mod:NewSoonAnnounce(32329, 1)
local warnDoomNow	= mod:NewSpellAnnounce(29204, 3)
local warnHealSoon	= mod:NewAnnounce("WarningHealSoon", 4, 48071, nil, nil, nil, 55593)
local warnHealNow	= mod:NewAnnounce("WarningHealNow", 1, 48071, false, nil, nil, 55593)

local timerSpore	= mod:NewNextTimer(36, 32329, nil, nil, nil, 5, 42524, DBM_COMMON_L.DAMAGE_ICON)
local timerDoom		= mod:NewNextTimer(120, 29204, nil, nil, nil, 2)
local timerAura		= mod:NewBuffActiveTimer(17, 55593, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)


mod.vb.doomCounter	= 0
mod.vb.sporeCounter 	= 0

function mod:OnCombatStart(delay)

	timerSpore:Start(15 - delay, 1)
	timerDoom:Start(120 - delay)

	warnSporeSoon:Schedule(10 - delay)
end

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 29234 then
		self.vb.sporeCounter = self.vb.sporeCounter + 1

		timerSpore:Start(35, self.vb.sporeCounter + 1)
		warnSporeNow:Show(self.vb.sporeCounter)
		warnSporeSoon:Schedule(30)
	end 
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(29204, 55052) then
		self.vb.doomCounter = self.vb.doomCounter + 1

		local timer = 30
		if self.vb.doomCounter >= 7 then
			timer = 15
		end
		warnDoomNow:Show(self.vb.doomCounter)
		timerDoom:Start(timer, self.vb.doomCounter + 1)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 55593 then
		timerAura:Start()
		warnHealSoon:Schedule(14)
		warnHealNow:Schedule(17)
	end
end
