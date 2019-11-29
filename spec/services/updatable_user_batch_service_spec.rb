require "rails_helper"

describe UpdatableUserBatchService do
  describe "self.with(batch_size:, listening:)" do
    context "listening is true" do
      it "returns batches only of users who are currently listening" do
        app_1 = create :spotify_app
        app_1_users = (0..4).map do
          create :spotify_user, spotify_app: app_1, is_listening: true
        end

        app_2 = create :spotify_app
        app_2_users = (0..1).map do
          create :spotify_user, spotify_app: app_2, is_listening: true
        end

        app_3 = create :spotify_app
        create :spotify_user, spotify_app: app_3, is_listening: false

        batches = UpdatableUserBatchService.with(batch_size: 2, listening: true)

        expect(batches).to eq([[
          app_1_users[0], app_2_users[0],
        ], [
          app_1_users[1], app_2_users[1],
        ], [
          app_1_users[2], app_1_users[3],
        ], [
          app_1_users[4],
        ]])
      end
    end

    context "listening is false" do
      it "returns batches only of users who are not currently listening" do
        app_1 = create :spotify_app
        app_1_users = (0..4).map do
          create :spotify_user, spotify_app: app_1, is_listening: false
        end

        app_2 = create :spotify_app
        app_2_users = (0..1).map do
          create :spotify_user, spotify_app: app_2, is_listening: false
        end

        app_3 = create :spotify_app
        create :spotify_user, spotify_app: app_3, is_listening: true

        batches = UpdatableUserBatchService.with(
          batch_size: 2,
          listening: false,
        )

        expect(batches).to eq([[
          app_1_users[0], app_2_users[0],
        ], [
          app_1_users[1], app_2_users[1],
        ], [
          app_1_users[2], app_1_users[3],
        ], [
          app_1_users[4],
        ]])
      end
    end
  end
end
