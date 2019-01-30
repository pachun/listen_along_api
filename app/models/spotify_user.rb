class SpotifyUser < ApplicationRecord
  DEFAULT_AVATAR_URL = "https://ubisoft-avatars.akamaized.net/454ea9c3-4b1a-4dbf-aa1b-0552fb994ce9/default_146_146.png"

  belongs_to :spotify_app

  has_many :listeners,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id

  belongs_to :broadcaster,
    class_name: "SpotifyUser",
    foreign_key: :spotify_user_id,
    required: false

  def time_spent_listening_to(spotify_user)
    ListenAlongDetails.find_by(
      listener: self,
      broadcaster: spotify_user,
    ).duration
  end

  def listen_to!(spotify_user)
    update(broadcaster: spotify_user)
    SpotifyService.new(self).listen_along(broadcaster: spotify_user)
    ListenAlongDetails.find_or_create_by(
      listener: self,
      broadcaster: spotify_user,
    ).update(
      listen_along_start_time: Time.now,
    )
  end

  def stop_listening_along!
    details = listen_along_details

    details.update(
      duration: (
        (Time.now - details.listen_along_start_time) \
        + details.duration
    ))
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

  private

  def listen_along_details(spotify_user = broadcaster)
    ListenAlongDetails.find_by(
      listener: self,
      broadcaster: spotify_user,
    )
  end
end
