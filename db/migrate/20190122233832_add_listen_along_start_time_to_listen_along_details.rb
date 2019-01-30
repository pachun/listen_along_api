class AddListenAlongStartTimeToListenAlongDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :listen_along_details, :listen_along_start_time, :integer
  end
end
