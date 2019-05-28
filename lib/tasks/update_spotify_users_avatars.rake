desc "Update Spotify Users Avatars"

# :nocov:
task :update_spotify_users_avatars => :environment do
  SpotifyUser.where(email: nil, avatar_url: "https://ubisoft-avatars.akamaized.net/454ea9c3-4b1a-4dbf-aa1b-0552fb994ce9/default_146_146.png").each do |spotify_user|
    hash = Digest::MD5.hexdigest(spotify_user.username)
    avatar_url = "https://www.gravatar.com/avatar/#{hash}?d=robohash&size=400"
    spotify_user.update(
      avatar_url: avatar_url,
    )
  end
end
# :nocov:
