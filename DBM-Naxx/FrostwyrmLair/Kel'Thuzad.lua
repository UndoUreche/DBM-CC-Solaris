local mod	= DBM:NewMod("Kel'Thuzad", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

local select, tContains = select, tContains
local PickupInventoryItem, PutItemInBackpack, UseEquipmentSet, CancelUnitBuff = PickupInventoryItem, PutItemInBackpack, UseEquipmentSet, CancelUnitBuff
local UnitClass = UnitClass

mod:SetRevision("20221030130154")
mod:SetCreatureID(15990)
mod:SetModelID("creature/lich/lich.m2")
mod:SetMinCombatTime(60)
mod:SetUsedIcons(1, 2, 3, 8)

mod:RegisterCombat("combat_yell", L.Yell)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 27808 27819 28410",
	"SPELL_AURA_REMOVED 28410",
	"SPELL_CAST_SUCCESS 27810 27819 27808 28410",
	"UNIT_HEALTH",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnAddsSoon			= mod:NewAnnounce("warnAddsSoon", 1, "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01")
local warnPhase2			= mod:NewPhaseAnnounce(2, 3)
local warnBlastTargets			= mod:NewTargetAnnounce(27808, 2)
local warnFissure			= mod:NewTargetNoFilterAnnounce(27810, 4)
local warnMana				= mod:NewTargetAnnounce(27819, 2)
local warnChainsTargets			= mod:NewTargetNoFilterAnnounce(28410, 4)
local warnMindControlSoon		= mod:NewSoonAnnounce(28410, 4)

local specwarnP2Soon			= mod:NewSpecialWarning("specwarnP2Soon")
local specWarnManaBomb			= mod:NewSpecialWarningMoveAway(27819, nil, nil, nil, 1, 2)
local specWarnManaBombNear		= mod:NewSpecialWarningClose(27819, nil, nil, nil, 1, 2)
local yellManaBomb			= mod:NewShortYell(27819)
local specWarnBlast			= mod:NewSpecialWarningTarget(27808, "Healer", nil, nil, 1, 2)
local specWarnFissureYou		= mod:NewSpecialWarningYou(27810, nil, nil, nil, 3, 2)
local specWarnFissureClose		= mod:NewSpecialWarningClose(27810, nil, nil, nil, 2, 8)
local yellFissure			= mod:NewYellMe(27810)

local blastTimer			= mod:NewBuffActiveTimer(4, 27808, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)
local timerManaBomb			= mod:NewNextTimer(30, 27819, nil, nil, nil, 3)
local timerFrostBlast			= mod:NewNextTimer(45, 27808, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerFissure			= mod:NewTargetTimer(5, 27810, nil, nil, 2, 3)
local timerFissureCD 			= mod:NewNextTimer(25, 27810, nil, nil, nil, 3, nil, nil, true)
local timerMC				= mod:NewBuffActiveTimer(20, 28410, nil, nil, nil, 3)
local timerMCCD				= mod:NewNextTimer(90, 28410, nil, nil, nil, 3)
local timerPhase2			= mod:NewTimer(228, "TimerPhase2", nil, nil, nil, 6)

mod:AddRangeFrameOption("11", 27808)
mod:AddSetIconOption("SetIconOnMC", 28410, true, false, {1, 2, 3})
mod:AddSetIconOption("SetIconOnManaBomb", 27819, false, false, {8})

local RaidWarningFrame = RaidWarningFrame
local GetFramesRegisteredForEvent, RaidNotice_AddMessage = GetFramesRegisteredForEvent, RaidNotice_AddMessage
local function selfWarnMissingSet()
	if mod.Options.EqUneqWeaponsKT and not mod:IsEquipmentSetAvailable("pve") then
		for i = 1, select("#", GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING")) do
			local frame = select(i, GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING"))
			if frame.AddMessage then
				frame.AddMessage(frame, L.setMissing)
			end
		end
		RaidNotice_AddMessage(RaidWarningFrame, L.setMissing, ChatTypeInfo["RAID_WARNING"])
	end
end

mod.vb.warnedAdds = false
mod.vb.MCIcon = 1
local frostBlastTargets = {}
local chainsTargets = {}

local function AnnounceChainsTargets(self)
	warnChainsTargets:Show(table.concat(chainsTargets, "< >"))
	if (not tContains(chainsTargets, UnitName("player")) and self.Options.EqUneqWeaponsKT and self:IsDps()) then
		DBM:Debug("Equipping scheduled",2)
		self:Schedule(1.0, EqWKT, self)
		self:Schedule(2.0, EqWKT, self)
		self:Schedule(3.6, EqWKT, self)
		self:Schedule(5.0, EqWKT, self)
		self:Schedule(6.0, EqWKT, self)
		self:Schedule(8.0, EqWKT, self)
		self:Schedule(10.0, EqWKT, self)
		self:Schedule(12.0, EqWKT, self)
	end
	table.wipe(chainsTargets)
	self.vb.MCIcon = 1
end

local function AnnounceBlastTargets(self)
	if self.Options.SpecWarn27808target then
		specWarnBlast:Show(table.concat(frostBlastTargets, "< >"))
		specWarnBlast:Play("healall")
	else
		warnBlastTargets:Show(table.concat(frostBlastTargets, "< >"))
	end
	blastTimer:Start(4)
	table.wipe(frostBlastTargets)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	table.wipe(chainsTargets)
	table.wipe(frostBlastTargets)
	self.vb.warnedAdds = false
	self.vb.MCIcon = 1
	specwarnP2Soon:Schedule(218-delay)
	timerPhase2:Start()
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 27810 then
		timerFissure:Start(args.destName)
		timerFissureCD:Start()
		if args:IsPlayer() then
			specWarnFissureYou:Show()
			specWarnFissureYou:Play("targetyou")
			yellFissure:Yell()
		elseif self:CheckNearby(8, args.destName) then
			specWarnFissureClose:Show(args.destName)
			specWarnFissureClose:Play("watchfeet")
		else
			warnFissure:Show(args.destName)
			warnFissure:Play("watchstep")
		end
	elseif spellId == 27819 then
		timerManaBomb:Start()
	elseif spellId == 27808 then
		timerFrostBlast:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 27808 then -- Frost Blast
		table.insert(frostBlastTargets, args.destName)
		self:Unschedule(AnnounceBlastTargets)
		self:Schedule(0.5, AnnounceBlastTargets, self)
	elseif spellId == 27819 then -- Detonate Mana
		if self.Options.SetIconOnManaBomb then
			self:SetIcon(args.destName, 8, 5.5)
		end
		if args:IsPlayer() then
			specWarnManaBomb:Show()
			specWarnManaBomb:Play("bombrun")
			yellManaBomb:Yell()
		elseif self:CheckNearby(12, args.destName) then
			specWarnManaBombNear:Show(args.destName)
			specWarnManaBombNear:Play("scatter")
		else
			warnMana:Show(args.destName)
		end
	elseif spellId == 28410 then -- Chains of Kel'Thuzad
		chainsTargets[#chainsTargets + 1] = args.destName
		if self:AntiSpam() then
			timerMC:Start()
			timerMCCD:Start()
			warnMindControlSoon:Schedule(85)
		end
		if self.Options.SetIconOnMC then
			self:SetIcon(args.destName, self.vb.MCIcon)
		end
		self.vb.MCIcon = self.vb.MCIcon + 1
		self:Unschedule(AnnounceChainsTargets)
		if #chainsTargets >= 3 then
			AnnounceChainsTargets(self)
		else
			self:Schedule(1.0, AnnounceChainsTargets, self)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 28410 then
		if self.Options.SetIconOnMC then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not self.vb.warnedAdds and self:GetUnitCreatureId(uId) == 15990 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.48 then
		self.vb.warnedAdds = true
		warnAddsSoon:Show()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.Phase2 or msg:find(L.Phase2) then
		self:SetStage(2)
		warnPhase2:Show()
		warnPhase2:Play("ptwo")

		timerFrostBlast:Start()
		timerFissureCD:Start()
		timerManaBomb:Start()


		if self:IsDifficulty("normal25") then
			timerMCCD:Start()
			warnMindControlSoon:Schedule(85)
		end
		if self.Options.EqUneqWeaponsKT and self:IsDps() then
			self:Schedule(60, UnWKT, self)
			self:Schedule(60.5, UnWKT, self)
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(11)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Guardians or msg:find(L.Guardians) then
		timerFrostBlast:AddTime(5.5)
		timerFissureCD:AddTime(5.5)
		timerManaBomb:AddTime(5.5)

		if self:IsDifficulty("normal25") then
			timerMCCD:AddTime(5.5)

			warnMindControlSoon:Cancel()
			warnMindControlSoon:Schedule(timerMCCD:GetRemaining() - 5)
		end
	end
end
