class SpotifyAuthenticationController < ApiController
  def index
    listener = SpotifyService.authenticate(
      using_authorization_code: code
    )

    redirect_to listen_along_index_path(
      broadcaster: broadcaster_username,
      listener: listener.username,
    )
  end

  private

  def code
    params[:code]
  end

  def broadcaster_username
    params["state"]
  end
end
