if Rails.env.development?
  AdminUser.create!(
    email: 'nick@pachulski.me',
    password: 'password',
    password_confirmation: 'password',
  )

  zone_16_spotify_app = SpotifyApp.create!(
    name: "Zone 16",
    client_identifier: ENV['ZONE_16_CLIENT_ID'],
    client_secret: ENV['ZONE_16_CLIENT_SECRET'],
  )

  SpotifyUser.create(
    username: "listen-with-dude",
    display_name: "listen-with-dude",
    listen_along_token: (0...32).map { ('a'..'z').to_a[rand(26)] }.join,
    access_token: ENV['LISTEN_WITH_DUDE_ZONE_16_ACCESS_TOKEN'],
    refresh_token: ENV['LISTEN_WITH_DUDE_ZONE_16_REFRESH_TOKEN'],
    spotify_app: zone_16_spotify_app,
  )
end
