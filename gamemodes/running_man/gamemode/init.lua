----------------------------------------------------------------------------------
-- This is an example gameplay override script
----------------------------------------------------------------------------------

print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("-[ The example gameplay script has been launched! ]-----")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("---------------+- mAy gOd hAvE mErcy On OUr sOUls -+----")
print("--------------------------------------------------------")
print("--------------------------------------------------------")

-- BloberZone
resource.AddWorkshop("3324650478")

include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("drawarc.lua")

util.AddNetworkString("RM_Connect")
util.AddNetworkString("RM_Disconnect")
util.AddNetworkString("RM_NewRunner")
util.AddNetworkString("RM_RunnerHealth")
util.AddNetworkString("RM_Spectate")

local weaponRespawnTime = CreateConVar("rm_weaponrespawntime", "20", FCVAR_ARCHIVE, "Time until a weapon created by the map respawns after pickup.", 0)
local respawningIndexes = {}

local PosUpdate = 0

local dev = false
--  Called every frame from: CHL2MPRules::Think( void ) -----------------------
function GM:Think()
	local weps = self.WeaponsToRespawn
	for i = 1, #weps do
		local wep = weps[i]

		if respawningIndexes[i] then
			if respawningIndexes[i] <= CurTime() then
				local ent = ents.Create(wep.class)
				ent:SetPos(wep.pos)
				ent:SetAngles(wep.ang)
				ent:Spawn()

				ent:EmitSound("weapons/stunstick/alyx_stunner2.wav")

				wep.idx = ent:EntIndex()
				respawningIndexes[i] = nil
			end

			continue
		end

		local wepcheck = Entity(wep.idx)
		if IsValid(wepcheck) and wepcheck:IsWeapon() and !IsValid(wepcheck:GetOwner()) then continue end

		respawningIndexes[i] = CurTime() + weaponRespawnTime:GetInt()
	end

	if dev and IsValid(self.RunningMan) and PosUpdate < CurTime() then
		local InfoString = ""

		local vPos = self.RunningMan:GetPos()

		InfoString = InfoString .. "pos: " .. tostring(vPos)
		InfoString = InfoString .. "\nvel: " .. tostring(self.RunningMan:GetAbsVelocity())

		-- _ScreenText( 0, InfoString,  0.1,0.1,   100,200,255,255,  0,0, 0.50, 0, 4 )
		PrintMessage( HUD_PRINTTALK, InfoString )

		PosUpdate = CurTime() + 0.05
	end

	if !IsValid(self.RunningMan) and self.TimeChooseRunner < CurTime() then
		local iMostFrags = -100
		local iNewRunner

		for _, ply in player.Iterator() do
			if ply:Frags() < iMostFrags then continue end

			iMostFrags = ply:Frags()
			iNewRunner = ply
		end

		if IsValid(iNewRunner) then
			self:NewRunner( iNewRunner )
		end

		self.TimeChooseRunner = CurTime() + 5
	end
end

function GM:PlayerLoadout(ply)
	ply:Give("weapon_pistol")
	ply:Give("weapon_smg1")
	ply:Give("weapon_crowbar")

	ply:GiveAmmo(255, "SMG1", false)

	if ply == self.RunningMan then
		ply:GiveAmmo(3, "smg1_grenade", false)
	else
		ply:Give("weapon_shotgun")
		ply:Give("weapon_physcannon")

		ply:GiveAmmo(128, "Buckshot", false)
	end
end

--  Called right before the new map starts ------------------------------------
function GM:Initialize()
	self.BestRunnerName = ""
	self.BestRunnerKills = 0
	self.CurrentRunnerKills = 0

	self.bWaitingRunnerRespawn = false

	self.TimeChooseRunner = 0

	self.WeaponsToRespawn = {}

	RunConsoleCommand("gmod_maxammo", "0")
end

local removeAllWeapons = CreateConVar("rm_removeallweapons", "0", FCVAR_ARCHIVE, "Remove all map created weapons. Requires restart.")

local storedWepClasses = {
	["weapon_357"] = true,
	["weapon_alyxgun"] = true,
	["weapon_ar2"] = true,
	["weapon_bugbait"] = true,
	["weapon_crossbow"] = true,
	["weapon_frag"] = true,
	["weapon_pistol"] = true,
	["weapon_rpg"] = true,
	["weapon_shotgun"] = true,
	["weapon_slam"] = true,
	["weapon_smg1"] = true,
	["weapon_stunstick"] = true,
	["item_healthkit"] = true
}

function GM:InitPostEntity()
	local weps = ents.FindByClass("weapon*")
	if removeAllWeapons:GetBool() then
		for i = 1, #weps do
			local wep = weps[i]
			if !storedWepClasses[wep:GetClass()] then continue end

			wep:Remove()
		end
	else
		for i = 1, #weps do
			local wep = weps[i]

			local class = wep:GetClass()
			if !storedWepClasses[class] then continue end

			table.insert(self.WeaponsToRespawn, {class = class, idx = wep:EntIndex(), pos = wep:GetPos(), ang = wep:GetAngles()})
		end
	end
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_GREEN)
end

local allowSpawnfrag = CreateConVar("rm_allowspawnfrags", "1", FCVAR_ARCHIVE, "Enable to kill any player that gets stuck when a player spawns on them.", 0, 1)
local function Spawnfrag(victim, attacker)
	if !IsValid(victim) then return end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(5000)
	dmginfo:SetDamageType(DMG_SONIC)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetDamageForce(Vector(0,0,10))
	dmginfo:SetDamagePosition(attacker:GetPos())

	victim:TakeDamageInfo(dmginfo)
end

local runner = Model("models/player/breen.mdl")
local mossman = Model("models/player/mossman.mdl")

local runnerCol = Color(109, 98, 80):ToVector()
local mossmanCol = Color(255, 242, 207):ToVector()

local pmUseTeamCol = CreateConVar("rm_useteamplayercolor", "0", FCVAR_ARCHIVE, "Set playermodel colour to be team-based instead of HL2 defaults.", 0, 1)

-- Player chooses a model (and team in this case)
function GM:PlayerSpawn(ply, transition)
	if ply:Team() == TEAM_SPECTATOR then
		self:PlayerSpawnAsSpectator(ply)
		ply:KillSilent()
		ply:Spectate(OBS_MODE_ROAMING)

		return
	end

	if allowSpawnfrag:GetBool() then
		-- find all players in the place where we will be and telefrag them
		local pos = ply:GetPos()
		local blockers = ents.FindInBox(pos + Vector(-16, -16, 0), pos + Vector(16, 16, 64))
		local blocking_plys = {}
		for i = 1, #blockers do
			local block = blockers[i]

			if IsValid(block) and block:IsPlayer() and block != ply and block:Alive() and block:Team() <= 3 then
				blocking_plys[#blocking_plys + 1] = block
			end
		end

		for i = 1, #blocking_plys do
			Spawnfrag(blocking_plys[i], ply)
		end
	end

	local plytbl = ply:GetTable()

	plytbl.PreventMossmanWeps = false

	-- Stop observer mode
	ply:UnSpectate()

	player_manager.OnPlayerSpawn(ply, transition)
	player_manager.RunClass(ply, "Spawn")

	-- If we are in transition, do not touch player's weapons
	if !transition then
		-- Call item loadout function
		hook.Call("PlayerLoadout", GAMEMODE, ply)

		plytbl.PreventMossmanWeps = true
	end

	-- Set player model
	hook.Call("PlayerSetModel", GAMEMODE, ply)

	ply:SetupHands()

	ply:ShouldDropWeapon(true)

	if self.RunningMan != ply then
		ply:SetModel(mossman)
		ply:SetTeam(TEAM_GREEN)
		ply:SetPlayerColor(pmUseTeamCol:GetBool() and team.GetColor(TEAM_GREEN) or mossmanCol)

		return
	end

	ply:SetModel(runner)
	ply:SetTeam(TEAM_BLUE)
	ply:SetPlayerColor(pmUseTeamCol:GetBool() and team.GetColor(TEAM_BLUE) or runnerCol)

	if self.bWaitingRunnerRespawn then
		ply:SetHealth(999)

		net.Start("RM_RunnerHealth")
			net.WriteUInt(999, 10)
		net.Broadcast()

		self.bWaitingRunnerRespawn = false
	end
end

local n = 0
function GM:PlayerSelectSpawn(ply)
	local tbl = ents.FindByClass("*_player_*")

	if n == #tbl then
		n = 1
	else
		n = n + 1
	end

	return tbl[n]
end

-- Event overrides

function GM:PlayerConnect(name)
	net.Start("RM_Connect")
		net.WriteUInt(math.random(0, 20), 5)
		net.WriteString(name)
	net.Broadcast()
end

function GM:PlayerDisconnected(ply)
	net.Start("RM_Disconnect")
		net.WriteUInt(math.random(0, 7), 3)
	net.Broadcast()
end

function GM:DoPlayerDeath(killed, attacker, dmg)
	if !dmg:IsDamageType(DMG_REMOVENORAGDOLL) then
		killed:CreateRagdoll()
	end

	killed:AddDeaths(1)

	if attacker == self.RunningMan and attacker != killed then
		self.CurrentRunnerKills = self.CurrentRunnerKills + 1

		if self.CurrentRunnerKills > self.BestRunnerKills then
			self.BestRunnerName = " " .. attacker:Name()
			self.BestRunnerKills = self.CurrentRunnerKills
		end

		attacker:AddFrags(1)
	end

	-- The runner is dead - long live the runner!
	if killed == self.RunningMan then
		-- If they killed themselves then they lose

		-- The running man killed himself! PUNISH HIM
		if attacker == killed then
			killed:AddFrags(-5)

			self.RunningMan = nil
		elseif IsValid(attacker) and attacker:IsPlayer() then
			killed:AddDeaths(-1)
			attacker:AddFrags(1)
			self:NewRunner(attacker)
		end
	end
end

function GM:PlayerDeathThink(ply)
	if ply:Team() == TEAM_SPECTATOR then return end

	if ply.DeathTime + 5 > CurTime() then return true end

	ply:Spawn()
end

function GM:PostEntityTakeDamage(ply)
	if !ply:IsPlayer() or ply != self.RunningMan then return end

	net.Start("RM_RunnerHealth")
		net.WriteUInt(ply:Health(), 10)
	net.Broadcast()
end

local limbs = {
	[HITGROUP_LEFTARM] = true,
	[HITGROUP_RIGHTARM] = true,
	[HITGROUP_LEFTLEG] = true,
	[HITGROUP_RIGHTLEG] = true,
	[HITGROUP_GEAR] = true
}

function GM:ScalePlayerDamage(ply, hitgroup, dmg)
	if dmg:GetAttacker():Team() == ply:Team() then
		dmg:ScaleDamage(0)
		return
	end

	-- this is a very rough approximation of gm8.4 damage values
	dmg:ScaleDamage(0.65)

	-- More damage if we're shot in the head
	if hitgroup == HITGROUP_HEAD then
		dmg:ScaleDamage(2)
	elseif limbs[hitgroup] then
		-- Less damage if we're shot in the arms or legs
		dmg:ScaleDamage(0.25)
	end
end

-- Custom functions for this mode

---Set a new Running Man.
---@param ply Player
function GM:NewRunner(ply)
	if ply:Team() != TEAM_GREEN then return end

	for _, p in player.Iterator() do
		self:SetPlayerSpeed(p, 190, 330)
	end

	self:SetPlayerSpeed(ply, 500, 500)

	self.CurrentRunnerKills = 0
	self.RunningMan = ply

	local ShowBestRunner = self.BestRunnerKills > 0

	net.Start("RM_NewRunner")
		net.WriteString(ply:Name())
		net.WriteBool(ShowBestRunner)
		if ShowBestRunner then
			net.WriteString(self.BestRunnerName)
			net.WriteUInt(self.BestRunnerKills, 16)
		end
	net.Broadcast()

	ply:SetModel(runner)
	ply:SetTeam(TEAM_BLUE)

	ply:CreateRagdoll()
	local rag = ply:GetRagdollEntity()
	local num = rag:GetPhysicsObjectCount() - 1

	for i = 0, num do
		local bone = rag:GetPhysicsObjectNum(i)
		if !IsValid(bone) then continue end

		local bp, ba = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))
		if bp and ba then
			bone:SetPos(bp)
			bone:SetAngles(ba)
		end

		bone:SetVelocity(ply:GetVelocity())
	end

	ply:KillSilent()
	rag:Dissolve()

	self.bWaitingRunnerRespawn = true
end

local runningManWeps = {
	["weapon_pistol"] = true,
	["weapon_smg1"] = true,
	["weapon_crowbar"] = true
}

local disableRunnerWhitelist = CreateConVar("rm_runner_allowallweps", "0", FCVAR_ARCHIVE, "Allow the runner to pick up any weapon.", 0, 1)
local allowMossmanPickup = CreateConVar("rm_mossman_allowweppickup", "1", FCVAR_ARCHIVE, "Allow Team Mossman to pick up weapons from the ground.", 0, 1)

function GM:PlayerCanPickupWeapon(ply, wep)
	if !ply:Alive() or ply:Team() > 3 then return false end

	if ply != self.RunningMan then
		return !ply.PreventMossmanWeps or allowMossmanPickup:GetBool()
	end

	if disableRunnerWhitelist:GetBool() then return true end

	-- weapons the runner is allowed to pickup.. aka spawn with
	return runningManWeps[wep:GetClass()]
end

function GM:PlayerSwitchFlashlight()
	return true
end

local disableKillbind = CreateConVar("rm_disablekillbind", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Prevent people from killbinding or switching to spectator. This is useful to prevent kill denying.", 0, 1)
function GM:CanPlayerSuicide()
	return !disableKillbind:GetBool()
end

function GM:ShowTeam(ply)
	if disableKillbind:GetBool() then return end

	local plytbl = ply:GetTable()

	if !plytbl.PressedSpecButton or plytbl.PressedSpecButton + 5 < CurTime() then
		plytbl.PressedSpecButton = CurTime()

		net.Start("RM_Spectate")
		net.Send(ply)

		return
	end

	if ply:Team() == TEAM_SPECTATOR then
		ply:KillSilent()
		ply:SetTeam(TEAM_GREEN)
		ply:SetPlayerColor(pmUseTeamCol:GetBool() and team.GetColor(TEAM_GREEN) or mossmanCol)
		ply:Spawn()
	else
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Kill()
		ply:Spawn()
	end

	plytbl.PressedSpecButton = false
end
