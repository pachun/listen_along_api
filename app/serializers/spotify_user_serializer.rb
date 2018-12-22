class SpotifyUserSerializer < ActiveModel::Serializer
  attributes :username, :display_name, :is_me

  has_one :broadcaster

  def is_me
    @instance_options[:spotify_user_token] == object.listen_along_token
  end
end
