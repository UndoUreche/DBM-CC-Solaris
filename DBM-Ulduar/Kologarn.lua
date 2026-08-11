local mod	= DBM:NewMod("Kologarn", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221031105808")
mod:SetCreatureID(32930)
mod:SetUsedIcons(5, 6, 7, 8)

mod:RegisterCombat("yell", L.YellEncounterStart)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 62166 63981",
	"SPELL_AURA_APPLIED 64290 64292 64002 63355",
	"SPELL_AURA_APPLIED_DOSE 64002 63355",
	"SPELL_AURA_REMOVED 64290 64292",
	"SPELL_DAMAGE 63783 63982 63346 63976 64003 64006 63573 63356",
	"SPELL_MISSED 63783 63982 63346 63976 64003 64006 63573 63356",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_DIED"
)

mod:SetBossHealthInfo(
	32930, L.Health_Body,
	32934, L.Health_Right_Arm,
	32933, L.Health_Left_Arm
)

-- General
-- local enrageTimer				= mod:NewBerserkTimer(600) as of right now disabled on CC
local timerTimeForDisarmed		= mod:NewTimer(12, "achievementDisarmed")

-- Kologarn
mod:AddTimerLine(L.name)
local warnFocusedEyebeam		= mod:NewTargetNoFilterAnnounce(63346, 4)
local warnCrunchArmor			= mod:NewStackAnnounce(64002, 2, nil, "Tank|Healer")
local warnSmash					= mod:NewSpellAnnounce(63356, 2)

local specWarnCrunchArmor2		= mod:NewSpecialWarningStack(64002, nil, 2, nil, 2, 1, 6)
local specWarnEyebeam			= mod:NewSpecialWarningRun(63346, nil, nil, nil, 4, 2)
local specWarnEyebeamNear		= mod:NewSpecialWarningClose(63346, nil, nil, nil, 1, 2)
local yellBeam					= mod:NewYell(63346)

local timerNextSmash			= mod:NewNextTimer(14, 63356, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextEyebeam			= mod:NewNextTimer(20, 63346, nil, nil, nil, 3, nil, DBM_COMMON_L.IMPORTANT_ICON)

mod:AddSetIconOption("SetIconOnEyebeamTarget", 63346, true, false, {8})

-- Right Arm
mod:AddTimerLine(L.Health_Right_Arm)
local warnGrip					= mod:NewTargetNoFilterAnnounce(64292, 2)

local timerNextGrip				= mod:NewNextTimer(25, 62166, nil, nil, nil, 3)
local timerRespawnRightArm		= mod:NewTimer(57, "timerRightArm", nil, nil, nil, 1)

mod:AddSetIconOption("SetIconOnGripTarget", 64292, true, false, {7, 6, 5})

-- Left Arm
mod:AddTimerLine(L.Health_Left_Arm)
local warnShockwave				= mod:NewSpellAnnounce(63982, 2)
local timerNextShockwave		= mod:NewNextTimer(17, 63982, nil, nil, nil, 2)
local timerRespawnLeftArm		= mod:NewTimer(57, "timerLeftArm", nil, nil, nil, 1)

mod:GroupSpells(64292, 62166) -- Stone Grip aura and cast

mod.vb.disarmActive = false
local gripTargets = {}

local function armReset(self)
	self.vb.disarmActive = false
end

local function GripAnnounce(self)
	warnGrip:Show(table.concat(gripTargets, "<, >"))
	table.wipe(gripTargets)
end

function mod:OnCombatStart(delay)
--	enrageTimer:Start(-delay)
	timerNextSmash:Start(8-delay)
	timerNextEyebeam:Start(10-delay)
	timerNextShockwave:Start(17-delay)
	timerNextGrip:Start(15-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.IsSpellID(62166, 63981) then -- Stone Grip
		timerNextGrip:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(64290, 64292) then
		if self.Options.SetIconOnGripTarget then
			self:SetIcon(args.destName, 8 - #gripTargets, 10)
		end
		table.insert(gripTargets, args.destName)
		self:Unschedule(GripAnnounce)
		if #gripTargets >= 3 then
			GripAnnounce(self)
		else
			self:Schedule(0.3, GripAnnounce, self)
		end
	elseif args:IsSpellID(64002, 63355) then	-- Crunch Armor
		local amount = args.amount or 1
		if amount >= 2 then
			if args:IsPlayer() then
				specWarnCrunchArmor2:Show(amount)
				specWarnCrunchArmor2:Play("stackhigh")
			else
				warnCrunchArmor:Show(args.destName, amount)
			end
		else
			warnCrunchArmor:Show(args.destName, amount)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(64290, 64292) then
		self:SetIcon(args.destName, 0)
	end
end

function mod:UNIT_DIED(args)

	if self:GetCIDFromGUID(args.destGUID) == 32934 then		-- right arm
		timerRespawnRightArm:Start()
		timerNextGrip:Cancel()
		if not self.vb.disarmActive then
			self.vb.disarmActive = true
			if self:IsDifficulty("normal10") then
				timerTimeForDisarmed:Start()
				self:Schedule(12, armReset, self)
			else
				timerTimeForDisarmed:Start()
				self:Schedule(12, armReset, self)
			end
		else
			timerTimeForDisarmed:Cancel()
		end
	elseif self:GetCIDFromGUID(args.destGUID) == 32933 then		-- left arm
		timerRespawnLeftArm:Start()
		timerNextShockwave:Cancel()
		
		if not self.vb.disarmActive then
			self.vb.disarmActive = true
			if self:IsDifficulty("normal10") then
				timerTimeForDisarmed:Start()
				self:Schedule(12, armReset, self)
			else
				timerTimeForDisarmed:Start()
				self:Schedule(12, armReset, self)
			end
		else
			timerTimeForDisarmed:Cancel()
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, destName, _, spellId)
	if (spellId == 63346 or spellId == 63976) and self:AntiSpam(2, 2) then -- Focused Eyebeam
		if destGUID == UnitGUID("player") then
			specWarnEyebeam:Show()
			
		elseif self:CheckNearby(3, destName) then
			specWarnEyebeamNear:Show(destName)
		end
	elseif spellId == 63356 or spellId == 63573 or spellId == 64003 or spellId == 64006 then -- Overhead Smash
		warnSmash:Show()
		timerNextSmash:Start()
	
		timerNextShockwave:AddTime(1)
		timerNextEyebeam:AddTime(1)
		timerNextGrip:AddTime(1)
	
	elseif (spellId == 63982 or spellId == 63783) and self:AntiSpam(2, 1) then --Arm Sweep
		warnShockwave:Show()
		timerNextShockwave:Start()
		
		timerNextSmash:AddTime(1)
		timerNextEyebeam:AddTime(1)
		timerNextGrip:AddTime(1)
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg == L.FocusedEyebeam or msg:find(L.FocusedEyebeam) then
		self:SendSync("EyeBeamOn", target)
	end
end

function mod:OnSync(msg, target)
	if msg == "EyeBeamOn" and self:AntiSpam(2, 1) then
		
		timerNextEyebeam:Start()
		
		if target == UnitName("player") then
			specWarnEyebeam:Show()
			specWarnEyebeam:Play("justrun")
			specWarnEyebeam:ScheduleVoice(1, "keepmove")
			yellBeam:Yell()
		else
			warnFocusedEyebeam:Show(target)
		end
		
		if self.Options.SetIconOnEyebeamTarget then
			self:SetIcon(target, 5, 8)
		end
	end
end
