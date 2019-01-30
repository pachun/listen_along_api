class CreateListenAlongDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :listen_along_details do |t|
      t.references :broadcaster
      t.references :listener
      t.integer :duration

      t.timestamps
    end
  end
end
