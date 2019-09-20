desc "Refresh Expired Avatars"

task :refresh_expired_avatars => [:environment] do
  RefreshExpiredAvatars.refresh
end
