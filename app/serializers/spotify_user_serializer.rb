class SpotifyUserSerializer < ActiveModel::Serializer
  attributes :username,
    :id,
    :is_listening,
    :display_name,
    :is_me,
    :avatar_url,
    :song_name,
    :song_artists,
    :song_album_cover_url

  has_one :broadcaster

  def is_me
    @instance_options[:spotify_user]&.listen_along_token == \
      object.listen_along_token
  end
end
