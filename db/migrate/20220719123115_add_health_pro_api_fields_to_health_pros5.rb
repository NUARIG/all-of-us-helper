class AddHealthProApiFieldsToHealthPros5 < ActiveRecord::Migration[5.1]
  def change
    add_column :health_pros, :enrollment_site, :string
    add_column :health_pros, :new_year_minute_ppi_survey_complete, :string
    add_column :health_pros, :new_year_minute_ppi_survey_completion_date, :string

    add_column :health_pros, :digital_health_status_fitbit_complete_y, :string
    add_column :health_pros, :digital_health_status_fitbit_completion_date_d, :string
    add_column :health_pros, :digital_health_status_apple_health_kit_complete_y, :string
    add_column :health_pros, :digital_health_status_apple_health_kit_completion_date_d, :string
    add_column :health_pros, :digital_health_status_apple_health_ehr_complete_y, :string
    add_column :health_pros, :digital_health_status_apple_health_ehr_completion_date_d, :string
  end
end
