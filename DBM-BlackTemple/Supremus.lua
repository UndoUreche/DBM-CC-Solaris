local mod	= DBM:NewMod("Supremus", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230108174447")
mod:SetCreatureID(22898)
mod:SetModelID(21145)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230108000000)
mod:SetMinSyncRevision(20230108000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_DAMAGE 40265 42052",
        "SPELL_MISSED 40265 42052"
)

local warnPhase			= mod:NewAnnounce("WarnPhase", 4, 42052)
local timerPhase		= mod:NewTimer(60, "TimerPhase", 42052, nil, nil, 6)

local berserkTimer		= mod:NewBerserkTimer(900)

local specWarnMolten	= mod:NewSpecialWarningMove(40265, nil, nil, nil, 1, 2)
local specWarnVolcano   = mod:NewSpecialWarningMove(42052, nil, nil, nil, 1, 2)

local warnFixate		= mod:NewTargetNoFilterAnnounce(41295, 3)
local specWarnFixate	= mod:NewSpecialWarningRun(41295, nil, nil, nil, 4, 2)

mod:AddBoolOption("KiteIcon", true)

mod.vb.lastTarget = "None"
mod.vb.lastPhase = false

local function ScanTarget(self)
        
        local target, uId = self:GetBossTarget(22898)
        if target then
                if self.vb.lastTarget ~= target then
                        self.vb.lastTarget = target
                        if UnitIsUnit(uId, "player") then
                                specWarnFixate:Show()
                                specWarnFixate:Play("justrun")
                                specWarnFixate:ScheduleVoice(1, "keepmove")
                        else
                                warnFixate:Show(target)
                        end
                        if self.Options.KiteIcon then
                                self:SetIcon(target, 8)
                        end
                end
        end
end

local function TankPhase(self) 
	self:SetStage(1)
        
	warnPhase:Show(L.Tank)
        
	self:Unschedule(ScanTarget)
	
	if self.vb.lastTarget ~= "None" then
                self:SetIcon(self.vb.lastTarget, 0)
        end
end

local function KitePhase(self) 
        self:SetStage(2)
        
	warnPhase:Show(L.Kite)
	
	self:Unschedule(ScanTarget)
        self:Schedule(4, ScanTarget, self)
        
	if self.vb.lastTarget ~= "None" then
		self:SetIcon(self.vb.lastTarget, 0)
        end
        
	if self:IsMelee() then
                specWarnFixate:Show()
		specWarnFixate:Play("justrun")
        end
end

local function phaseSwap(self, delay) 

	if mod.vb.lastPhase == false then
		TankPhase(self)
	else
		KitePhase(self)
	end

	mod.vb.lastPhase = not mod.vb.lastPhase

	timerPhase:Start(-delay)
	self:Schedule(60, phaseSwap, self, 0)
end

function mod:OnCombatStart(delay)
        self:SetStage(1)
        berserkTimer:Start(-delay)
        self.vb.lastTarget = "None"
	phaseSwap(self,delay)
end

function mod:OnCombatEnd()
        self:UnregisterShortTermEvents()
        if self.vb.lastTarget ~= "None" then
                self:SetIcon(self.vb.lastTarget, 0)
        end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if spellId == 40265 and destGUID == UnitGUID("player") and self:AntiSpam(4, 1) and not self:IsTrivial() then
		specWarnMolten:Show()
		specWarnMolten:Play("runaway")
	elseif spellId == 42052 and destGUID == UnitGUID("player") and self:AntiSpam(4, 2) and not self:IsTrivial() then
		specWarnVolcano:Show()
		specWarnVolcano:Play("runaway")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	
	if msg == L.ChangeTarget or msg:find(L.ChangeTarget) then
		self:Unschedule(ScanTarget)
		self:Schedule(0.5, ScanTarget, self)
	end
end
