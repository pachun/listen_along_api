desc "Update Spotify Users Personal Information"

# :nocov:
task :update_spotify_users_personal_information => :environment do
  SpotifyUser.all.each do |spotify_user|

    url = SpotifyService::SPOTIFY_API_URL + SpotifyService::SPOTIFY_USERNAME_ENDPOINT
    spotify_response = Faraday.get(url) do |req|
      req.headers["Authorization"] = "Bearer #{spotify_user.access_token}"
    end

    email = JSON.parse(spotify_response.body)["email"]
    spotify_user.update(email: email)

    if spotify_user.avatar_url === "https://ubisoft-avatars.akamaized.net/454ea9c3-4b1a-4dbf-aa1b-0552fb994ce9/default_146_146.png" && email.present?
      hash = Digest::MD5.hexdigest(email)
      avatar_url = "https://www.gravatar.com/avatar/#{hash}?d=robohash&size=400"

      spotify_user.update(
        avatar_url: avatar_url,
      )
    end
  end
end
# :nocov:
