module RequestSpecHelpers
  def authenticated_spotify_user_headers(spotify_user = create(:spotify_user))
    {
      "Authorization" => "Bearer #{spotify_user.listen_along_token}"
    }
  end
end
