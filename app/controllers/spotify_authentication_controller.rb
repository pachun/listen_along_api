class SpotifyAuthenticationController < ApiController
  def index
    authenticating_user = SpotifyService.authenticate(
      using_authorization_code: code
    )

    redirect_to listen_along_index_path(
      broadcaster: broadcaster_username,
      listener_token: authenticating_user.listen_along_token,
      authenticating: true,
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
