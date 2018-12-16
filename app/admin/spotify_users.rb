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

  index do
    actions
    id_column
    column :username
    column :broadcaster
    column :song_name
    column :millisecond_progress_into_song
    column :is_listening
  end
end
