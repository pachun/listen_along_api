require "rails_helper"

describe "current playing song" do
  describe "GET #index" do
    it "returns the name of the currently playing song" do
      spotify_client_double = instance_double(BroadcasterSpotifyClient)
      allow(BroadcasterSpotifyClient).to receive(:new)
        .and_return(spotify_client_double)
      allow(spotify_client_double).to(
        receive(:currently_playing_song).and_return({name: "Aerials"})
      )

      get "/currently_playing_song"

      expect(response.body).to eq("Aerials")

      allow(spotify_client_double).to(
        receive(:currently_playing_song).and_return({name: "Bone Dry"})
      )

      get "/currently_playing_song"

      expect(response.body).to eq("Bone Dry")
    end
  end
end
