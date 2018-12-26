require "rails_helper"

describe ListenersController do
  describe "GET #index" do
    it "returns the currently playing song" do
      me = create :spotify_user,
        listen_along_token: "my_token",
        song_name: "Sleep Alone",
        song_artists: ["Quinn", "Phoebe"],
        song_album_cover_url: "album_cover"

      get "/currently_playing_song?token=my_token"

      song_json = JSON.parse(response.body)
      album_cover = song_json["song_album_cover_url"]
      song_name = song_json["name"]
      song_artists = song_json["artists"]

      expect(album_cover).to eq("album_cover")
      expect(song_name).to eq("Sleep Alone")
      expect(song_artists).to eq(["Quinn", "Phoebe"])

      me.update(
        song_album_cover_url: "another_album_cover",
        song_name: "You're Free",
        song_artists: ["Florida Georgia Line"],
      )

      get "/currently_playing_song?token=my_token"

      song_json = JSON.parse(response.body)
      album_cover = song_json["song_album_cover_url"]
      song_name = song_json["name"]
      song_artists = song_json["artists"]

      expect(album_cover).to eq("another_album_cover")
      expect(song_name).to eq("You're Free")
      expect(song_artists).to eq(["Florida Georgia Line"])
    end

    context "the listener has a broadcaster" do
      it "shows the broadcaster's song information" do
        broadcaster = create :spotify_user,
          song_name: "September",
          song_artists: ["Campsite Dream"],
          song_album_cover_url: "https://i.scdn.co/image/0259cd214a691eeff6d05607f1a9127b9cae8c21"

        create :spotify_user,
          broadcaster: broadcaster,
          listen_along_token: "my_token"

        get "/currently_playing_song?token=my_token"

        song_json = JSON.parse(response.body)

        album_cover = song_json["song_album_cover_url"]
        song_name = song_json["name"]
        song_artists = song_json["artists"]

        expect(album_cover).to eq("https://i.scdn.co/image/0259cd214a691eeff6d05607f1a9127b9cae8c21")
        expect(song_name).to eq("September")
        expect(song_artists).to eq(["Campsite Dream"])
      end
    end
  end
end
