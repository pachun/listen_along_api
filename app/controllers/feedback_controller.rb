class FeedbackController < ApiController
  before_action :authenticate_spotify_user

  def create
    Feedback.create(
      spotify_user: current_spotify_user,
      feedback: feedback_params["feedback"],
    )
    head :created
  end

  private

  def feedback_params
    params.permit("feedback")
  end
end
