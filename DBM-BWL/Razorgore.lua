local mod	= DBM:NewMod("Razorgore", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 188 $"):sub(12, -3))
mod:SetCreatureID(12435)
mod:SetMinSyncRevision(168)
mod:RegisterCombat("yell", L.YellPull)
mod:SetWipeTime(180)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"UNIT_SPELLCAST_SUCCEEDED",
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START 22425"
)

local warnConflagration		= mod:NewTargetAnnounce(23023)
local warnEggsLeft			= mod:NewCountAnnounce(19873, 1)
local warnPhase2			= mod:NewPhaseAnnounce(2)

local timerConflagration	= mod:NewTargetTimer(10, 23023)
local timerAddsSpawn		= mod:NewTimer(45, "TimerAddsSpawn", 19879)

mod:AddSpeedClearOption("BWL", true)

mod.vb.eggsLeft = 30

function mod:OnCombatStart(delay)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPull then
		timerAddsSpawn:Start()
		self:SetStage(1)
		self.vb.eggsLeft = 30
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == "Destroy Egg" then
		self.vb.eggsLeft = self.vb.eggsLeft - 1
		warnEggsLeft:Show(string.format("%d/%d",30-self.vb.eggsLeft,30))
		
		if self.vb.eggsLeft == 0 then 
			warnPhase2:Show()
			self:SetStage(2)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 23023 and args:IsDestTypePlayer() then
		warnConflagration:Show(args.destName)
		timerConflagration:Start(args.destName)
	end
end

function mod:SPELL_CAST_START (args)
	if args.spellId == 23023 and args:IsDestTypePlayer() then
		if self.Options.SpecWarn22425moveto then
			specWarnFireballVolley:Show(DBM_COMMON_L.BREAK_LOS)
			specWarnFireballVolley:Play("findshelter")
		else
			warnFireballVolley:Show()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 23023 then
		timerConflagration:Start(args.destName)
	end
end