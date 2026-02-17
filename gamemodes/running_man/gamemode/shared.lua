GM.Name = "Running Man"
GM.Author = "Garry Newman"
GM.Email = ""
GM.Website = "garry.tv"

TEAM_BLUE = 1
TEAM_GREEN = 2

function GM:CreateTeams()
	team.SetUp(TEAM_BLUE, "#RunningMan.RunningMan", Color(192, 241, 255))
	team.SetUp(TEAM_GREEN, "#RunningMan.TeamMossman", Color(172, 255, 172))
end

local sv_cheats = GetConVar("sv_cheats")
function GM:PlayerNoClip()
	return sv_cheats:GetBool()
end