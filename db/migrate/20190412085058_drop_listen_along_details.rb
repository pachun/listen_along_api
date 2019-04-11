class DropListenAlongDetails < ActiveRecord::Migration[5.2]
  def change
    drop_table :listen_along_details
  end
end
