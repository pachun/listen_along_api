class DefaultIsListeningToFalse < ActiveRecord::Migration[5.2]
  def change
    change_column_default :spotify_users, :is_listening, false
  end
end
