require "rails_helper"

describe UnsyncListenersWhoseBroadcasterStoppedBroadcasting do
  describe "self.unsync" do
    context "a broadcasters playback has ended" do
      it "stops syncing their listeners with their playback" do
        broadcaster = create :spotify_user,
          is_listening: false
        listener = create :spotify_user,
          broadcaster: broadcaster

        not_listening_relation_double = instance_double(ActiveRecord::Relation)
        allow(SpotifyUser).to receive(:where)
          .with(is_listening: false)
          .and_return(not_listening_relation_double)
        allow(SpotifyUser).to receive(:where)
          .with(broadcaster: not_listening_relation_double)
          .and_return([listener])

        allow(listener).to receive(:stop_listening_along!)

        UnsyncListenersWhoseBroadcasterStoppedBroadcasting.unsync

        expect(listener).to have_received(:stop_listening_along!)
      end
    end
  end
end
