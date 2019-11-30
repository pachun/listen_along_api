require "rufus-scheduler"

EVERY_DAY_AT_MIDNIGHT = "0 0 * * *"

FIVE_SECONDS = "5s"
TEN_MINUTES = "10m"

scheduler = Rufus::Scheduler.singleton

scheduler.every FIVE_SECONDS do
  run do
    if Rails.env.production?
      UpdatePlaybackWorker.perform_async
    else
      UpdatePlaybackWorker.new.perform
    end
  end
end

scheduler.every TEN_MINUTES do
  run do
    if Rails.env.production?
      UpdateInactiveUsersPlaybackWorker.perform_async
    else
      UpdateInactiveUsersPlaybackWorker.new.perform
    end
  end
end

scheduler.cron EVERY_DAY_AT_MIDNIGHT do
  run do
    if Rails.env.production?
      RefreshExpiredAvatarsWorker.perform_async
    else
      RefreshExpiredAvatarsWorker.new.perform
    end
  end
end

def run
  begin
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.verify!
    end

    yield

  rescue => e
    Rails.logger.debug(e.inspect)
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
