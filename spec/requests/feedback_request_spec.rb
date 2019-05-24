require "rails_helper"

describe FeedbackController do
  describe "POST #create" do
    context "without a signed in spotify user" do
      it "responds with a 401 'unauthorized' status" do
        post "/feedback"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "responds with an http status of 201 created" do
      post "/feedback", headers: authenticated_spotify_user_headers

      expect(response).to have_http_status(:created)
    end

    it "saves feedback" do
      spotify_user_1 = create :spotify_user

      post "/feedback",
        headers: authenticated_spotify_user_headers(spotify_user_1),
        params: { feedback: "Hello World" }

      expect(Feedback.last.spotify_user).to eq(spotify_user_1)
      expect(Feedback.last.feedback).to eq("Hello World")

      spotify_user_2 = create :spotify_user

      post "/feedback",
        headers: authenticated_spotify_user_headers(spotify_user_2),
        params: { feedback: "Lorem Ipsum" }

      expect(Feedback.last.spotify_user).to eq(spotify_user_2)
      expect(Feedback.last.feedback).to eq("Lorem Ipsum")
    end
  end
end
