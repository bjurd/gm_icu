hook.Add("StartCommand", "icu", function(Player, Command)
	if Player:GetNWEntity("ICU:Controller"):IsValid() then
		Command:ClearButtons()
		Command:ClearMovement()
	end
end)
