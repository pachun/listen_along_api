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
    SpotifyUser.active_including_myself(spotify_user_params[:token])
  end

  def authenticated?
    current_spotify_user&.id == spotify_user_params[:id].to_i
  end

  def broadcaster
    @broadcaster ||= SpotifyUser.find_by(
      username: spotify_user_params[:broadcaster_username]
    )
  end

  def current_spotify_user
    SpotifyUser.find_by(listen_along_token: spotify_user_params[:token])
  end

  def spotify_user_params
    params.permit(:id, :token, :broadcaster_username)
  end
end
