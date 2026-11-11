--!strict
-- Database Playlist Musik Terkategori (Indonesia, Jawa, English)
-- Masing-masing lagu dilengkapi 'PlaybackSpeed' untuk mengembalikan tempo asli (anti-kecepatan)
export type Song = {
	Id: number,
	Title: string,
	Artist: string,
	PlaybackSpeed: number,
	Image: string,
}

export type Category = {
	Key: string,
	Name: string,
	Icon: string,
	Color: Color3,
	Songs: { Song },
}

local MusicData = {
	Categories = {
		Indo = {
			Key = "Indo",
			Name = "Indonesia",
			Icon = "rbxassetid://99264910429345",
			Color = Color3.fromRGB(240, 70, 70),
			Songs = {
				{
					Id = 117951442449964,
					Title = "Komang",
					Artist = "Raim Laode",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://99264910429345",
				},
				{
					Id = 85686035692407,
					Title = "Sial",
					Artist = "Mahalini",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://99264910429345",
				},
				{
					Id = 96947129986366,
					Title = "Jiwa Yang Bersedih",
					Artist = "Ghea Indrawari",
					PlaybackSpeed = 0.90,
					Image = "rbxassetid://99264910429345",
				},
				{
					Id = 112085364811737,
					Title = "Rayuan Perempuan Gila",
					Artist = "Nadin Amizah",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://99264910429345",
				},
			},
		},
		Jawa = {
			Key = "Jawa",
			Name = "Jawa",
			Icon = "rbxassetid://75682744013094",
			Color = Color3.fromRGB(255, 175, 40),
			Songs = {
				{
					Id = 101860925564465,
					Title = "Nemen",
					Artist = "GildCoustic",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://75682744013094",
				},
				{
					Id = 129368751478039,
					Title = "Dumes",
					Artist = "Wawes ft. Guyon Waton",
					PlaybackSpeed = 0.90,
					Image = "rbxassetid://75682744013094",
				},
				{
					Id = 136567923838513,
					Title = "Sanes",
					Artist = "Guyon Waton",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://75682744013094",
				},
				{
					Id = 108999272882786,
					Title = "Kisinan",
					Artist = "Masdddho",
					PlaybackSpeed = 0.88,
					Image = "rbxassetid://75682744013094",
				},
			},
		},
		Inggris = {
			Key = "Inggris",
			Name = "English",
			Icon = "rbxassetid://98116895292866",
			Color = Color3.fromRGB(80, 160, 255),
			Songs = {
				{
					Id = 107077267639492,
					Title = "Golden Hour",
					Artist = "JVKE",
					PlaybackSpeed = 0.95,
					Image = "rbxassetid://98116895292866",
				},
				{
					Id = 108744370394813,
					Title = "Until I Found You",
					Artist = "Stephen Sanchez",
					PlaybackSpeed = 0.92,
					Image = "rbxassetid://98116895292866",
				},
				{
					Id = 136423797762727,
					Title = "Night Changes",
					Artist = "One Direction",
					PlaybackSpeed = 0.90,
					Image = "rbxassetid://98116895292866",
				},
			},
		},
	},
	-- Order of category display
	CategoryOrder = { "Indo", "Jawa", "Inggris" },
}

return MusicData
