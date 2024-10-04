local mod	= DBM:NewMod("Shahraz", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(22947)

mod:SetModelID(21252)
mod:SetUsedIcons(1, 2, 3)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_AURA_APPLIED 41001",
	"SPELL_AURA_REMOVED 41001",
	"SPELL_CAST_SUCCESS 40823"
)

mod:RegisterEvents(
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnFA			= mod:NewTargetNoFilterAnnounce(41001, 4)
local warnShriek		= mod:NewSpellAnnounce(40823)
local warnEnrage		= mod:NewSpellAnnounce(45078)

local specWarnFA		= mod:NewSpecialWarningMoveAway(41001, nil, nil, nil, 1, 2)

local timerNextFA		= mod:NewNextTimer(60, 41001, nil, nil, nil, 3)--20-28
local timerAura			= mod:NewTimer(15, "timerAura", 22599)
local timerNextShriek		= mod:NewNextTimer(30.8, 40823, nil, nil, nil, 2)

mod:AddSetIconOption("FAIcons", 41001, true)

mod.vb.enrage = false
mod.vb.FAIcon = 1

local GetSpellInfo = GetSpellInfo

local aura = {
	[GetSpellInfo(40880)] = true,
	[GetSpellInfo(40882)] = true,
	[GetSpellInfo(40883)] = true,
	[GetSpellInfo(40891)] = true,
	[GetSpellInfo(40896)] = true,
	[GetSpellInfo(40897)] = true
}

function mod:OnCombatStart(delay)
	mod.vb.FAIcon = 1
	self.vb.prewarn_enrage = false
	self.vb.enrage = false
	timerNextShriek:Start(-delay)
	timerNextFA:Start(50-delay)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end

local function resetFAIcon(self)
	self.vb.FAIcon = 1
end

function mod:SPELL_AURA_APPLIED(args)
	
	if args.spellId == 41001 then
		warnFA:CombinedShow(1, args.destName)
		if args:IsPlayer() then
			specWarnFA:Show()
			specWarnFA:Play("scatter")
		end
		if self.Options.FAIcons then
			self:Unschedule(resetFAIcon)
			self:SetIcon(args.destName, self.vb.FAIcon, 30)
			self.vb.FAIcon = self.vb.FAIcon + 1
			self:Schedule(0.5, resetFAIcon, self)
			
		end
		if self:AntiSpam(3, args.spellName) then
			timerNextFA:Start()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 41001 and self.Options.FAIcons then
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 40823 then
		warnShriek:Show()
		timerNextShriek:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, source)
	if not self.vb.enrage and (source or "") == L.name then
		self.vb.enrage = true
		warnEnrage:Show()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if aura[spellName] then
		timerAura:Start(spellName)
	end
end

