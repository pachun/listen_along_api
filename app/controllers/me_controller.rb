class MeController < ApiController
  def index
    return (head :unauthorized) unless authenticated?

    render json: { "is_listening" => is_listening }
  end

  private

  def is_listening
    current_spotify_user
      .updated_playback_state[:playback_state][:is_listening]
  end

  def authenticated?
    current_spotify_user.present?
  end

  def current_spotify_user
    SpotifyUser.find_by(listen_along_token: listen_along_token)
  end

  def listen_along_token
    request.headers["Authorization"]&.split&.last
  end
end
