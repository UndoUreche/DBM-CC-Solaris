local mod	= DBM:NewMod("Gothik", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220629223621")
mod:SetCreatureID(16060)

mod:RegisterCombat("combat")

local warnWaveNow		= mod:NewAnnounce("WarningWaveSpawned", 3, nil, false)
local warnPhase2		= mod:NewPhaseAnnounce(2, 3)

local timerPhase2		= mod:NewTimer(274, "TimerPhase2", 27082, nil, nil, 6)
local timerWave			= mod:NewTimer(25, "TimerWave", 5502, nil, nil, 1)
local timerGate			= mod:NewTimer(120, "Gate Opens", 9484)

mod.vb.wave = 0
local wavesNormal = {
	{2, L.Trainee, timer = 20},
	{2, L.Trainee, timer = 20},
	{2, L.Trainee, timer = 10},
	{1, L.Knight, timer = 10},
	{2, L.Trainee, timer = 15},
	{1, L.Knight, timer = 10},
	{2, L.Trainee, timer = 15},
	{2, L.Trainee, 1, L.Knight, timer = 10},
	{1, L.Rider, timer = 10},
	{2, L.Trainee, timer = 5},
	{2, L.Knight, timer = 15},
	{1, L.Rider, 2, L.Trainee, timer = 10},
	{1, L.Knight, timer = 10},
	{2, L.Trainee, timer = 10},
	{1, L.Rider, timer = 5},
	{1, L.Knight, timer = 5},
	{1, L.Trainee, timer = 20},
	{1, L.Rider, 1, L.Knight, 2, L.Trainee, timer=15},
	{2, L.Trainee}
}

local wavesHeroic = {
	{3, L.Trainee, timer = 20},
	{3, L.Trainee, timer = 20},
	{3, L.Trainee, timer = 10},
	{2, L.Knight, timer = 10},
	{3, L.Trainee, timer = 15},
	{2, L.Knight, timer = 10},
	{3, L.Trainee, timer = 15},
	{3, L.Trainee, 2, L.Knight, timer = 10},
	{1, L.Rider, timer = 10},
	{3, L.Trainee, timer = 5},
	{2, L.Knight, timer = 15},
	{1, L.Rider, 3, L.Trainee, timer = 10},
	{2, L.Knight, timer = 10},
	{3, L.Trainee, timer = 10},
	{1, L.Rider, timer = 5},
	{2, L.Knight, timer = 5},
	{1, L.Trainee, timer = 20},
	{1, L.Rider, 2, L.Knight, 3, L.Trainee, timer=15},
	{3, L.Trainee}
}

local waves = wavesNormal

local function StartPhase2(self)
	self:SetStage(2)
end

local function getWaveString(wave)
	local waveInfo = waves[wave]
	if #waveInfo == 2 then
		return L.WarningWave1:format(unpack(waveInfo))
	elseif #waveInfo == 4 then
		return L.WarningWave2:format(unpack(waveInfo))
	elseif #waveInfo == 6 then
		return L.WarningWave3:format(unpack(waveInfo))
	end
end

local function NextWave(self)
	self.vb.wave = self.vb.wave + 1
	warnWaveNow:Show(self.vb.wave, getWaveString(self.vb.wave))

	local timer = waves[self.vb.wave].timer

	if timer then
		timerWave:Start(timer, self.vb.wave + 1)
		self:Schedule(timer, NextWave, self)
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	if self:IsDifficulty("normal25") then
		waves = wavesHeroic
	else
		waves = wavesNormal
	end
	self.vb.wave = 0
	timerGate:Start(-delay)
	timerPhase2:Start(-delay)
	warnPhase2:Schedule(277-delay)
	timerWave:Start(30-delay, self.vb.wave + 1)
	self:Schedule(30-delay, NextWave, self)
	self:Schedule(274-delay, StartPhase2, self)
end

function mod:OnTimerRecovery()
	if self:IsDifficulty("normal25") then
		waves = wavesHeroic
	else
		waves = wavesNormal
	end
end
