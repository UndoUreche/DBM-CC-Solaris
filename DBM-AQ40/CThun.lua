local mod	= DBM:NewMod("CThun", "DBM-AQ40", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(15589, 15727)

mod:SetUsedIcons(1)

mod:RegisterCombat("combat")
mod:SetWipeTime(25)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 26134",
	"SPELL_CAST_SUCCESS 26139 26478 26029",
	"SPELL_AURA_APPLIED_DOSE 26476",
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
local playerStacks = {}
local fleshTentacles = {}
local tentacleMurderCounter = 0

local updateInfoFrame
do
	local twipe = table.wipe
	local lines = {}
	local sortedLines = {}
	
	local function addLine(key, value)
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end
	
		updateInfoFrame = function()
		twipe(lines)
		twipe(sortedLines)
		
		for name, stacks in pairs(playerStacks) do 
			addLine(name, stacks)
		end
		
		local nLines = 0
		for _, health in pairs(fleshTentacles) do
			nLines = nLines + 1
			addLine(L.FleshTent .. " " .. nLines .. "   ", health .. '%')
		end
		return lines, sortedLines
	end

end

function mod:OnCombatStart(delay)
	table.wipe(playerStacks)
	table.wipe(fleshTentacles)
	
	tentacleMurderCounter = 0
	
	self:SetStage(1)
	
	timerClawTentacle:Start(9-delay) -- Combatlog told me, the first Claw Tentacle spawn in 00:00:09, but need more test.
	timerEyeTentacle:Start(45-delay)
	timerDarkGlareCD:Start(-delay)
	
	self:ScheduleMethod(51-delay, "DarkGlare")
	
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(15)
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
	timerClawTentacle:Unschedule()
	timerEyeTentacle:Cancel()
	timerEyeTentacle:Unschedule()

	timerClawTentacle:Schedule(39)
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
	if args.spellId == 26139 or args.spellId == 26478 or args.spellId == 26029 then
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
			elseif cid == 15728 then
				timerGiantClawTentacle:Stop()
				self:UnscheduleMethod("GiantClawTentacle")
	
				timerGiantClawTentacle:Start(59)
	
				self:ScheduleMethod(59, "GiantClawTentacle")
				
			elseif cid == 15334 then
				timerGiantEyeTentacle:Stop()
				self:UnscheduleMethod("GiantEyeTentacle")
				
				timerGiantEyeTentacle:Start(59)
				self:ScheduleMethod(59, "GiantEyeTentacle")
				
			-- elseif args.spellId == 15589 then
				-- self:UnscheduleMethod("DarkGlare")
				
				-- self:ScheduleMethod(0, "DarkGlare")
				
				-- print("scheduled glare")
			end
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 26476 then
		self:SendSync("PlayerStomachIn", args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 26476 then
		self:SendSync("PlayerStomachOut", args.destName)
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args) 
	
	for name, _ in pairs(playerStacks) do
	
		local uId = DBM:GetRaidUnitId(name)
		if uId then
			
			local spellName, _, _, count = DBM:UnitDebuff(uId, 26476)
			if spellName and count then
				self:SendSync("PlayerStomachStacksUpdate", name, tonumber(count))
			end

			local targetuId = uId.."target"
			local guid = UnitGUID(targetuId)
			if guid and (mod:GetCIDFromGUID(guid) == 15802) then--Targetting Flesh Tentacle
				self:SendSync("PlayerStomachTentacleUpdate", guid, math.floor(UnitHealth(targetuId) / UnitHealthMax(targetuId) * 100))
			end	
		end
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
		timerDarkGlare:Stop()
		self:UnscheduleMethod("DarkGlare")
		
		timerEyeTentacle:Stop()
		timerClawTentacle:Stop() -- Claw Tentacle never respawns in phase2
		
		timerEyeTentacle:Start(33)
		
		timerGiantClawTentacle:Start(11)
		timerGiantEyeTentacle:Start(41)
		self:ScheduleMethod(11, "GiantClawTentacle")
		self:ScheduleMethod(41, "GiantEyeTentacle")
		
	elseif args.destName == "Flesh Tentacle" then
		fleshTentacles[args.destGUID] = 0
		
		tentacleMurderCounter = tentacleMurderCounter + 1
		
		if tentacleMurderCounter >= 2 then
			tentacleMurderCounter = 0
			
			self:SendSync("Weakened")
		end
	end
end

function mod:OnSync(msg, id, value)
	if not self:IsInCombat() then return end
	if msg == "Weakened" then
		self:UnscheduleMethod("doWeakened")
		self:ScheduleMethod(0.3, "doWeakened")
		
		for k, _ in pairs(fleshTentacles) do 
			
			fleshTentacles[k] = nil
		end
	
	elseif msg == "PlayerStomachOut" then
		
		playerStacks[id] = nil
	
	elseif msg == "PlayerStomachIn" then
	
		playerStacks[id] = 1.0
		
		if self.Options.InfoFrame and not DBM.InfoFrame:IsShown() then
			DBM.InfoFrame:SetHeader(L.Stomach)
			DBM.InfoFrame:Show(42, "function", updateInfoFrame, false, false)
			DBM.InfoFrame:SetColumns(1)
		end	
		
	elseif msg == "PlayerStomachTentacleUpdate" then
		
		if fleshTentacles[id] == nil or fleshTentacles[id] > value then
			fleshTentacles[id] = value	
		end
		
	elseif msg == "PlayerStomachStacksUpdate" then
		
		value = tonumber(value)
		
		if playerStacks[id] < value then
			playerStacks[id] = value
		end
	end
	
end

function mod:doWeakened() 

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
	
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end