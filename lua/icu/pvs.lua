hook.Add("SetupPlayerVisibility", "iControlU", function(Player, ViewEntity)
	if Player:IsICUTargeted() then
		local Controller = Player:GetICUController()

		AddOriginToPVS(Controller:EyePos())
	end
end)

hook.Add("CreateEntityRagdoll", "iControlU", function(Entity, Ragdoll) -- Totally PVS related
	if Entity:IsPlayer() then
		--- @cast Entity Player

		if Entity:IsICUTargeted() then
			Ragdoll:SetNoDraw(true)
			SafeRemoveEntityDelayed(Ragdoll, engine.TickInterval())
		end
	end
end)
