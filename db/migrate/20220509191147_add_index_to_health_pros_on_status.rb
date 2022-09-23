class AddIndexToHealthProsOnStatus < ActiveRecord::Migration[5.1]
  def change
    add_index :health_pros, :status
  end
end
