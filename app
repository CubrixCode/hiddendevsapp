module.Attack = function(char,Target,HealthCheck,Knockback,DamageBoost,HeavyAttack,SetSounds,inverse)
	if Target:FindFirstChild('Immune') then return end -- checking if there for example loading in
	if Target:FindFirstChild('Safe Mode') then return end
	local Config = module.GetConfig(char) -- getting combat values from both players like stuns
	local EnemyConfig = module.GetConfig(Target)
	local Player =  nil -- getting some variables defined
	local Stats = nil
	local EnemyPlayer = nil
	local EnemyStats = nil
	if game.Players:FindFirstChild(char.Name) then
		Player = game.Players:FindFirstChild(char.Name)
		Stats = module.GetStats(Player) -- getting stats from player like the level
	end
	local Damage = 3
	
	if Player then
		Damage = 3 + (Stats.Level.Value/18) -- scaling damage with level
	end
		
	
	if HeavyAttack == true then
		Damage = 4 
		if Player then 
			Damage = 4 + (Stats.Level.Value/15) -- scaling damage with level
		end
	end
		
		
	if DamageBoost ~= false then
		Damage = Damage + DamageBoost -- any damage boost from the functions parameters
	end
	if Player then
		if char.Health.Value < HealthCheck then -- checking from functions parameters if they can be damage beyond a point of HP like so a move cant get you below 30 hp for example
			return
		end
		Damage = Damage + (Stats.PhysicalStrength.Value / 2) -- getting physical stat point damage
		if char:FindFirstChild('Weapon') then
			if char.Weapon:FindFirstChild('Damage') then -- damage value from the weapon
				local WeaponDamage = char.Weapon:FindFirstChild('Damage').Value
				Damage = Damage + (WeaponDamage * Stats.Level.Value/22) -- adding up all the damage
				if Stats.Trait.Value == 'Blade Master' then
					Damage = Damage * 1.2 -- a perk that allows more damage
				end
				if Stats.EquippedTorsoAccessory.Value == 'The Totem of Rōg' then
					if char.Health.Value <= (char.Health.MaxValue / 2) then
						Damage = Damage + (Damage * .3) -- a damage boosting accessory
					end
				end
			end
		end
	end
	if char.HumanoidRootPart:FindFirstChild('KBV') and Player ~= nil then -- checking for knockback on the attacker
		return
	end
	if Target.HumanoidRootPart:FindFirstChild('KBV') then -- checking for knockback on the target
		return
	end
	if Config.Stunned.Value == true and Player ~= nil then return end -- checking for stuns
	if Config.FullyStunned.Value == true and Player ~= nil then return end
	if Config.Swung.Value == true and EnemyConfig.Swung.Value == true then -- deflect checking
		if char:FindFirstChild('Weapon') and Target:FindFirstChild('Weapon') then
			pcall(function()
				char.Weapon.Deflect.Value = true
			end)
			pcall(function()
				Target.Weapon.Deflect.Value = true
			end)
			Config.Stunned.Value = true -- stunning then releasing the stun
			EnemyConfig.Stunned.Value = true
			task.spawn(function()
				task.wait(.4)
				Config.Stunned.Value = false
				EnemyConfig.Stunned.Value = false
			end)
			if char:FindFirstChild('Boss') then -- seeing if there is a boss attacking and making enemies screen shake
				spawn(function()
					for _,v in pairs (game.Players:GetPlayers()) do
						if v and v.Character and v.Character:FindFirstChild('HumanoidRootPart') then
							if (v.Character.HumanoidRootPart.Position - char.Weapon.Position).magnitude <= 130 then
								local Shake = script.Shake:Clone()
								Shake.Parent = v.Character
								Shake.Disabled = false
							end
						end
					end
				end)
			end
			return
		end
	end
	pcall(function()
		local effects = {game.ServerStorage.Hit1,game.ServerStorage.Hit2,game.ServerStorage.Hit3} -- attempting to add the hit VFX in
		local a = Instance.new('Attachment')
		a.Parent = Target.Torso
		for i,v in pairs(effects) do
			local clone = v:Clone()
			clone.Parent = a
			clone:Emit(20)
		end
		game.Debris:AddItem(a,1)
	end)
	if EnemyConfig:FindFirstChild('BlockChance') then -- auto block feature
		if EnemyConfig.Blocking.Value == false then
			local BC = EnemyConfig:FindFirstChild('BlockChance')
			if math.random(1,100) <= BC.Value then
				EnemyConfig.Blocking.Value = true
			end
		end
	end
	if EnemyConfig.Blocking.Value == true then
		--print('Blocking')
		if Player == nil then
			--print('nil player')
			if HeavyAttack == true then
				--print('Heavy Attack')
				EnemyConfig.Blocking.Value = false
				EnemyConfig:FindFirstChild('BlockBreak').Value = true -- checking if there blocking to gaurd break if theres a heavy attack
				return false
			end
		end
		if char:FindFirstChild('Weapon') and (Target:FindFirstChild('Weapon') or Target:FindFirstChild('Shield')) then
			if HeavyAttack == true and EnemyPlayer then
				EnemyConfig.Blocking.Value = false
				EnemyConfig:FindFirstChild('BlockBreak').Value = true -- checking if attacker has weapon and target has a weapon or shield for this blockbreak with no VFX
				return false
			end
			if Target:FindFirstChild('Shield') then
				module.PlaySound(Target,game.ServerStorage.Sounds.ShieldHit)
				pcall(function()
					local PSounds = game.ServerStorage.Sounds.ParrySounds:GetChildren()
					local ChosenSound = PSounds[math.random(1,#PSounds)]
					module.PlaySound(Target,ChosenSound)
					char.Weapon.Handle.Attachment.Spark:Emit(30)
                    -- if only the target has shielf then parry sounds play and spars shoot
				end)	
			else
				pcall(function()
					Target.Weapon.Deflect.Value = true
					if char:FindFirstChild('Boss') then
						task.spawn(function() -- checking for boss screen shake again
							for _,v in pairs (game.Players:GetPlayers()) do
								if v and v.Character and v.Character:FindFirstChild('HumanoidRootPart') then
									if (v.Character.HumanoidRootPart.Position - char.Weapon.Position).magnitude <= 130 then
										local Shake = script.Shake:Clone()
										Shake.Parent = v.Character
										Shake.Disabled = false
									end
								end
							end
						end)
					end
					if char:FindFirstChild('HeavyHitter') then -- adding knockback
						local bv = Instance.new("BodyVelocity")
						bv.Name = "KBV"
						bv.MaxForce = Vector3.new(80000,0,80000)
						bv.velocity =  Target.HumanoidRootPart.CFrame.lookVector * -200
						bv.Parent = Target.HumanoidRootPart
						game.Debris:AddItem(bv,.4)
					end
				end)
			end
		else
			if Target:FindFirstChild("Weapon") == nil then
				EnemyConfig.Deflect.Value = true -- deflect check
			end
			local BlockSounds = script.BlockSounds:GetChildren()
			module.PlaySound(char,BlockSounds[math.random(1,#BlockSounds)]) -- picking random noise
		end
		if EnemyPlayer ~= nil then
			Config.Stunned.Value = true -- stunning the attacker from deflect
			EnemyConfig.Stunned.Value = false
			if EnemyPlayer then
				local Drain = Damage -- getting stmina loss for deflecting
				if char:FindFirstChild('Weapon') then
					if char.Weapon:FindFirstChild('WeaponType') then
						if char.Weapon.WeaponType.Value == 'Greatsword' then
							Drain = EnemyPlayer.Stamina.MaxValue / 3 -- different scaling for greatsword
						end
					end
				end
				if EnemyStats.Trait.Value == 'Resilient' then
					Drain = Drain / 2
				end
				EnemyPlayer.Stamina.Value = EnemyPlayer.Stamina.Value - Drain -- applying drain
			end
			task.spawn(function()
				task.wait(.27)
				Config.Stunned.Value = false
			end)
		end
		return 'Blocked'
	end
	module.TagHumanoid(char.Name,Target,Damage) -- damaging
	if char.Config:FindFirstChild('Mode') then
		if module.GetConfig(char).Mode.Value == 'SetABlaze' then
			module.Burn(Player,Target) -- mode check for burning enemies
		end
	end
	
	if Knockback == true or HeavyAttack == true then -- checking if its a heavier attack
		if SetSounds ~= nil and (type(SetSounds) ~= 'boolean') then
			if SetSounds:IsA('Folder') then
				local HitSounds = SetSounds:GetChildren()
				module.PlaySound(char,HitSounds[math.random(1,#HitSounds)])	  -- checking if theres set sounds and playing them
			end
		else
			module.PlaySound(char,script["Heavy Hit"])	-- if not play this sound
		end
		module.KnockBack(char,Target)
		if EnemyConfig:FindFirstChild('HitByKB') then
			EnemyConfig:FindFirstChild('HitByKB').Value = true
		end
		EnemyConfig.Stunned.Value = true
	else
		if EnemyConfig:FindFirstChild('HitByMelee') then -- hitbymelee value for other modules
			EnemyConfig:FindFirstChild('HitByMelee').Value = true
		end
		local HitSounds 
		if SetSounds ~= nil and SetSounds:IsA('Folder')then
			HitSounds = SetSounds:GetChildren() -- gathering sounds for non heavier attacks
		else
			HitSounds = script.HitSounds:GetChildren()	
		end
		if Player and Stats then
			if char:FindFirstChild('Weapon') then
				if Target.Health.Value > 0 then
					local Type = char.Weapon.WeaponType.Value
					local exp = Stats:FindFirstChild(Type..'MasteryExperience') -- mastery training to get weapon skills
					if Stats.Trait.Value == 'Blade Master' then
						exp.Value = exp.Value + 2.5
					else
						exp.Value = exp.Value + 1.5
					end
				end
			end
		end
		module.PlaySound(char,HitSounds[math.random(1,#HitSounds)])	-- playing gathered sounds
		local bv = Instance.new("BodyVelocity")
		bv.Name = "HITBV" -- movement on attack
		bv.MaxForce = Vector3.new(80000,0,80000)
		if inverse ~= nil then
			if inverse == true then
				bv.Velocity = char.HumanoidRootPart.CFrame.lookVector * -4
			else
				bv.Velocity = char.HumanoidRootPart.CFrame.lookVector * 4
			end
		else
			bv.Velocity = char.HumanoidRootPart.CFrame.lookVector * 4
		end
	-- slight movement
		bv.Parent = Target.HumanoidRootPart
		game.Debris:AddItem(bv,.3)		
		task.spawn(function()
			EnemyConfig.Stunned.Value = true
			EnemyConfig.CanBlock.Value = false
			repeat  -- setting all these falues
				task.wait(.1) 
				pcall(function()
					EnemyConfig.Blocking.Value = false
				end)
			until Config.Attacking.Value == false or Config.Stunned.Value == true or Config.FullyStunned.Value == true or (Target.HumanoidRootPart.Position - char.HumanoidRootPart.Position).magnitude >= 10 -- checking if the character stops attacking or target is nearby
			if EnemyConfig then -- unstunning and allowing enemies to go free
				if EnemyConfig:FindFirstChild('Stunned') then
					EnemyConfig.Stunned.Value = false
					EnemyConfig.CanBlock.Value = true
				end
			end
		end)
	end
end
