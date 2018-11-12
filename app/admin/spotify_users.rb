ActiveAdmin.register SpotifyUser do
  permit_params \
    :access_token,
    :refresh_token,
    :username,
    :spotify_user_id,
    :song_name,
    :song_uri,
    :millisecond_progress_into_song,
    :is_listening,
    :broadcaster
end
