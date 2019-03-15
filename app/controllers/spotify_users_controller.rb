class SpotifyUsersController < ApiController
  def index
    render json: spotify_users,
      spotify_user: current_spotify_user
  end

  def update
    if authenticated?
      current_spotify_user.listen_to!(broadcaster)
    else
      head :unauthorized
    end
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
      username: spotify_user_params[:broadcaster_username]
    )
  end

  def current_spotify_user
    SpotifyUser.find_by(listen_along_token: listen_along_token)
  end

  def listen_along_token
    request.headers["Authorization"]&.split&.last
  end

  def spotify_user_params
    params.permit(:id, :broadcaster_username)
  end
end
