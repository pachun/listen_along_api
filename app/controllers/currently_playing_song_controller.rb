class CurrentlyPlayingSongController < ApplicationController
  def index
    render json: currently_playing_song
  end

  private

  def currently_playing_song
    @currently_playing_song ||= {
      name: song_name,
      artists: song_artists,
      song_album_cover_url: song_album_cover_url,
    }
  end

  def song_name
    if current_spotify_user.broadcaster.present?
      @song_name ||= current_spotify_user.broadcaster.song_name
    else
      @song_name ||= current_spotify_user.song_name
    end
  end

  def song_artists
    if current_spotify_user.broadcaster.present?
      @song_artists ||= current_spotify_user.broadcaster.song_artists
    else
      @song_artists ||= current_spotify_user.song_artists
    end
  end

  def song_album_cover_url
    if current_spotify_user.broadcaster.present?
      @song_album_cover_url ||= \
        current_spotify_user.broadcaster.song_album_cover_url
    else
      @song_album_cover_url ||= current_spotify_user.song_album_cover_url
    end
  end

  def current_spotify_user
    @current_spotify_user ||= SpotifyUser.find_by(
      listen_along_token: currently_playing_song_params[:token]
    )
  end

  def currently_playing_song_params
    params.permit(:token)
  end
end
