require "rails_helper"

describe UpdatePlaybackStates do
  describe "self.update" do
    it "updates all spotify user's playbacks" do
      spotify_user = create :spotify_user,
        is_listening: true

      stub_get_playback_request(
        spotify_user,
        song_artists: ["a1", "a2"],
        album_url: "album_cover_url",
      )

      UpdatePlaybackStates.update

      spotify_user.reload

      expect(spotify_user.song_artists).to eq(["a1", "a2"])
      expect(spotify_user.song_album_cover_url).to eq("album_cover_url")
    end

    it "updates spotify user's playback state" do
      spotify_user_1 = create :spotify_user,
        is_listening: true,
        song_name: "On a Tuesday",
        song_uri: "spotify:track:1xyt3kmjrV3o9kbiAdwdXb",
        millisecond_progress_into_song: "5000"

      stub_currently_playing_request(
        access_token: spotify_user_1.access_token,
        is_playing: false,
      )

      spotify_user_2 = create :spotify_user
      beam_me_up = {
        is_listening: true,
        song_name: "Beam Me Up",
        song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
        millisecond_progress_into_song: "10000",
      }
      stub_get_playback_request(spotify_user_2, beam_me_up)

      UpdatePlaybackStates.update

      spotify_user_1.reload

      expect(spotify_user_1).not_to be_listening
      expect(spotify_user_1.song_name).to eq(nil)
      expect(spotify_user_1.song_uri).to eq(nil)
      expect(spotify_user_1.millisecond_progress_into_song).to eq(nil)

      spotify_user_2.reload

      expect(spotify_user_2).to be_listening
      expect(spotify_user_2.song_name).to eq("Beam Me Up")
      expect(spotify_user_2.song_uri).to eq("spotify:track:1S4FHBl24uLTzJ37VMBjut")
      expect(spotify_user_2.millisecond_progress_into_song).to eq("10000")
    end
  end

  def not_listening_state
    {
      is_listening: false,
      song_name: nil,
      song_uri: nil,
      millisecond_progress_into_song: nil,
    }
  end
end
