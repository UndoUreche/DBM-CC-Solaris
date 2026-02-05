local mod	= DBM:NewMod("Thaddius", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221008164846")
mod:SetCreatureID(15928)

mod:RegisterCombat("combat_yell", L.Yell)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 28089",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_AURA player"
)

local warnShiftSoon			= mod:NewPreWarnAnnounce(28089, 5, 3)
local warnThrowSoon			= mod:NewSoonAnnounce(28338, 1)

local warnChargeChanged			= mod:NewSpecialWarning("WarningChargeChanged", nil, nil, nil, 3, 2, nil, nil, 28089)
local yellShift				= mod:NewShortPosYell(28089, DBM_CORE_L.AUTO_YELL_CUSTOM_POSITION)

local enrageTimer			= mod:NewBerserkTimer(365)
local timerNextShift			= mod:NewNextTimer(30, 28089, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerShiftCast			= mod:NewCastTimer(3, 28089, nil, nil, nil, 2)
local timerThrow			= mod:NewNextTimer(20, 28338, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)

if not DBM.Options.GroupOptionsBySpell then
	mod:AddMiscLine(DBM_CORE_L.OPTION_CATEGORY_DROPDOWNS)
end

mod:SetBossHealthInfo(
	15930, L.Boss1,
	15929, L.Boss2
)

local currentCharge
local down

local function TankThrow(self)
	if not self:IsInCombat() or self.vb.phase == 2 then
		DBM.BossHealth:Hide()
		return
	end
	timerThrow:Start(23)
	warnThrowSoon:Schedule(21)
	self:Schedule(23, TankThrow, self)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	currentCharge = nil
	down = 0

	self:Schedule(20 - delay, TankThrow, self)
	timerThrow:Start(-delay)
	warnThrowSoon:Schedule(18 - delay)
end

do
	local lastShift
	function mod:SPELL_CAST_START(args)
		if args.spellId == 28089 then
			self:SetStage(2)
			timerNextShift:Start()
			timerShiftCast:Start()
			warnShiftSoon:Schedule(25)
			lastShift = GetTime()
		end
	end

	function mod:UNIT_AURA()
		if self.vb.phase ~= 2 or not lastShift or (GetTime() - lastShift) < 3 then return end
		local charge
		local i = 1
		while UnitDebuff("player", i) do
			local _, _, icon, count = UnitDebuff("player", i)
			if icon == "Interface\\Icons\\Spell_ChargeNegative" then
				if count > 1 then return end	
			
				charge = L.Charge1
				yellShift:Yell(7,"---")
			elseif icon == "Interface\\Icons\\Spell_ChargePositive" then
				if count > 1 then return end

				charge = L.Charge2
				yellShift:Yell(6,"+++")
			end
			i = i + 1
		end
		if charge then
			lastShift = nil
			if charge ~= currentCharge then
				warnChargeChanged:Show(charge)
				warnChargeChanged:Play("stilldanger")
			end
			currentCharge = charge
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg:match(L.Emote) or msg:match(L.Emote2) or msg:find(L.Emote) or msg:find(L.Emote2) or msg == L.Emote or msg == L.Emote2 then
		down = down + 1
		if down >= 2 then
			self:Unschedule(TankThrow)
			DBM.BossHealth:Hide()
			timerThrow:Cancel()
			warnThrowSoon:Cancel()
			enrageTimer:Start()
			timerNextShift:Start(22)
		end
	end
end