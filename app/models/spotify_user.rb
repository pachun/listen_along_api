class SpotifyUser < ApplicationRecord
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
end
