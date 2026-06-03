hook.Add("StartCommand", "icu", function(Player, Command)
	if Player:GetNWEntity("ICU:Controller"):IsValid() then
		Command:ClearButtons()
		Command:ClearMovement()
		Command:SetViewAngles(Player:GetNWAngle("ICU:ViewAngles", Player:EyeAngles()))
	end
end)
