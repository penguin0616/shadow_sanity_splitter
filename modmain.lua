--------------------------------------------------------------------------
--[[ Pre-initializing ]]
--------------------------------------------------------------------------
do
	local GLOBAL = GLOBAL
	local modEnv = GLOBAL.getfenv(1)
	local rawget, setmetatable = GLOBAL.rawget, GLOBAL.setmetatable
	setmetatable(modEnv, {
		__index = function(self, index)
			return rawget(GLOBAL, index)
		end
	})

	_G = GLOBAL
end


--------------------------------------------------------------------------
--[[ Functions ]]
--------------------------------------------------------------------------
local function AwardSanity(inst, amount)
	if inst and inst.components.sanity ~= nil then
		--print(string.format("Awarding %s sanity to %s.", amount, tostring(inst)))
		inst.components.sanity:DoDelta(amount)
	end
end

local function CanGetSanity(inst)
	return inst
		and inst:IsValid()
		and inst.components.sanity ~= nil
		and inst.components.health ~= nil
		and not inst.components.health:IsDead()
		and not inst:HasTag("playerghost")
end

local function OnShadowHealthDelta(inst, data)
	-- data { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, afflicter = afflicter, amount = amount })
	if type(data.amount) ~= "number" or data.amount >= 0 then
		return
	end
	
	if type(data.oldpercent) ~= "number" or type(data.newpercent) ~= "number" then
		return
	end
	
	if not inst.components.health then
		return
	end
	
	if not (data.afflicter and type(data.afflicter.HasTag) == "function" and data.afflicter:HasTag("player")) then
		return
	end
	
	if not type(inst._attack_records) == "table" then
		return
	end
	
	-- figure out real amount of damage dealt
	local ideal_percent = math.abs(data.amount) / inst.components.health.maxhealth
	local percent_diff = data.oldpercent - data.newpercent
	
	local actual_percent_taken = math.max(0, math.min(ideal_percent, percent_diff)) -- in case for some reason the percent is negative, math.max(0, ...) will put percent at 0.
	local real_damage = actual_percent_taken * inst.components.health.maxhealth
	
	inst._attack_records[data.afflicter] = (inst._attack_records[data.afflicter] or 0) + real_damage
	--print("OnShadowHealthDelta", inst, data.afflicter, data.amount, real_damage, data.oldpercent, data.newpercent)
end

local function OnShadowKilled(inst, attacker)
	--print("OnShadowKilled", inst.spawnedforplayer, attacker)
	-- note: this gets called before OnShadowAttacked.
	
	local sanity_reward = inst.sanityreward or TUNING.SANITY_SMALL
	print("Sanity reward:", sanity_reward, inst.sanityreward, TUNING.SANITY_SMALL)
	-- in case something's wrong, just follow default game behavior
	if type(inst._attack_records) ~= "table" then
		AwardSanity(attacker, sanity_reward)
		return
	end
	
	print(GetModConfigData("split_type"))
	-- my stuff
	if GetModConfigData("split_type") == 0 then
		-- distribute based on damage dealt
		local total_damage_dealt = 0 -- by players
		
		local to_distribute = {}
		local count = 0
		for fighter, dmg in pairs(inst._attack_records) do
			if CanGetSanity(fighter) then
				count = count + 1
				to_distribute[fighter] = dmg
				total_damage_dealt = total_damage_dealt + dmg
			end
		end
		
		local damage_not_accounted_for = (inst.components.health and inst.components.health.maxhealth - total_damage_dealt) or 0
		
		for fighter, dmg in pairs(to_distribute) do
			local adjusted_dmg = (dmg + damage_not_accounted_for / count)
			local percent_dealt = adjusted_dmg / inst.components.health.maxhealth
			AwardSanity(fighter, sanity_reward * percent_dealt)
		end
		
	elseif GetModConfigData("split_type") == 1 then
		-- distribute based on # of participants
		local valid_participants = {}
		
		-- figure out how many of the participants are actually valid to receive sanity
		for fighter in pairs(inst._attack_records) do
			if CanGetSanity(fighter) then
				table.insert(valid_participants, fighter)
			end
		end
		
		for i,v in pairs(valid_participants) do
			AwardSanity(v, sanity_reward / #valid_participants)
		end
		
	elseif GetModConfigData("split_type") == 2 then
		-- give to shadow "owner", or the killer if the former isn't present/existing.
		if inst.spawnedforplayer and inst.spawnedforplayer:IsValid() then
			AwardSanity(inst.spawnedforplayer, sanity_reward)
		elseif attacker and attacker:IsValid() then
			AwardSanity(attacker, sanity_reward)
		else
			-- well.. the person this belonged to is gone and so is the attacker?
		end
	end
end

local function OnShadowPostInit(inst)
	inst._attack_records = {}
	inst:ListenForEvent("healthdelta", OnShadowHealthDelta)
	inst.components.combat.onkilledbyother = OnShadowKilled
	
	inst:DoTaskInTime(0, function()
		-- next frame to get inst.spawnedforplayer
		--print("Spawnedforplayer", inst.spawnedforplayer)
	end)
end

--------------------------------------------------------------------------
--[[ Initializing ]]
--------------------------------------------------------------------------
AddPrefabPostInit("crawlinghorror", OnShadowPostInit)
AddPrefabPostInit("terrorbeak", OnShadowPostInit)
AddPrefabPostInit("oceanhorror", OnShadowPostInit)


