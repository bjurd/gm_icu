hook.Add("StartCommand", "iControlU", function(Player, Command)
	if Player:IsICUTargeted() then
		Command:ClearButtons()
		Command:ClearMovement()
		Command:SetMouseX(0)
		Command:SetMouseY(0)

		icu.ApplyTargetCommand(Player, Command)
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
