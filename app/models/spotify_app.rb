class SpotifyApp < ApplicationRecord
  has_many :spotify_users

  scope :with_most_spotify_users, -> () {
    joins(:spotify_users)
      .select("spotify_apps.*, count(spotify_users.id) as users_count")
      .group("spotify_apps.id") .order("users_count DESC")
      .limit(1)
      .first
  }

  def self.concurrently_updatable_spotify_user_batches(batch_size:)
    users_by_app = SpotifyApp.order(created_at: :asc).map do |spotify_app|
      spotify_app.spotify_users.order(created_at: :asc)
    end
    most_spotify_users = with_most_spotify_users.present? ?
      with_most_spotify_users.spotify_users.count : 0
    flat_order = []

    most_spotify_users.times do |index|
      users_by_app.each do |users_in_app|
        flat_order << users_in_app[index] if users_in_app[index].present?
      end
    end

    num_batches = flat_order.count / batch_size
    num_batches += 1 if flat_order.count % batch_size != 0

    batches = []
    num_batches.times do |batch_index|
      offset = batch_index * batch_size
      batches << flat_order[offset, batch_size]
    end

    # batch_zones = batches.map do |batch|
    #   batch.map { |spotify_user| spotify_user.spotify_app.id }
    # end
    # pp batch_zones

    batches
  end
end
