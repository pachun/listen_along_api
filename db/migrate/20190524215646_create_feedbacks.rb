class CreateFeedbacks < ActiveRecord::Migration[5.2]
  def change
    create_table :feedbacks do |t|
      t.references :spotify_user, foreign_key: true
      t.string :feedback

      t.timestamps
    end
  end
end
