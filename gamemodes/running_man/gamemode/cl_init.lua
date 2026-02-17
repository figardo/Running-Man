include("shared.lua")
include("drawarc.lua")
include("cl_scoreboard.lua")

surface.CreateFont("ScreenText", {
	font = "Trebuchet MS",
	size = ScreenScaleH(18),
	weight = 700,
	additive = true
})

surface.CreateFont("CenterMessage", {
	font = "Trebuchet MS",
	size = ScreenScaleH(8),
	weight = 650,
	antialias = false
})

surface.CreateFont("LegacyDefault", {
	font = "Verdana",
	size = ScreenScaleH(8),
	weight = 700,
	antialias = true,
	extended = true
})

surface.CreateFont("LegacyDefaultThin", {
	font = "Verdana",
	size = ScreenScaleH(8),
	weight = 500,
	antialias = true,
	extended = true
})

local unsupported = {
	["bg"] = "Не се поддържа български език. Допринесете тук:",
	["cs"] = "Čeština není podporována. Přispějte zde:",
	["el"] = "Η ελληνική γλώσσα δεν υποστηρίζεται. Συμβάλετε εδώ:",
	["en-pt"] = "YARRRGH! This ship be docked fer now matey! Help us steer her here:",
	["et"] = "Eesti keel toetamata. Anna oma panus siin:",
	["fi"] = "Suomen kieltä ei tueta. Osallistu täällä:",
	-- ["fr"] = "La langue française n'est pas prise en charge. Contribuez ici :",
	["he"] = "אין תמיכה בשפה העברית. תרמו כאן:",
	["hr"] = "Hrvatski jezik nije podržan. Doprinesite ovdje:",
	["hu"] = "A magyar nyelv nem támogatott. Hozzászólás itt:",
	["it"] = "La lingua italiana non è supportata. Contribuisci qui:",
	["ja"] = "日本語は非対応です。 ここに貢献してください:",
	["ko"] = "한국어는 지원하지 않습니다. 여기에 기여하세요:",
	["lt"] = "lietuvių kalba nepalaikoma. Prisidėkite čia:",
	["nl"] = "Nederlandse taal niet ondersteund. Draag hier bij:",
	["no"] = "Norsk språk støttes ikke. Bidra her:",
	["pt-pt"] = "Língua portuguesa europeia não suportada. Contribua aqui:",
	["sk"] = "Slovenský jazyk nie je podporovaný. Prispejte sem:",
	-- ["sv-se"] = "Svenska språket stöds inte. Bidra här:",
	-- ["tr"] = "Türkçe dil desteklenmiyor. Buraya katkıda bulunun:",
	-- ["uk"] = "Українська мова не підтримується. Зробіть свій внесок тут:",
	["vi"] = "Ngôn ngữ tiếng Việt không được hỗ trợ. Đóng góp tại đây:",
	-- ["zh-cn"] = "不支持中文（简体）语言。 在这里贡献：",
	-- ["zh-tw"] = "不支持中文（繁體）語言。 在這裡貢獻："
}

function GM:InitPostEntity()
	local lang = GetConVar("gmod_language"):GetString():lower()
	if !unsupported[lang] then return end

	local ply = LocalPlayer()

	ply:ChatPrint("Selected language is unsupported. Contribute here: https://crowdin.com/project/gmod9")
	ply:ChatPrint(unsupported[lang] .. " https://crowdin.com/project/gmod9")
end

local boxCol = Color(0, 0, 0, 102)

function GM:HUDPaint()
	local scrw, scrh = ScrW(), ScrH()

	local plyTeam = LocalPlayer():Team()
	local teamStr = team.GetName(plyTeam)
	local teamColour = team.GetColor(plyTeam)

	local x1, y1 = scrw * 0.01875, scrh * 0.86458

	surface.SetFont("LegacyDefault")
	local textX, textY = surface.GetTextSize(teamStr)

	local x2, y2 = textX + (scrw * 0.0195), scrh * 0.03263

	draw.RoundedBox(8, x1, y1, x2, y2, boxCol)

	surface.SetTextPos(x1 + (x2 / 2) - (textX / 2), y1 + ((y2 / 2) - (textY / 2)))
	surface.SetTextColor(teamColour)
	surface.DrawText(teamStr)

	hook.Run( "HUDDrawTargetID" )
	hook.Run( "HUDDrawPickupHistory" )
	hook.Run( "DrawDeathNotice", 0.85, 0.04 )
end

local ef2delay = 1 / 20
local function Effect2(pnl)
	if !pnl.LastChar then
		pnl.LastChar = ef2delay
		pnl.FullText = pnl:GetText()
		pnl.TextIndex = 0
		pnl:SetText("")
	end

	if pnl.LastChar > 0 then
		pnl.LastChar = pnl.LastChar - RealFrameTime()

		return
	end

	pnl.TextIndex = pnl.TextIndex + 1
	pnl:SetText(pnl.FullText:sub(1, pnl.TextIndex))

	if pnl.TextIndex >= pnl.FullText:len() then
		pnl.Think = nil

		return
	end

	pnl.LastChar = ef2delay
end

local function FadeInOut(pnl, fadein, holdtime, fadeout)
	pnl:AlphaTo(255, fadein, 0, function(_, s) s:AlphaTo(0, fadeout, holdtime, function(_, s2) s2:Remove() end) end)
end

local newRunnerCol = Color(255, 100, 0)
local bestRunnerCol = Color(100, 200, 255)

local function NewRunner()
	local scrw, scrh = ScrW(), ScrH()

	surface.SetFont("ScreenText")
	local txt = string.format(language.GetPhrase("RunningMan.NewRunner"), net.ReadString())
	local tx = surface.GetTextSize(txt)

	local pnl = vgui.Create("DLabel")
	pnl:SetAlpha(0)
	FadeInOut(pnl, 1, 6, 3)
	pnl:SetFont("ScreenText")
	pnl:SetText(txt)
	pnl:SetTextColor(newRunnerCol)
	pnl:SizeToContents()
	pnl:SetPos((scrw / 2) - (tx / 2), scrh * 0.2)

	if net.ReadBool() then
		txt = string.format(language.GetPhrase("RunningMan.BestRunner"), net.ReadString(), net.ReadUInt(16))
		tx = surface.GetTextSize(txt)

		pnl = vgui.Create("DLabel")
		pnl:SetAlpha(0)
		FadeInOut(pnl, 0.05, 10, 5)
		pnl:SetFont("ScreenText")
		pnl:SetText(txt)
		pnl:SetTextColor(bestRunnerCol)
		pnl:SizeToContents()
		pnl:SetPos((scrw / 2) - (tx / 2), scrh * 0.3)
		pnl.Think = Effect2
	end
end
net.Receive("RM_NewRunner", NewRunner)

local msgPnl
local function PrintMessageAll(txt)
	surface.SetFont("CenterMessage")
	local tx = surface.GetTextSize(txt)

	if IsValid(msgPnl) then
		msgPnl:Remove()
	end

	msgPnl = vgui.Create("DLabel")
	msgPnl:SetFont("CenterMessage")
	msgPnl:SetText(txt)
	msgPnl:SetTextColor()
	msgPnl:SizeToContents()
	msgPnl:SetPos((ScrW() / 2) - (tx / 2), ScrH() * 0.341)
	msgPnl.Lifespan = 5
	msgPnl.Think = function(s)
		if s.Lifespan <= 0 then
			s:Remove()

			return
		end

		s.Lifespan = s.Lifespan - RealFrameTime()
	end
end

local RunnersOldHealth = 0

local healthPnl
local function RunnerHealth()
	local scrw, scrh = ScrW(), ScrH()

	local newhealth = net.ReadUInt(10)

	if newhealth != 999 then
		if !IsValid(healthPnl) then
			healthPnl = vgui.Create("DLabel")
			healthPnl:SetAlpha(0)
			FadeInOut(healthPnl, 0.1, 10, 5)
			healthPnl:SetFont("ScreenText")
			healthPnl:SetText(string.format(language.GetPhrase("RunningMan.RunnerHealth"), newhealth))
			healthPnl:SetTextColor(bestRunnerCol)
			healthPnl:SizeToContents()
			healthPnl:SetPos(scrw * 0.02, scrh * 0.8)
			healthPnl.Think = Effect2
		elseif healthPnl.Think then
			healthPnl.FullText = string.format(language.GetPhrase("RunningMan.RunnerHealth"), newhealth)
		else
			healthPnl:SetText(string.format(language.GetPhrase("RunningMan.RunnerHealth"), newhealth))
		end

		if newhealth < 800 and RunnersOldHealth >= 800 then
			PrintMessageAll(string.format(language.GetPhrase("RunningMan.Health800"), newhealth))
		elseif newhealth < 500 and RunnersOldHealth >= 500 then
			PrintMessageAll(string.format(language.GetPhrase("RunningMan.Health500"), newhealth))
		elseif newhealth < 200 and RunnersOldHealth >= 200 then
			PrintMessageAll(string.format(language.GetPhrase("RunningMan.Health200"), newhealth))
		elseif newhealth < 100 and RunnersOldHealth >= 100 then
			PrintMessageAll(string.format(language.GetPhrase("RunningMan.Health100"), newhealth))
		end
	end

	RunnersOldHealth = newhealth
end
net.Receive("RM_RunnerHealth", RunnerHealth)

local circleMat = Material("SGM/playercircle")
local circleSize = 48
function GM:PostDrawOpaqueRenderables() -- Team circles for everyone!
	for _, ply in player.Iterator() do
		local tid = ply:Team()
		if ply:IsDormant() or !ply:Alive() or tid == TEAM_SPECTATOR then continue end

		local pos = ply:GetPos()
		local tcol = team.GetColor(tid)
		tcol.a = 150

		render.SetMaterial(circleMat)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), circleSize, circleSize, tcol)
	end
end

local function OnConnect()
	surface.PlaySound("vo/npc/female01/question" .. net.ReadUInt(5) + 10 .. ".wav")

	PrintMessageAll(string.format(language.GetPhrase("RunningMan.Join"), net.ReadString()))
end
net.Receive("RM_Connect", OnConnect)

local function OnDisconnect()
	surface.PlaySound( "vo/npc/male01/gordead_ques" .. net.ReadUInt(3) + 10 .. ".wav" )
end
net.Receive("RM_Disconnect", OnDisconnect)

local disableKillbind = CreateConVar("rm_disablekillbind", "0", FCVAR_REPLICATED)
local function Spectate()
	if disableKillbind:GetBool() then return end

	if LocalPlayer():Team() == TEAM_SPECTATOR then
		chat.AddText("Press F2 again to join a team.")
	else
		chat.AddText("Press F2 again to join spectator.")
	end
end
net.Receive("RM_Spectate", Spectate)