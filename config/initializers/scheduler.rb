require "rufus-scheduler"

Rufus::Scheduler.singleton.every "5s" do
  begin
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.verify!
    end
    UpdatePlaybackService.update
  rescue => e
    Rails.logger.debug(e.inspect)
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
