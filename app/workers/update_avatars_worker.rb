class UpdateAvatarsWorker
  include Sidekiq::Worker

  def perform
    UpdateAvatars.update
  end
end
