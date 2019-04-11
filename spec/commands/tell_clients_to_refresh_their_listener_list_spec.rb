require "rails_helper"

describe TellClientsToRefreshTheirListenerList do
  describe "self.tell" do
    it "tells clients to refresh their listener list" do
      expect {
        TellClientsToRefreshTheirListenerList.tell
      }.to have_broadcasted_to("spotify_users_channel").with({})
    end
  end
end
