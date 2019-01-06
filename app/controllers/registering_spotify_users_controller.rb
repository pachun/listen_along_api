class RegisteringSpotifyUsersController < ApiController
  def new
    registering_spotify_user = RegisteringSpotifyUser.create(
      spotify_app: spotify_app_with_fewest_users,
      broadcaster_username: registering_user_params[:broadcaster_username],
      identifier: random_identifier,
    )
    redirect_to SpotifyService.oauth_url(
      registering_spotify_user: registering_spotify_user,
    )
  end

  private

  def random_identifier
    (0...32).map { ("a".."z").to_a[rand(26)] }.join
  end

  def registering_user_params
    params.permit(:broadcaster_username)
  end

  def spotify_app_with_fewest_users
    SpotifyApp.find(id_of_spotify_app_with_fewest_users)
  end

  def all_apps_with_zeroed_user_counts
    SpotifyApp.all.inject({}) do |previous, spotify_app|
      previous.merge(spotify_app.id => 0)
    end
  end

  def apps_with_nonzero_user_counts
    SpotifyUser
      .joins(:spotify_app)
      .group("spotify_apps.id")
      .count
  end

  def id_of_spotify_app_with_fewest_users
    all_apps_with_zeroed_user_counts
      .merge(apps_with_nonzero_user_counts)
      .minmax_by { |k, v| v }.first.first
  end
end
