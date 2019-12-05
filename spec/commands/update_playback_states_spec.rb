require "rails_helper"

describe UpdatePlaybackStates do
  describe "self.update(listening:)" do
    context "listening is false" do
      it "updates inactive spotify user's playbacks" do
        spotify_user = create :spotify_user,
          is_listening: false

        stub_get_playback_request(
          spotify_user,
          is_listening: true,
          song_artists: ["a1", "a2"],
          album_url: "album_cover_url",
        )
        UpdatePlaybackStates.update(listening: false)

        spotify_user.reload

        expect(spotify_user.song_artists).to eq(["a1", "a2"])
        expect(spotify_user.song_album_cover_url).to eq("album_cover_url")
      end

      it "sleeps in between batch updates to avoid hitting the spotify api rate limit" do
        spotify_user = create :spotify_user,
          is_listening: false

        stub_get_playback_request(spotify_user)

        update_double = UpdatePlaybackStates.new(false)
        allow(update_double).to receive(:sleep)
        allow(UpdatePlaybackStates).to receive(:new)
          .with(false)
          .and_return(update_double)

        allow(Rails).to receive_message_chain(:env, :production?) { true }

        UpdatePlaybackStates.update(listening: false)

        expect(update_double).to have_received(:sleep).with(2)
      end
    end

    it "updates all listening spotify user's playbacks" do
      spotify_user = create :spotify_user,
        is_listening: true

      stub_get_playback_request(
        spotify_user,
        song_artists: ["a1", "a2"],
        album_url: "album_cover_url",
      )
      UpdatePlaybackStates.update(listening: true)

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

      spotify_user_2 = create :spotify_user,
        is_listening: true
      beam_me_up = {
        is_listening: true,
        song_name: "Beam Me Up",
        song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
        millisecond_progress_into_song: "10000",
      }
      stub_get_playback_request(spotify_user_2, beam_me_up)

      UpdatePlaybackStates.update(listening: true)

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

    context "a spotify user is listening to a song which has no album cover" do
      it "sets their album cover url to an empty string" do
        spotify_user = create :spotify_user,
          is_listening: true

        stub_get_playback_request(spotify_user)

        UpdatePlaybackStates.update(listening: true)

        spotify_user.reload

        expect(spotify_user.song_album_cover_url).to eq("")
      end
    end

    context "while make requests to update the listening users" do
      context "a user listened along with someone else" do
        it "does not change the user's attributes" do
          spotify_user = create :spotify_user,
            is_listening: true,
            updated_at: 5.seconds.from_now

          stub_get_playback_request(spotify_user)

          UpdatePlaybackStates.update(listening: true)

          expect(spotify_user.updated_at).to eq(spotify_user.reload.updated_at)
        end
      end
    end

    context "the spotify api rate limit is hit while updating a user" do
      it "does not make any changes to the spotify user" do
        old_broadcaster = create :spotify_user

        spotify_user = create :spotify_user,
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000",
          broadcaster: old_broadcaster

        stub_get_playback_request(old_broadcaster)
        stub_get_playback_request_with_rate_limiting(spotify_user)

        old_attributes = spotify_user.attributes

        UpdatePlaybackStates.update(listening: true)

        new_attributes = spotify_user.reload.attributes

        expect(old_attributes).to eq(new_attributes)
      end

      it "creates a SpotifyApiRateLimitHit model" do
        old_broadcaster = create :spotify_user

        spotify_app = create :spotify_app
        spotify_user = create :spotify_user,
          is_listening: true,
          song_name: "Beam Me Up",
          song_uri: "spotify:track:1S4FHBl24uLTzJ37VMBjut",
          millisecond_progress_into_song: "10000",
          broadcaster: old_broadcaster,
          spotify_app: spotify_app

        stub_get_playback_request(old_broadcaster)
        stub_get_playback_request_with_rate_limiting(spotify_user)

        time = DateTime.current

        num_prior_spotify_api_rate_limit_hits = SpotifyApiRateLimitHit.count

        travel_to(time) do
          UpdatePlaybackStates.update(listening: true)
        end

        expect(SpotifyApiRateLimitHit.count).to(
          eq(num_prior_spotify_api_rate_limit_hits + 1)
        )

        expect(SpotifyApiRateLimitHit.last).to(have_attributes(
          spotify_user: spotify_user,
          spotify_app: spotify_app,
          created_at: time.change(:usec => 0),
        ))
      end
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
