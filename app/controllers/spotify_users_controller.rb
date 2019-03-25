class SpotifyUsersController < ApiController
  def index
    render json: spotify_users,
      spotify_user: current_spotify_user
  end

  def add_to_library
    return (head :unauthorized) unless authenticated?

    SpotifyService
      .new(current_spotify_user)
      .add_to_library(song_id: add_to_library_params[:song_id])
  end

  def listen_along
    return (head :unauthorized) unless authenticated?

    current_spotify_user.listen_to!(broadcaster)
  end

  private

  def spotify_users
    SpotifyUser.active_including_myself(listen_along_token)
  end

  def authenticated?
    current_spotify_user.present?
  end

  def broadcaster
    @broadcaster ||= SpotifyUser.find_by(
      username: listen_along_params[:broadcaster_username]
    )
  end

  def current_spotify_user
    SpotifyUser.find_by(listen_along_token: listen_along_token)
  end

  def listen_along_token
    request.headers["Authorization"]&.split&.last
  end

  def listen_along_params
    params.permit(:broadcaster_username)
  end

  def add_to_library_params
    params.permit(:song_id)
  end
end
