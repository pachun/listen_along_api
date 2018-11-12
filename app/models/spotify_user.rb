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
end
