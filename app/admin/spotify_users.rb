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
    :spotify_app

  index do
    actions
    id_column
    column :has_access_token do |spotify_user|
      spotify_user.access_token != nil
    end
    column :display_name
    column :broadcaster
    column :song_name
    column :millisecond_progress_into_song
    column :is_listening
    column :username
    column :spotify_app
  end

  form do |f|
    f.semantic_errors
    f.inputs
    f.actions
  end
end
