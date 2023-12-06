class RenameWelBeingToWellBeing < ActiveRecord::Migration[5.1]
  def change
    rename_column :health_pros, :questionnaire_on_emotional_health_history_and_wel_being, :questionnaire_on_emotional_health_history_and_well_being
  end
end
