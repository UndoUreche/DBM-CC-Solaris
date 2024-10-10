local mod	= DBM:NewMod("Bloodboil", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230108171130")
mod:SetCreatureID(22948)
mod:SetModelID(21443)
mod:SetHotfixNoticeRev(20230108000000)
mod:SetMinSyncRevision(20230108000000)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 40508",
	"SPELL_CAST_SUCCESS 42005 40491",
	"SPELL_AURA_APPLIED 42005 40481 40491 40604 40594",
	"SPELL_AURA_APPLIED_DOSE 42005 40481",
	"SPELL_AURA_REFRESH 42005 40481",
	"SPELL_AURA_REMOVED 40604 40594"
)


local berserkTimer		= mod:NewBerserkTimer(600)

mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..DBM:GetSpellInfo(38027))
local warnBlood			= mod:NewTargetAnnounce(42005, 3)
local warnWound			= mod:NewStackAnnounce(40481, 2, nil, "Tank", 2)
local warnStrike		= mod:NewTargetNoFilterAnnounce(40491, 3, nil, "Tank", 2)

local specWarnBlood		= mod:NewSpecialWarningStack(42005, nil, 1, nil, nil, 1, 2)

local timerNextBlood		= mod:NewNextTimer(10, 42005, nil, nil, nil, 5, nil, DBM_COMMON_L.IMPORTANT_ICON) 
local timerNextStrike		= mod:NewNextTimer(30, 40491, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON) 

mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..DBM:GetSpellInfo(40594))
local warnRage			= mod:NewTargetAnnounce(40604, 4)
local warnRageSoon		= mod:NewSoonAnnounce(40604, 3)
local warnRageEnd		= mod:NewEndAnnounce(40604, 4)
local warnBreath		= mod:NewSpellAnnounce(40508, 2)

local specWarnRage		= mod:NewSpecialWarningYou(40604, nil, nil, nil, 1, 2)
local yellRage			= mod:NewYell(40604)

local timerNextRage		= mod:NewNextTimer(90, 40604, nil, nil, nil, 3, nil, DBM_COMMON_L.IMPORTANT_ICON) 
local timerRageEnd		= mod:NewBuffActiveTimer(30, 40604, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON) 

mod:AddInfoFrameOption(42005)

function mod:OnCombatStart(delay)
	self:SetStage(1)

	berserkTimer:Start(-delay)
	timerNextBlood:Start(10-delay, 1)  
        timerNextStrike:Start(28-delay, 1)

	warnRageSoon:Schedule(55-delay)
	timerNextRage:Start(60-delay) 
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellInfo(42005))
		DBM.InfoFrame:Show(30, "playerdebuffstacks", 42005, 1)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 40508 then
		warnBreath:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 42005 then
			timerNextBlood:Start()
	elseif spellId == 40491 then
		timerNextStrike:Start()
	end
end

local function warnBloodBoil(amount, destName)

	if UnitName("player") == destName then
		specWarnBlood:Show(amount)     
        	specWarnBlood:Play("targetyou") 
	else 
		warnBlood:CombinedShow(0.8, destName)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 42005 then
		warnBloodBoil(1, args.destName)
	elseif spellId == 40481 then
		local amount = args.amount or 1
		if (amount % 5 == 0) then
			warnWound:Show(args.destName, amount)
		end
	elseif spellId == 40491 then
		warnStrike:Show(args.destName)
	elseif spellId == 40594 then -- Fel Rage (boss)
		self:SetStage(2)

		timerRageEnd:Start()

		warnRageSoon:Schedule(85)
		timerNextRage:Start()

		timerNextBlood:Cancel()
		timerNextBlood:Schedule(20, 10)

		timerNextStrike:AddTime(30)
	elseif spellId == 40604 then -- Fel Rage (player)

		if args:IsPlayer() then
			specWarnRage:Show()
			specWarnRage:Play("targetyou")
			yellRage:Yell()
		else
			warnRage:Show(args.destName)
		end
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args) 
	local spellId = args.spellId

	if spellId == 42005 then
		warnBloodBoil(args.amount, args.destName)

        elseif spellId == 40481 then
                local amount = args.amount or 1
                
		if (amount % 5 == 0) then
                        warnWound:Show(args.destName, amount)
                end
	end
end

function mod:SPELL_AURA_REFRESH(args) 	
        local spellId = args.spellId
        
        if spellId == 42005 then
                warnBloodBoil(5, args.destName)      
        end
end 

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 40594 then--Ending on Boss
		self:SetStage(1)
		warnRageEnd:Show()
	end
end
