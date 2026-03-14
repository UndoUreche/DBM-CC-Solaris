local mod	= DBM:NewMod("Malygos", "DBM-EyeOfEternity")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220927225043")
mod:SetCreatureID(28859)

--mod:RegisterCombat("yell", L.YellPull)
mod:RegisterCombat("combat")
mod:SetWipeTime(45)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 60936 57407 55853",
	"SPELL_CAST_START 56505",
	"SPELL_CAST_SUCCESS 57430",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_THREAT_LIST_UPDATE",
	"TRACKED_ACHIEVEMENT_UPDATE"
)
-- General
local enrageTimer				= mod:NewBerserkTimer(600)
local timerAchieve				= mod:NewAchievementTimer(360, 1875)

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnSummonPowerSpark			= mod:NewSpellAnnounce(56140, 2, 59381)
local warnVortex				= mod:NewSpellAnnounce(56105, 3)
local warnVortexSoon				= mod:NewSoonAnnounce(56105, 2)

local timerSummonPowerSpark			= mod:NewCDTimer(20, 56140, nil, nil, nil, 1, 59381, DBM_COMMON_L.DAMAGE_ICON)
local timerVortex				= mod:NewCastTimer(11, 56105, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)
local timerVortexCD				= mod:NewNextTimer(60, 56105, nil, nil, nil, 2)

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnPhase2				= mod:NewPhaseAnnounce(2)
local warnBreathInc				= mod:NewSoonAnnounce(56505, 3)

local specWarnBreath				= mod:NewSpecialWarningSpell(56505, nil, nil, nil, 2, 2)

local timerBreath				= mod:NewBuffActiveTimer(8, 56505, nil, nil, nil, 5)
local timerBreathCD				= mod:NewNextTimer(65, 56505, nil, nil, nil, 2)
local timerIntermission				= mod:NewPhaseTimer(24)

-- Stage Three
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3))
local warnPhase3				= mod:NewPhaseAnnounce(3)

local warnSurge					= mod:NewTargetAnnounce(60936, 3)

local specWarnSurge				= mod:NewSpecialWarningDefensive(60936, nil, nil, nil, 1, 2)
--local specWarnStaticField			= mod:NewSpecialWarningYou(57430, nil, nil, nil, 1, 2)
--local specWarnStaticFieldNear			= mod:NewSpecialWarningClose(57430, nil, nil, nil, 1, 2)

--local timerStaticFieldCD			= mod:NewCDTimer(13, 57430, nil, nil, nil, 3, nil, nil, true)

local tableBuild = false
local guids = {}

local hasStarted = false

local function buildGuidTable()
	table.wipe(guids)
	for uId in DBM:GetGroupMembers() do
		local name, server = UnitName(uId)
		local fullName = name .. (server and server ~= "" and ("-" .. server) or "")
		guids[UnitGUID(uId.."pet") or "none"] = fullName
	end
	tableBuild = true
end

function mod:StaticFieldTarget()
	local targetname, uId = self:GetBossTarget(28859)
	if not targetname or not uId then return end
	local targetGuid = UnitGUID(uId)
	if not tableBuild then
		buildGuidTable()
	end
	local announcetarget = guids[targetGuid]
	if announcetarget == UnitName("player") then
		specWarnStaticField:Show()
		specWarnStaticField:Play("runaway")
		yellStaticField:Yell()
	elseif announcetarget and self:CheckNearby(13, announcetarget) then
		specWarnStaticFieldNear:Show(announcetarget)
		specWarnStaticFieldNear:Play("runaway")
	else
		warnStaticField:Show(announcetarget)
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	table.wipe(guids)

	tableBuild = false
	hasStarted = false
end

function mod:TRACKED_ACHIEVEMENT_UPDATE(id)

	if not hasStarted and id == 1875 or id == 1874 then
		self:SendSync("Start", 0)
	end
end

function mod:UNIT_THREAT_LIST_UPDATE(uid)

	if not hasStarted and DBM:GetUnitCreatureId("target") == 28859 and UnitCanAttack("player", "target") then
		self:SendSync("Start", 0)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId

	if spellId == 57430 then
		DBM:AddMsg("Ping Wizs, the big spark can be tracked!")
		--self:ScheduleMethod(0.1, "StaticFieldTarget")
		--timerStaticFieldCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(60936, 57407) then
		local target = guids[args.destGUID or 0]
		if target then
			if target == UnitName("player") then
				specWarnSurge:Show()
				specWarnSurge:Play("defensive")
			else
				warnSurge:CombinedShow(0.5, target)
			end
		end
	elseif args:IsSpellID(55853) then
		self:SendSync("Vortex")
	end
end

function mod:SPELL_CAST_START(args)
	
	if args.spellId == 56505 then--His deep breath
		specWarnBreath:Show()
		specWarnBreath:Play("findshield")
		timerBreath:Start()
		timerBreathCD:Start()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.YellPull or msg:find(L.YellPull)) and not self:IsInCombat() then
		DBM:StartCombat(self, 0)
	elseif msg:sub(0, L.YellPhase1End:len()) == L.YellPhase1End then
		self:SendSync("Phase2")
	elseif msg == L.YellPhase2 or msg:find(L.YellPhase2) then
		self:SendSync("Phase2Start")
	elseif msg == L.YellBreath or msg:find(L.YellBreath) then
		self:SendSync("BreathSoon")
	elseif msg == L.EnoughScream then
		self:SendSync("Phase2End")
	elseif msg:sub(0, L.YellPhase3:len()) == L.YellPhase3 then
		self:SendSync("Phase3")
	elseif msg == L.YellVortex then 
		--vortex yell message triggers a delay on all abilities beside berserk
		if timerSummonPowerSpark:IsStarted() then
			timerSummonPowerSpark:AddTime(25)
		else
			timerSummonPowerSpark:Start(25)
		end
	elseif msg == L.EnoughScream then
		timerBreathCD:Stop()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.EmoteSpark or msg:find(L.EmoteSpark) then
		self:SendSync("Spark")
	elseif msg == L.EmoteSurge or msg:find(L.EmoteSurge) then
		self:SendSync("MalygosSurge", UnitName("player"))
	end
end


function mod:OnSync(event, arg)
	if not self:IsInCombat() then return end
	
	--encounter start trackers are unreliable, therefore the 3 methods of tracking it are used, merged here
	if event == "Start" and self:AntiSpam() then --arg is a dealy
		hasStarted = true

		enrageTimer:Start(-arg)
		timerVortexCD:Start(30-arg)
		timerSummonPowerSpark:Start(10-arg)
		timerAchieve:Start(-arg)

	-- vortex sync to avoid issues with not everyone being affected
	elseif event == "Vortex" and self:AntiSpam() then 
		warnVortex:Show()
		timerVortex:Start()

		timerVortexCD:Start(72)
		warnVortexSoon:Schedule(67)

	elseif event == "Spark" then
		warnSummonPowerSpark:Show()
		timerSummonPowerSpark:Start()

	elseif event == "Phase2" then
		self:SetStage(2)

		warnPhase2:Show()

		timerSummonPowerSpark:Cancel()
		timerVortexCD:Cancel()
		warnVortexSoon:Cancel()
		
		timerIntermission:Start()

	elseif event == "Phase2Start" then
		timerBreathCD:Start(55)

	elseif event == "BreathSoon" then
		warnBreathInc:Show()

	elseif event == "Phase2End" then
		timerBreathCD:Cancel()

	elseif event == "Phase3" then
		self:SetStage(3)
		warnPhase3:Show()

		self:Schedule(6, buildGuidTable)
		
		--timerBreathCD:Cancel()
		--timerStaticFieldCD:Start(20.2)
	end
end
