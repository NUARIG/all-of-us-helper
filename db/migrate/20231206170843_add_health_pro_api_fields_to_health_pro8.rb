class AddHealthProApiFieldsToHealthPro8 < ActiveRecord::Migration[5.1]
  change_table(:health_pros, bulk: true) do |t|
    t.column   :questionnaire_on_behaviorial_health_and_personality_authored, :string
    t.column   :questionnaire_on_emotional_health_history_and_well_being_authored, :string
    t.column   :questionnaire_on_environmental_exposures, :string
    t.column   :questionnaire_on_environmental_exposures_authored, :string
  end
end
