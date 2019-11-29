class UpdatableUserBatchService
  def self.with(batch_size:, listening:)
    new(batch_size, listening).batches
  end

  def initialize(batch_size, listening)
    @batch_size = batch_size
    @listening = listening
  end

  def batches
    @batches = []
    num_batches.times do |batch_index|
      offset = batch_index * batch_size
      @batches << flat_order[offset, batch_size]
    end
    @batches
  end

  private

  attr_reader :batch_size, :listening

  def num_batches
    return @num_batches if @num_batches.present?

    @num_batches = flat_order.count / batch_size
    @num_batches += 1 if flat_order.count % batch_size != 0
    @num_batches
  end

  def flat_order
    return @flat_order if @flat_order.present?

    @flat_order = []
    most_spotify_users.times do |index|
      users_by_app.each do |users_in_app|
        users = users_in_app.select { |user| user.is_listening == listening }
        @flat_order << users[index] if users[index].present?
      end
    end
    @flat_order
  end

  def most_spotify_users
    @most_spotify_users ||= app_with_most_users.present? ?
      app_with_most_users.spotify_users.count : 0
  end

  def app_with_most_users
    @app_with_most_users ||= SpotifyApp.with_most_spotify_users(listening: listening)
  end

  def users_by_app
    @users_by_app ||= SpotifyApp.order(created_at: :asc).map do |spotify_app|
      spotify_app.spotify_users.order(created_at: :asc)
    end
  end
end
