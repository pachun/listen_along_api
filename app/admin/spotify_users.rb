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
    :avatar_url

  index do
    actions
    id_column
    column :display_name
    column :broadcaster
    column :song_name
    column :millisecond_progress_into_song
    column :is_listening
    column :username
  end

  form do |f|
    f.semantic_errors
    f.inputs
    f.actions
  end
end
