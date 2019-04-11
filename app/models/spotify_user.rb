class SpotifyUser < ApplicationRecord
  DEFAULT_AVATAR_URL = "https://ubisoft-avatars.akamaized.net/454ea9c3-4b1a-4dbf-aa1b-0552fb994ce9/default_146_146.png"

  belongs_to :spotify_app

  has_many :listeners,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id,
    dependent: :destroy

  belongs_to :broadcaster,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id,
    required: false

  scope :active_including_myself, -> (listen_along_token) {
    SpotifyUser
      .where(is_listening: true)
      .or(SpotifyUser.where(listen_along_token: listen_along_token))
      .order(:display_name)
  }

  def update_playback_state
    update(SpotifyService.new(self).current_playback_state)
  end

  def listen_to!(spotify_user)
    update(broadcaster: spotify_user)
    SpotifyService.new(self).listen_along(broadcaster: spotify_user)
  end

  def stop_listening_along!
    update(
      maybe_intentionally_paused: false,
      broadcaster: nil,
    )
  end

  def listening?
    is_listening
  end

  def changed_song?
    song_uri != last_song_uri
  end

  def on_same_song_as_broadcaster?
    if broadcaster.nil?
      false
    else
      song_uri == broadcaster.song_uri
    end
  end

  def broadcaster_started_new_song?
    broadcaster&.changed_song? &&
      !on_same_song_as_broadcaster?
  end

  def resync_with_broadcaster!
    update(maybe_intentionally_paused: false)
    SpotifyService.new(self).listen_along(broadcaster: broadcaster)
  end

  def may_have_intentionally_paused?
    !is_listening &&
      !broadcaster_started_new_song? &&
      !maybe_intentionally_paused
  end

  def intentionally_paused?
    !broadcaster_started_new_song? && maybe_intentionally_paused
  end

  def started_playing_music_independently?
    !broadcaster.changed_song? &&
      !on_same_song_as_broadcaster?
  end
end
