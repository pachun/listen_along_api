class ApiController < ActionController::API
  attr_reader :current_spotify_user

  private

  def authenticate_spotify_user
    @current_spotify_user = SpotifyUser.find_by(
      listen_along_token: request.headers["Authorization"]&.split(" ")&.dig(1),
    )
    head :unauthorized unless current_spotify_user.present?
  end
end
