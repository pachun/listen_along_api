require "rails_helper"

describe SpotifyUser do
  describe "#update_playback_state" do
    it "updates playback state" do
      spotify_user_1 = create :spotify_user
      allow(spotify_user_1).to receive(:update)

      expected_playback_state_1 = { playback: :state_1 }
      spotify_service_double_1 = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(spotify_user_1)
        .and_return(spotify_service_double_1)
      allow(spotify_service_double_1).to(
        receive(:current_playback_state).and_return(expected_playback_state_1)
      )

      spotify_user_1.update_playback_state

      expect(spotify_user_1).to have_received(:update).with(expected_playback_state_1)

      spotify_user_2 = create :spotify_user
      allow(spotify_user_2).to receive(:update)

      expected_playback_state_2 = { playback: :state_2 }
      spotify_service_double_2 = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(spotify_user_2)
        .and_return(spotify_service_double_2)
      allow(spotify_service_double_2).to(
        receive(:current_playback_state).and_return(expected_playback_state_2)
      )

      spotify_user_2.update_playback_state

      expect(spotify_user_2).to have_received(:update).with(expected_playback_state_2)
    end
  end

  describe "#listen_to!(broadcaster)" do
    it "syncs with and begins listening to the broadcasters playback" do
      listener = create :spotify_user
      broadcaster = create :spotify_user

      spotify_service_double = instance_double(SpotifyService)
      allow(SpotifyService).to receive(:new)
        .with(listener)
        .and_return(spotify_service_double)
      allow(spotify_service_double).to receive(:listen_along)

      listener.listen_to!(broadcaster)

      expect(spotify_service_double).to have_received(:listen_along)
        .with(broadcaster: broadcaster)
    end

    it "sets the listeners broadcaster" do
      stub_spotify_service_listen_alongs

      listener = create :spotify_user
      broadcaster = create :spotify_user

      listener.listen_to!(broadcaster)

      listener.reload

      expect(listener.broadcaster).to eq(broadcaster)
    end
  end

  describe "#stop_listening_along!" do
    it "turns off repeat on the listeners devices" do
      broadcaster = create :spotify_user
      listener = create :spotify_user

      spotify_service_double = instance_double(SpotifyService)
      allow(spotify_service_double).to receive(:turn_off_repeat)
      allow(SpotifyService).to receive(:new)
        .with(listener)
        .and_return(spotify_service_double)

      allow(spotify_service_double).to receive(:listen_along)
      listener.listen_to!(broadcaster)

      listener.stop_listening_along!

      expect(spotify_service_double).to have_received(:turn_off_repeat)

      expect(2 + 2).to eq(4)
    end

    it "stops listening along" do
      broadcaster = create :spotify_user,
        maybe_intentionally_paused: true
      spotify_user = create :spotify_user,
        broadcaster: broadcaster
      stub_spotify_service_listen_alongs
      spotify_user.listen_to!(broadcaster)

      spotify_user.stop_listening_along!

      spotify_user.reload

      expect(spotify_user.broadcaster).to eq(nil)
      expect(spotify_user.maybe_intentionally_paused).to eq(false)
    end
  end

  describe "#started_playing_music_independently?" do
    context "when the spotify user started playing music independently" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          song_uri: "another uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(true)
      end
    end

    context "when the spotify user is listening to the same song as their broadcaster" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          song_uri: "uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(false)
      end
    end

    context "when the spotify user's broadcaster changed their song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          song_uri: "different uri",
          broadcaster: broadcaster

        expect(spotify_user.started_playing_music_independently?).to eq(false)
      end
    end
  end

  describe "#intentionally_paused?" do
    context "when the user intentionally paused their music" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(true)
      end
    end

    context "when the spotify users .maybe_intentionally_paused flag is false" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(false)
      end
    end

    context "when the broadcaster has started a new song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.intentionally_paused?).to eq(false)
      end
    end
  end

  describe "#may_have_intentionally_paused?" do
    context "when the listener may have intentionally paused" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "same uri",
          song_uri: "same uri"
        spotify_user = create :spotify_user,
          is_listening: false,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster

        expect(spotify_user.may_have_intentionally_paused?).to eq(true)
      end
    end

    context "when the spotify user is listening to music" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "same uri",
          song_uri: "same uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: false,
          broadcaster: broadcaster,
          is_listening: true

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end
    context "when the listener's broadcaster has started a new song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "another uri"
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true,
          broadcaster: broadcaster

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end

    context "when .maybe_intentionally_paused is already set to true" do
      it "returns false" do
        spotify_user = create :spotify_user,
          maybe_intentionally_paused: true

        expect(spotify_user.may_have_intentionally_paused?).to eq(false)
      end
    end
  end
  describe "#resync_with_broadcaster!" do
    it "resyncs the listener with their broadcaster" do
      broadcaster = create :spotify_user
      spotify_user = create :spotify_user,
        broadcaster: broadcaster

      spotify_service_double = instance_double(SpotifyService)
      allow(spotify_service_double).to receive(:listen_along)
      allow(SpotifyService).to receive(:new).with(spotify_user)
        .and_return(spotify_service_double)

      spotify_user.resync_with_broadcaster!

      expect(spotify_service_double).to have_received(:listen_along)
        .with(broadcaster: broadcaster)
    end

    it "resets .maybe_intentionally_paused to false" do
      spotify_user = create :spotify_user,
        maybe_intentionally_paused: true

      spotify_service_double = instance_double(SpotifyService)
      allow(spotify_service_double).to receive(:listen_along)
      allow(SpotifyService).to(
        receive(:new).and_return(spotify_service_double)
      )

      spotify_user.resync_with_broadcaster!

      expect(spotify_user.reload.maybe_intentionally_paused).to eq(false)
    end
  end

  describe "#broadcaster_started_new_song?" do
    context "when no broadcaster exists" do
      it "returns nil" do
        spotify_user = create :spotify_user

        expect(spotify_user.broadcaster_started_new_song?).to eq(nil)
      end
    end

    context "when the broadcasters song did not change" do
      it "returns false" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri",
          song_uri: "uri"

        spotify_user = create :spotify_user,
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(false)
      end
    end

    context "when the listener is on the same song" do
      it "returns false" do
        broadcaster = create :spotify_user,
          song_uri: "uri"

        spotify_user = create :spotify_user,
          song_uri: "uri",
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(false)
      end
    end

    context "when the broadcasters song has changed" do
      it "returns true" do
        broadcaster = create :spotify_user,
          last_song_uri: "uri1",
          song_uri: "uri2"

        spotify_user = create :spotify_user,
          song_uri: "not uri2",
          broadcaster: broadcaster

        expect(spotify_user.broadcaster_started_new_song?).to eq(true)
      end
    end
  end

  describe "#changed_song?" do
    context "the spotify user is listening to a different song" do
      it "returns true" do
        spotify_user = create :spotify_user,
          last_song_uri: "last song uri",
          song_uri: "current song uri"

        expect(spotify_user.changed_song?).to eq(true)
      end
    end

    context "the spotify user is listening to the same song" do
      it "returns false" do
        the_same_uri = "the same uri"
        spotify_user = create :spotify_user,
          last_song_uri: the_same_uri,
          song_uri: the_same_uri

        expect(spotify_user.changed_song?).to eq(false)
      end
    end
  end

  describe "#on_same_song_as_broadcaster?" do
    context "the spotify user has a broadcaster" do
      context "the spotify user is not listening to the same song as their broadcaster" do
        it "returns false" do
          broadcaster = create :spotify_user,
            song_uri: "a great song"
          listener = create :spotify_user,
            song_uri: "a poor song",
            broadcaster: broadcaster

          expect(listener.on_same_song_as_broadcaster?).to be(false)
        end
      end

      context "the spotify user is listening to the same song as their broadcaster" do
        it "returns true" do
          the_same_uri = "the same uri"
          broadcaster = create :spotify_user,
            song_uri: the_same_uri
          listener = create :spotify_user,
            song_uri: the_same_uri,
            broadcaster: broadcaster

          expect(listener.on_same_song_as_broadcaster?).to be(true)
        end
      end
    end

    context "the spotify user does not have a broadcaster" do
      it "returns false" do
        listener = create :spotify_user

        expect(listener.on_same_song_as_broadcaster?).to be(false)
      end
    end
  end
end
