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
  end
end
