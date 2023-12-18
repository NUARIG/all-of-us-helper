class AddHealthProApiFieldsToHealthPro8 < ActiveRecord::Migration[5.1]
  def change
    add_column :health_pros, :questionnaire_on_behaviorial_health_and_personality_authored, :string
    add_column :health_pros, :questionnaire_on_emotional_health_history_and_well_being_authored, :string
    add_column :health_pros, :questionnaire_on_environmental_exposures, :string
    add_column :health_pros, :questionnaire_on_environmental_exposures_authored, :string
  end
end
