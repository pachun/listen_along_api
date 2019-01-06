class RenameClientIdToClientIdentifierForActiveAdmin < ActiveRecord::Migration[5.2]
  def change
    rename_column :spotify_apps, :client_id, :client_identifier
  end
end
