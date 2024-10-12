-- Modules nécessaires
local http = require("http")
local json = require("json")
local aukit = require("aukit")
local term = require("term")
local event = require("event")

-- Variables globales pour pagination
local page = 1
local songsPerPage = 5
local selectedSong = 1

-- Fonction pour récupérer la playlist depuis GitHub
local function fetchPlaylist(url)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        return json.decode(content)
    else
        error("Impossible de récupérer la playlist")
    end
end

-- Fonction pour afficher les chansons paginées
local function displaySongs(playlist)
    term.clear()
    local totalPages = math.ceil(#playlist / songsPerPage)
    local startSong = (page - 1) * songsPerPage + 1
    local endSong = math.min(page * songsPerPage, #playlist)

    print("Page " .. page .. " / " .. totalPages)
    for i = startSong, endSong do
        if i == selectedSong then
            print("-> " .. playlist[i].title .. " - " .. playlist[i].artist)
        else
            print("   " .. playlist[i].title .. " - " .. playlist[i].artist)
        end
    end
    print("\nUtilisez les flèches pour naviguer, Entrée pour jouer")
end

-- Fonction pour jouer la chanson sélectionnée
local function playSong(playlist)
    local song = playlist[selectedSong]
    print("Lecture en cours: " .. song.title .. " par " .. song.artist)
    aukit.play(aukit.stream[song.format](http.get(song.url):readAll()), peripheral.find("speaker"))
end

-- Fonction de navigation avec les flèches et Entrée
local function navigatePlaylist(playlist)
    local running = true
    while running do
        displaySongs(playlist)
        local event, key = event.pull("key")
        
        if key == keys.up then
            if selectedSong > 1 then
                selectedSong = selectedSong - 1
                if selectedSong < (page - 1) * songsPerPage + 1 then
                    page = page - 1
                end
            end
        elseif key == keys.down then
            if selectedSong < #playlist then
                selectedSong = selectedSong + 1
                if selectedSong > page * songsPerPage then
                    page = page + 1
                end
            end
        elseif key == keys.left then
            if page > 1 then
                page = page - 1
                selectedSong = (page - 1) * songsPerPage + 1
            end
        elseif key == keys.right then
            if page < math.ceil(#playlist / songsPerPage) then
                page = page + 1
                selectedSong = (page - 1) * songsPerPage + 1
            end
        elseif key == keys.enter then
            playSong(playlist)
        elseif key == keys.q then
            running = false -- Quitter
        end
    end
end

-- URL du fichier JSON de la playlist sur GitHub
local playlistUrl = "https://raw.githubusercontent.com/Dartsgame974/eee/refs/heads/main/playlist.json"

-- Récupération et navigation dans la playlist
local playlist = fetchPlaylist(playlistUrl)
navigatePlaylist(playlist)
