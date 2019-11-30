class UpdateAvatars
  NOT_FOUND = 404

  def self.update
    new.update
  end

  def update
    SpotifyUser.all.each do |spotify_user|
      if Faraday.get(spotify_user.avatar_url).status == NOT_FOUND
        email_hash = Digest::MD5.hexdigest(spotify_user.email)
        avatar_url = "https://www.gravatar.com/avatar/#{email_hash}?d=robohash&size=400"
        spotify_user.update(avatar_url: avatar_url)
      end
    end
  end
end
