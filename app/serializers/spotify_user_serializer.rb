class SpotifyUserSerializer < ActiveModel::Serializer
  attributes :username,
    :display_name,
    :is_me,
    :avatar_url,
    :number_of_listeners,
    :listening_along

  def is_me
    @instance_options[:spotify_user]&.listen_along_token == \
      object.listen_along_token
  end

  def listening_along
    @instance_options[:spotify_user]&.broadcaster&.username == object.username
  end
end
