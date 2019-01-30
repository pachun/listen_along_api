class DefaultListenAlongDetailsDurationToZero < ActiveRecord::Migration[5.2]
  def change
    change_column_default :listen_along_details, :duration, 0
  end
end
