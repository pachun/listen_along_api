class SpotifyUser < ApplicationRecord
  DEFAULT_AVATAR_URL = "https://ubisoft-avatars.akamaized.net/454ea9c3-4b1a-4dbf-aa1b-0552fb994ce9/default_146_146.png"

  has_many :listeners,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id

  belongs_to :broadcaster,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id,
    required: false

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

  def number_of_listeners
    SpotifyUser.where(broadcaster: self).count
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
    !is_listening && !broadcaster_started_new_song? && !maybe_intentionally_paused
  end

  def intentionally_paused?
    !broadcaster_started_new_song? && maybe_intentionally_paused
  end

  def started_playing_music_independently?
    !broadcaster.changed_song? &&
      !on_same_song_as_broadcaster?
  end

  def stop_listening_along!
    update(
      maybe_intentionally_paused: false,
      broadcaster: nil,
    )
  end
end
