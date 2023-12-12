local mod	= DBM:NewMod("Tidewalker", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220812215520")
mod:SetCreatureID(21213)

mod:SetUsedIcons(5, 6, 7, 8)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 37730",
	"SPELL_AURA_APPLIED 38028 38023 38024 38025 37850",
	"SPELL_SUMMON 37854",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnTidal			= mod:NewSpellAnnounce(37730, 3)
local warnGrave			= mod:NewTargetNoFilterAnnounce(38049, 4)
local warnBubble		= mod:NewSpellAnnounce(37854, 4)

local specWarnMurlocs	= mod:NewSpecialWarning("SpecWarnMurlocs", nil, nil, nil, nil, nil, nil, 24984, 37764)

local timerNextGrave	= mod:NewNextTimer(25, 38049, nil, nil, nil, 3)
local timerCDMurlocs	= mod:NewCDTimer(37, 37764, nil, nil, nil, 1, nil, nil, nil, nil, nil, nil, nil, 37764)
local timerMurlocsSoon	= mod:NewNextTimer(8, 37764, "Murlocs Soon", nil, "Show timer for Murlocs Soon", 3)
local timerBubble		= mod:NewBuffActiveTimer(35, 37854, nil, nil, nil, 1)

mod:AddSetIconOption("GraveIcon", 38049, true, false, {5, 6, 7, 8})

local warnGraveTargets = {}
mod.vb.graveIcon = 8

local function showGraveTargets()
	warnGrave:Show(table.concat(warnGraveTargets, "<, >"))
	table.wipe(warnGraveTargets)
end

function mod:OnCombatStart(delay)
	self.vb.graveIcon = 8
	table.wipe(warnGraveTargets)
	timerNextGrave:Start(20-delay)
	timerCDMurlocs:Start(40-delay)
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 37730 then
		warnTidal:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(38028, 38023, 38024, 38025, 37850) then
		warnGraveTargets[#warnGraveTargets + 1] = args.destName
		self:Unschedule(showGraveTargets)
		if self.Options.GraveIcon then
			self:SetIcon(args.destName, self.vb.graveIcon)
		end
		self.vb.graveIcon = self.vb.graveIcon - 1
		if #warnGraveTargets >= 4 then
			showGraveTargets()
		else
			self:Schedule(0.3, showGraveTargets)
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 37854 and self:AntiSpam(30) then --TODO consider adding a second timer as the globules overlap should you manage to avoid them for the full duration
		warnBubble:Show()
		timerBubble:Start()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)

	if msg == L.Grave or msg:find(L.Grave) then
		timerNextGrave:Show()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)

	if msg == L.Murlocs or msg:find(L.Murlocs) then
		
		timerMurlocsSoon:Show()
	
		specWarnMurlocs:Schedule(8)
		timerCDMurlocs:Schedule(8)
	end
end
