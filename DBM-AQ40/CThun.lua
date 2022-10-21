local mod	= DBM:NewMod("CThun", "DBM-AQ40", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(15589, 15727)

mod:SetUsedIcons(1)

mod:RegisterCombat("combat")
mod:SetWipeTime(25)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 26134",
	"SPELL_CAST_SUCCESS 26139 26478",
	-- "SPELL_DAMAGE 26478",
	"SPELL_AURA_APPLIED 26476",
	"SPELL_AURA_REMOVED 26476",
	"CHAT_MSG_MONSTER_EMOTE",
	"UNIT_DIED",
	"CHAT_MSG_ADDON"
)

local warnEyeTentacle			= mod:NewAnnounce("WarnEyeTentacle", 2, 126)
local warnClawTentacle			= mod:NewAnnounce("WarnClawTentacle2", 2, 26391, false)
local warnGiantEyeTentacle		= mod:NewAnnounce("WarnGiantEyeTentacle", 3, 126)
local warnGiantClawTentacle		= mod:NewAnnounce("WarnGiantClawTentacle", 3, 26391)
local warnPhase2				= mod:NewPhaseAnnounce(2)

local specWarnDarkGlare			= mod:NewSpecialWarningDodge(26029, nil, nil, nil, 3, 2)
local specWarnWeakened			= mod:NewSpecialWarning("SpecWarnWeakened", nil, nil, nil, 2, 2, nil, 28598)
local specWarnEyeBeam			= mod:NewSpecialWarningYou(26134, nil, nil, nil, 1, 2)
local yellEyeBeam				= mod:NewYell(26134)

local timerDarkGlareCD			= mod:NewNextTimer(50, 26029)
local timerDarkGlare			= mod:NewBuffActiveTimer(35, 26029)
local timerEyeTentacle			= mod:NewTimer(45, "TimerEyeTentacle", 126, nil, nil, 1)
local timerGiantEyeTentacle		= mod:NewTimer(60, "TimerGiantEyeTentacle", 126, nil, nil, 1)
local timerClawTentacle			= mod:NewTimer(8, "TimerClawTentacle", 26391, nil, nil, 1) -- every 8 seconds
local timerGiantClawTentacle	= mod:NewTimer(60, "TimerGiantClawTentacle", 26391, nil, nil, 1)
local timerWeakened				= mod:NewTimer(45, "TimerWeakened", 28598)

mod:AddRangeFrameOption("10")
mod:AddSetIconOption("SetIconOnEyeBeam", 26134, true, false, {1})
mod:AddInfoFrameOption(nil, true)

local firstBossMod = DBM:GetModByName("AQ40Trash")
local playersInStomach = {}
local fleshTentacles, diedTentacles = {}, {}
local tentacleMurderCounter = 0
-- local weakened = false

local updateInfoFrame
do
	local twipe = table.wipe
	local lines = {}
	local sortedLines = {}
	local function addLine(key, value)
		-- sort by insertion order
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end
	updateInfoFrame = function()
		twipe(lines)
		twipe(sortedLines)
		--First, process players in stomach and gather tentacle information and debuff stacks
		for i = 1, #playersInStomach do
			local name = playersInStomach[i]
			local uId = DBM:GetRaidUnitId(name)
			if uId then
				--First, display their stomach debuff stacks
				local spellName, _, count = DBM:UnitDebuff(uId, 26476)
				if spellName and count then
					addLine(name, count)
				end
				--Also, process their target information for tentacles
				local targetuId = uId.."target"
				local guid = UnitGUID(targetuId)
				if guid and (mod:GetCIDFromGUID(guid) == 15802) and not diedTentacles[guid] then--Targetting Flesh Tentacle
					fleshTentacles[guid] = math.floor(UnitHealth(targetuId) / UnitHealthMax(targetuId) * 100)
				end
			end
		end
		--Now, show tentacle data after it's been updated from player processing
		local nLines = 0
		for _, health in pairs(fleshTentacles) do
			nLines = nLines + 1
			addLine(L.FleshTent .. " " .. nLines, health .. '%')
		end
		return lines, sortedLines
	end
end

function mod:OnCombatStart(delay)
	table.wipe(playersInStomach)
	table.wipe(fleshTentacles)
	table.wipe(diedTentacles)
	
	tentacleMurderCounter = 0
	--weakened = false
	
	self:SetStage(1)
	
	timerClawTentacle:Start(9-delay) -- Combatlog told me, the first Claw Tentacle spawn in 00:00:09, but need more test.
	timerEyeTentacle:Start(45-delay)
	timerDarkGlareCD:Start(-delay)
	
	self:ScheduleMethod(51-delay, "DarkGlare")
	
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10)
	end
end

function mod:OnCombatEnd(wipe, isSecondRun)

	timerClawTentacle:Stop()
	timerDarkGlareCD:Stop()
	timerEyeTentacle:Stop()
	timerGiantClawTentacle:Stop()
	timerGiantEyeTentacle:Stop()
	
	self:UnscheduleMethod("GiantClawTentacle")
	self:UnscheduleMethod("GiantEyeTentacle")

	table.wipe(diedTentacles)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
	--Only run on second run, to ensure trash mod has had enough time to update requiredBosses
	if not wipe and isSecondRun and firstBossMod.vb.firstEngageTime and firstBossMod.Options.SpeedClearTimer then
		if firstBossMod.vb.requiredBosses < 5 then
			DBM:AddMsg(L.NotValid:format(5 - firstBossMod.vb.requiredBosses .. "/4"))
		end
	end
end

function mod:DarkGlare()
	if not UnitIsDeadOrGhost("player") then
		specWarnDarkGlare:Show()
		specWarnDarkGlare:Play("watchstep")
	end
	
	timerDarkGlare:Schedule(3)
	timerDarkGlareCD:Schedule(39)

	timerClawTentacle:Cancel()
	timerEyeTentacle:Cancel()

	timerClawTentacle:Schedule(39, 8)
	timerEyeTentacle:Schedule(39, 45)
	
	self:ScheduleMethod(89, "DarkGlare")
end

function mod:EyeBeamTarget(targetname)
	if not targetname then 
		return 
	end
	
	if self.Options.SetIconOnEyeBeam then
		self:SetIcon(targetname, 1, 3)
	end
	if targetname == UnitName("player") then
		specWarnEyeBeam:Show()
		specWarnEyeBeam:Play("targetyou")
		yellEyeBeam:Yell()
	end
end

function mod:GiantEyeTentacle()
	warnGiantEyeTentacle:Show()
	
	timerGiantEyeTentacle:Stop()
	
	timerGiantEyeTentacle:Start(60)
	
	self:ScheduleMethod(60, "GiantEyeTentacle")
end

function mod:GiantClawTentacle()
	warnGiantClawTentacle:Show()
	
	timerGiantClawTentacle:Stop()
	
	timerGiantClawTentacle:Start(60)
	
	self:ScheduleMethod(60, "GiantClawTentacle")
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 26134 and args:IsSrcTypeHostile() then
		-- the eye target can change to the correct target a tiny bit after the cast starts
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "EyeBeamTarget", 0.1, 3)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 26139 then
		 
		 local cid = self:GetCIDFromGUID(args.sourceGUID)
		 
		 if self:AntiSpam(5, cid) then
			if cid == 15726 then--Eye Tentacle
				warnEyeTentacle:Show()
				
				timerEyeTentacle:Stop()
				
				timerEyeTentacle:Start(self.vb.phase == 2 and 30 or 45)
			elseif cid == 15725 then -- Claw Tentacle
				warnClawTentacle:Show()
				
				timerClawTentacle:Stop()
				
				timerClawTentacle:Start()
			end
		end
	end
end

-- function mod:SPELL_DAMAGE(_, sourceName, _, _, _, _, spellId) 

	-- if spellId == 26478 and not weakened then
		 
		-- if sourceName  ==  "Giant Eye Tentacle" then -- Giant Eye Tentacle
			-- timerGiantEyeTentacle:Stop()
			-- self:UnscheduleMethod("GiantEyeTentacle")
			
			-- timerGiantEyeTentacle:Start()
			-- self:ScheduleMethod(60, "GiantEyeTentacle")
			
		-- elseif sourceName  ==  "Giant Claw Tentacle" then -- Giant Claw Tentacle
			-- timerGiantClawTentacle:Stop()
			-- self:UnscheduleMethod("GiantClawTentacle")
			
			-- timerGiantClawTentacle:Start()
			-- self:ScheduleMethod(60, "GiantClawTentacle")
		-- end
	-- end
-- end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 26476 then
		--I'm aware debuff stacks, but it's a context that doesn't matter to this mod
		if not tContains(playersInStomach, args.destName) then
			table.insert(playersInStomach, args.destName)
		end
		if self.Options.InfoFrame and not DBM.InfoFrame:IsShown() then
			DBM.InfoFrame:SetHeader(L.Stomach)
			DBM.InfoFrame:Show(42, "function", updateInfoFrame, false, false)
			DBM.InfoFrame:SetColumns(1)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 26476 then
		tDeleteItem(playersInStomach, args.destName)
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.Weakened or msg:find(L.Weakened) then
		self:SendSync("Weakened")
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 15589 then -- Eye of C'Thun
		self:SetStage(2)
		warnPhase2:Show()
		
		timerDarkGlareCD:Stop()
		self:UnscheduleMethod("DarkGlare")
		
		timerEyeTentacle:Stop()
		timerClawTentacle:Stop() -- Claw Tentacle never respawns in phase2
		
		timerEyeTentacle:Start(33)
		
		timerGiantClawTentacle:Start(11)
		timerGiantEyeTentacle:Start(41)
		self:ScheduleMethod(11, "GiantClawTentacle")
		self:ScheduleMethod(41, "GiantEyeTentacle")
		
	elseif args.destName == "Flesh Tentacle" then
		fleshTentacles[args.destGUID] = nil
		diedTentacles[args.destGUID] = true
		
		tentacleMurderCounter = tentacleMurderCounter + 1
		
		if tentacleMurderCounter >= 2 then
			tentacleMurderCounter = 0
			
			SendAddonMessage("DBM_CTHUN_WEAKENED", "", "RAID");
		end
	end
end

function mod:CHAT_MSG_ADDON(prefix, msg) 
	if not self:IsInCombat() then return end
	
	if prefix == "DBM_CTHUN_WEAKENED" and not UnitIsDeadOrGhost("player") then 
		self:UnscheduleMethod("Weakened")
		self:ScheduleMethod(0.5, "Weakened")
	end
end

-- local function disableWeakenedState() 
	-- weakened = false 
-- end

function mod:Weakened()
	if not self:IsInCombat() then 
		return 
	end
	
	table.wipe(fleshTentacles)
	specWarnWeakened:Show()
	specWarnWeakened:Play("targetchange")

	timerWeakened:Start()
	
	timerEyeTentacle:Stop()
	timerGiantClawTentacle:Stop()
	timerGiantEyeTentacle:Stop()
	self:UnscheduleMethod("GiantClawTentacle")
	self:UnscheduleMethod("GiantEyeTentacle")
	
	timerEyeTentacle:Schedule(45, 30)
	timerGiantClawTentacle:Schedule(45, 8)
	self:ScheduleMethod(53, "GiantClawTentacle")
	timerGiantEyeTentacle:Schedule(45, 38)
	self:ScheduleMethod(83, "GiantEyeTentacle")
	
	-- weakened = true
	-- self:Schedule(45, disableWeakenedState)
	
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end