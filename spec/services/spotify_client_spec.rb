require "rails_helper"

describe SpotifyClient do
  describe "#currently_playing_song_name" do
    context "the song 'Bone Dry' is playing" do
      context "the spotify access token has expired" do
        it "gets a new access token then returns the song name" do
          spotify_credentials = create :spotify_credential,
            access_token: "expired access token",
            refresh_token: "refresh token"

          VCR.use_cassette(
            "Expired Spotify Access Token While Listening To Bone Dry",
            match_requests_on: [:method, :uri, :headers, :body]
          ) do

            @song_name = SpotifyClient.new.currently_playing_song_name
          end

          expect(
            spotify_credentials.reload.access_token
          ).to eq("refreshed access token")
          expect(@song_name).to eq("Bone Dry")
        end
      end

      it "returns 'Bone Dry'" do
        create :spotify_credential,
          access_token: "bone_dry_access_token"

        VCR.use_cassette(
          "Bone Dry",
          match_requests_on: [:method, :uri, :headers, :body]
        ) do
          expect(
            SpotifyClient.new.currently_playing_song_name
          ).to eq("Bone Dry")
        end
      end
    end

    context "the song 'Aerials' is playing" do
      it "returns 'Aerials'" do
        create :spotify_credential,
          access_token: "aerials_access_token"

        VCR.use_cassette(
          "Aerials",
          match_requests_on: [:method, :uri, :headers, :body]
        ) do
          expect(
            SpotifyClient.new.currently_playing_song_name
          ).to eq("Aerials")
        end
      end
    end

    context "there is no song playing" do
      it "returns 'No Song Playing'" do
        create :spotify_credential,
          access_token: "no_song_playing_access_token"

        VCR.use_cassette(
          "No Song Playing",
          match_requests_on: [:method, :uri, :headers, :body],
        ) do
          @song_name = SpotifyClient.new.currently_playing_song_name
        end

        expect(@song_name).to eq("No Song Playing")
      end
    end
  end
end
