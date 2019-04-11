require "rails_helper"

describe CarryListenersToNewBroadcasters do
  describe "self.carry" do
    context "a listeners broadcaster started listening to another broadcaster" do
      it "updates the listeners broadcaster to the new broadcaster" do
        new_broadcaster = create :spotify_user
        original_broadcaster = create :spotify_user, broadcaster: new_broadcaster
        listener = create :spotify_user, broadcaster: original_broadcaster

        CarryListenersToNewBroadcasters.carry

        expect(listener.reload.broadcaster).to eq(new_broadcaster)
      end
    end
  end
end
