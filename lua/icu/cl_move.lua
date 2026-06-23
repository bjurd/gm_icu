hook.Add("StartCommand", "iControlU", function(Player, Command)
	if Player:IsICUTargeted() then
		Command:ClearButtons()
		Command:ClearMovement()
	end
end)

hook.Add("InputMouseApply", "iControlU", function(Command, x, y, Angles)
	if LocalPlayer():IsICUTargeted() then
		Command:SetMouseX(0)
		Command:SetMouseY(0)

		return true
	end
end)

hook.Add("CalcView", "iControlU", function(Player, Origin, Angles, FOV, ZNear, ZFar)
	if Player:IsICUTargeted() then
		local Controller = Player:GetICUController()

		if Controller:IsValid() then
			local ControllerOrigin = Controller:GetPos()
			local Offset = Controller:GetCurrentViewOffset()

			ControllerOrigin:Add(Offset)

			Origin:Set(ControllerOrigin)
		end
	end
end)

hook.Add("CalcViewModelView", "iControlU", function(Weapon, ViewModel, Origin, Angles, BobOrigin, BobAngles)
	if LocalPlayer():IsICUTargeted() then
		local Controller = LocalPlayer():GetICUController()

		if Controller:IsValid() then
			local ControllerOrigin = Controller:GetPos()
			local Offset = Controller:GetCurrentViewOffset()

			ControllerOrigin:Add(Offset)

			return ControllerOrigin, BobAngles
		end
	end
end)

hook.Add("CreateClientsideRagdoll", "iControlU", function(Entity, Ragdoll)
	if Entity:IsPlayer() then
		--- @cast Entity Player

		if Entity:IsICUTargeted() then
			Ragdoll:SetNoDraw(true)
		end
	end
end)

--- @param Player Player
--- @param Flags number
local function PlayerDraw(Player, Flags)
	if LocalPlayer():IsICUTargeted() then
		if Player == LocalPlayer() then
			return true
		end

		if Player == LocalPlayer():GetICUController() then
			return true
		end
	end
end
hook.Add("PrePlayerDraw", "iControlU", PlayerDraw)
hook.Add("PostPlayerDraw", "iControlU", PlayerDraw)

--[=[

--- @param Source Player
--- @param Dest Player
local function CopyPlayerBones(Source, Dest)
	-- TODO: This should be done in BuildBonePositions
	-- This is actually just a lazy way of matching animations, sequences and cycles

	if Source:GetModel() ~= Dest:GetModel() then
		-- Should never happen
		Dest:SetModel(Source:GetModel() --[[@as string]])
	end

	Source:SetupBones()
	Dest:InvalidateBoneCache()
	Dest:SetupBones() -- Let me write da bonez...

	local Bones = Source:GetBoneCount()
	local Matrix = Matrix()

	for i = 0, Bones - 1 do
		Source:CopyBoneMatrix(i, Matrix)
		Dest:SetBoneMatrix(i, Matrix)
	end
end

--- @param Player Player
--- @param Flags number
local function PlayerDraw(Player, Flags)
	if Player:IsICUTargeted() then
		local Controller = Player:GetICUController()

		CopyPlayerBones(Controller, Player)

		-- return true
	end
end
hook.Add("PrePlayerDraw", "iControlU", PlayerDraw)
hook.Add("PostPlayerDraw", "iControlU", PlayerDraw)

--]=]
