class AddHealthProApiFieldsToHealthPros4 < ActiveRecord::Migration[5.1]
  def change
    add_column :health_pros, :cope_feb_ppi_survey_complete, :string
    add_column :health_pros, :cope_feb_ppi_survey_completion_date, :string
    add_column :health_pros, :core_participant_minus_pm_date, :string
    add_column :health_pros, :summer_minute_ppi_survey_complete, :string
    add_column :health_pros, :summer_minute_ppi_survey_completion_date, :string
    add_column :health_pros, :fall_minute_ppi_survey_complete, :string
    add_column :health_pros, :fall_minute_ppi_survey_completion_date, :string
    add_column :health_pros, :digital_health_consent, :string
    add_column :health_pros, :personal_and_family_hx_ppi_survey_complete, :string
    add_column :health_pros, :personal_and_family_hx_ppi_survey_completion_date, :string
    add_column :health_pros, :sdoh_ppi_survey_complete, :string
    add_column :health_pros, :sdoh_ppi_survey_completion_date, :string
    add_column :health_pros, :winter_minute_ppi_survey_complete, :string
    add_column :health_pros, :winter_minute_ppi_survey_completion_date, :string
  end
end