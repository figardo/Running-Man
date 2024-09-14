GM.Name = "Running Man"
GM.Author = "Garry Newman"
GM.Email = ""
GM.Website = "garry.tv"

TEAM_BLUE = 1
TEAM_GREEN = 2

local unsupported = {
	["bg"] = "Не се поддържа български език. Допринесете тук:",
	["cs"] = "Čeština není podporována. Přispějte zde:",
	["el"] = "Η ελληνική γλώσσα δεν υποστηρίζεται. Συμβάλετε εδώ:",
	["en-pt"] = "YARRRGH! This ship be docked fer now matey! Help us steer her here:",
	["et"] = "Eesti keel toetamata. Anna oma panus siin:",
	["fi"] = "Suomen kieltä ei tueta. Osallistu täällä:",
	["fr"] = "La langue française n'est pas prise en charge. Contribuez ici :",
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
	["uk"] = "Українська мова не підтримується. Зробіть свій внесок тут:",
	["vi"] = "Ngôn ngữ tiếng Việt không được hỗ trợ. Đóng góp tại đây:",
	-- ["zh-cn"] = "不支持中文（简体）语言。 在这里贡献：",
	["zh-tw"] = "不支持中文（繁體）語言。 在這裡貢獻："
}

function GM:InitPostEntity()
	team.SetUp(TEAM_BLUE, "#RunningMan.RunningMan", Color(192, 241, 255))
	team.SetUp(TEAM_GREEN, "#RunningMan.TeamMossman", Color(172, 255, 172))

	if CLIENT then
		local lang = GetConVar("gmod_language"):GetString():lower()
		if !unsupported[lang] then return end

		local ply = LocalPlayer()

		ply:ChatPrint("Selected language is unsupported. Contribute here: https://crowdin.com/project/gmod9")
		ply:ChatPrint(unsupported[lang] .. " https://crowdin.com/project/gmod9")
	end
end

function GM:PlayerNoClip()
	return GetConVar("sv_cheats"):GetBool()
end