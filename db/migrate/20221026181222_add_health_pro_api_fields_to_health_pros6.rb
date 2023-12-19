class AddHealthProApiFieldsToHealthPros6 < ActiveRecord::Migration[5.1]
  def change
    add_column :health_pros, :physical_measurements_collect_type, :string
    add_column :health_pros, :onsite_id_verification_time, :string
    add_column :health_pros, :participant_incentives, :string

    add_column :health_pros, :self_reported_physical_measurements_status, :string
    add_column :health_pros, :self_reported_physical_measurements_authored, :string
    add_column :health_pros, :clinic_physical_measurements_finalized_time, :string
    add_column :health_pros, :clinic_physical_measurements_finalized_site, :string
    add_column :health_pros, :clinic_physical_measurements_time, :string
    add_column :health_pros, :clinic_physical_measurements_created_site, :string

    add_column :health_pros, :reconsent_for_study_enrollment_authored, :string
    add_column :health_pros, :reconsent_for_electronic_health_records_authored, :string
    add_column :health_pros, :questionnaire_on_life_functioning, :string
    add_column :health_pros, :questionnaire_on_life_functioning_authored, :string
  end
end
