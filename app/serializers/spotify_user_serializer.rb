class SpotifyUserSerializer < ActiveModel::Serializer
  attributes :username, :display_name, :broadcaster, :is_me

  def broadcaster
    object.broadcaster&.username
  end

  def is_me
    @instance_options[:spotify_user_token] == object.listen_along_token
  end
end
