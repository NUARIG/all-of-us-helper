class AddHealthProApiFieldsToHealthPro7 < ActiveRecord::Migration[5.1]
  def change
    add_column :health_pros, :questionnaire_on_behaviorial_health_and_personality, :string
    add_column :health_pros, :questionnaire_on_emotional_health_history_and_wel_being, :string
  end
end
