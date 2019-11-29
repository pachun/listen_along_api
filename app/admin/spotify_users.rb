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
    :broadcaster,
    :display_name,
    :avatar_url,
    :listen_along_token,
    :spotify_app_id

  index do
    id_column
    column :username
    column :is_listening
    column :broadcaster
    column :song_name
    column :last_listen_along_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs
    f.actions
  end
end
