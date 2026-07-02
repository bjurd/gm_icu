hook.Add("StartCommand", "iControlU", function(Player, Command)
	if Player:IsICUTargeted() then
		Command:ClearButtons()
		Command:ClearMovement()
		Command:SetMouseX(0)
		Command:SetMouseY(0)

		icu.ApplyTargetCommand(Player, Command)

		-- This isn't needed, but it doesn't hurt, the clientside hooks will smooth
		-- this mess out anyways
		local Controller = Player:GetICUController()
		Player:SetPos(Controller:GetPos())
		Player:SetEyeAngles(Controller:EyeAngles())
		Player:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end

	if Player:IsICUControlling() then
		icu.StoreCommand(Player, Command)
	end
end)

hook.Add("CanPlayerSuicide", "iControlU", function(Player)
	if Player:IsICUTargeted() then
		return false
	end
end)
