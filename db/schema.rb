# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 202210261812226) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_errors", force: :cascade do |t|
    t.string "system", null: false
    t.string "api_operation", null: false
    t.text "error", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_logs", force: :cascade do |t|
    t.string "system", null: false
    t.text "url"
    t.text "payload"
    t.text "response"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_api_logs_on_created_at"
    t.index ["system"], name: "index_api_logs_on_system"
  end

  create_table "api_metadata", force: :cascade do |t|
    t.string "system", null: false
    t.string "api_operation", null: false
    t.datetime "last_called_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string "api_token_type", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audit_actions", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "controller", null: false
    t.string "action", null: false
    t.string "browser"
    t.string "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller", "action"], name: "index_audit_actions_on_controller_and_action"
    t.index ["user_id", "action"], name: "index_audit_actions_on_user_id_and_action"
    t.index ["user_id", "controller"], name: "index_audit_actions_on_user_id_and_controller"
  end

  create_table "batch_health_pros", force: :cascade do |t|
    t.string "health_pro_file"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_user"
    t.string "batch_type"
  end

  create_table "batch_invitation_codes", force: :cascade do |t|
    t.string "invitation_code_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "delayed_reference_id"
    t.string "delayed_reference_type"
    t.index ["delayed_reference_id"], name: "delayed_jobs_delayed_reference_id"
    t.index ["delayed_reference_type"], name: "delayed_jobs_delayed_reference_type"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "duplicate_matches", force: :cascade do |t|
    t.integer "health_pro_id", null: false
    t.integer "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "empi_matches", force: :cascade do |t|
    t.integer "health_pro_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birth_date"
    t.string "address"
    t.string "gender"
    t.string "nmhc_mrn", null: false
    t.string "ethnicity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "empi_race_matches", force: :cascade do |t|
    t.integer "empi_match_id", null: false
    t.integer "race_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "health_pros", force: :cascade do |t|
    t.integer "batch_health_pro_id", null: false
    t.string "status", null: false
    t.string "pmi_id"
    t.string "biobank_id"
    t.string "last_name"
    t.string "first_name"
    t.string "date_of_birth"
    t.string "language"
    t.string "general_consent_status"
    t.string "general_consent_date"
    t.string "ehr_consent_status"
    t.string "ehr_consent_date"
    t.string "cabor_consent_status"
    t.string "cabor_consent_date"
    t.string "withdrawal_status"
    t.string "withdrawal_date"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "email"
    t.string "phone"
    t.string "sex"
    t.string "gender_identity"
    t.string "race_ethnicity"
    t.string "education"
    t.string "required_ppi_surveys_complete"
    t.string "completed_surveys"
    t.string "basics_ppi_survey_complete"
    t.string "basics_ppi_survey_completion_date"
    t.string "health_ppi_survey_complete"
    t.string "health_ppi_survey_completion_date"
    t.string "lifestyle_ppi_survey_complete"
    t.string "lifestyle_ppi_survey_completion_date"
    t.string "hist_ppi_survey_complete"
    t.string "hist_ppi_survey_completion_date"
    t.string "meds_ppi_survey_complete"
    t.string "meds_ppi_survey_completion_date"
    t.string "family_ppi_survey_complete"
    t.string "family_ppi_survey_completion_date"
    t.string "access_ppi_survey_complete"
    t.string "access_ppi_survey_completion_date"
    t.string "physical_measurements_status"
    t.string "physical_measurements_completion_date"
    t.string "physical_measurements_location"
    t.string "samples_for_dna_received"
    t.string "biospecimens"
    t.string "eight_ml_sst_collected"
    t.string "eight_ml_sst_collection_date"
    t.string "eight_ml_pst_collected"
    t.string "eight_ml_pst_collection_date"
    t.string "four_ml_na_hep_collected"
    t.string "four_ml_na_hep_collection_date"
    t.string "four_ml_edta_collected"
    t.string "four_ml_edta_collection_date"
    t.string "first_10_ml_edta_collected"
    t.string "first_10_ml_edta_collection_date"
    t.string "second_10_ml_edta_collected"
    t.string "second_10_ml_edta_collection_date"
    t.string "urine_10_ml_collected"
    t.string "urine_10_ml_collection_date"
    t.string "saliva_collected"
    t.string "saliva_collection_date"
    t.string "biospecimens_location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "participant_status"
    t.string "paired_site"
    t.string "paired_organization"
    t.string "two_ml_edta_collected"
    t.string "two_ml_edta_collected_date"
    t.string "urine_90_ml_collected"
    t.string "urine_90_ml_collection_date"
    t.string "cell_free_dna_collected"
    t.string "cell_free_dna_collected_date"
    t.string "paxgene_rna_collected"
    t.string "paxgene_rna_collected_date"
    t.string "withdrawal_reason"
    t.string "language_of_general_consent"
    t.string "dv_only_ehr_sharing_status"
    t.string "dv_only_ehr_sharing_date"
    t.string "login_phone"
    t.string "street_address2"
    t.string "middle_name"
    t.string "age_range"
    t.string "patient_status"
    t.string "core_participant_date"
    t.string "participant_origination"
    t.string "deactivation_status"
    t.string "deactivation_date"
    t.string "consent_for_genomics_ror"
    t.string "consent_for_genomics_ror_date"
    t.string "questionnaire_on_cope_may"
    t.string "questionnaire_on_cope_may_time"
    t.string "questionnaire_on_cope_june"
    t.string "questionnaire_on_cope_june_time"
    t.string "questionnaire_on_cope_july"
    t.string "questionnaire_on_cope_july_authored"
    t.string "consent_cohort"
    t.string "program_update"
    t.string "date_of_program_update"
    t.string "ehr_expiration_status"
    t.string "date_of_ehr_expiration"
    t.string "date_of_first_primary_consent"
    t.string "date_of_first_ehr_consent"
    t.string "retention_eligible"
    t.string "date_of_retention_eligibility"
    t.string "deceased"
    t.string "date_of_death"
    t.string "date_of_approval"
    t.string "cope_nov_ppi_survey_complete"
    t.string "cope_nov_ppi_survey_completion_date"
    t.string "retention_status"
    t.string "ehr_data_transfer"
    t.string "most_recent_ehr_receipt"
    t.string "saliva_collection"
    t.string "cope_dec_ppi_survey_complete"
    t.string "cope_dec_ppi_survey_completion_date"
    t.string "cope_feb_ppi_survey_complete"
    t.string "cope_feb_ppi_survey_completion_date"
    t.string "core_participant_minus_pm_date"
    t.string "summer_minute_ppi_survey_complete"
    t.string "summer_minute_ppi_survey_completion_date"
    t.string "fall_minute_ppi_survey_complete"
    t.string "fall_minute_ppi_survey_completion_date"
    t.string "digital_health_consent"
    t.string "personal_and_family_hx_ppi_survey_complete"
    t.string "personal_and_family_hx_ppi_survey_completion_date"
    t.string "sdoh_ppi_survey_complete"
    t.string "sdoh_ppi_survey_completion_date"
    t.string "winter_minute_ppi_survey_complete"
    t.string "winter_minute_ppi_survey_completion_date"
    t.string "enrollment_site"
    t.string "new_year_minute_ppi_survey_complete"
    t.string "new_year_minute_ppi_survey_completion_date"
    t.string "digital_health_status_fitbit_complete_y"
    t.string "digital_health_status_fitbit_completion_date_d"
    t.string "digital_health_status_apple_health_kit_complete_y"
    t.string "digital_health_status_apple_health_kit_completion_date_d"
    t.string "digital_health_status_apple_health_ehr_complete_y"
    t.string "digital_health_status_apple_health_ehr_completion_date_d"
    t.string "physical_measurements_collect_type"
    t.string "onsite_id_verification_time"
    t.string "participant_incentives"
    t.string "self_reported_physical_measurements_status"
    t.string "self_reported_physical_measurements_authored"
    t.string "clinic_physical_measurements_finalized_time"
    t.string "clinic_physical_measurements_finalized_site"
    t.string "clinic_physical_measurements_time"
    t.string "clinic_physical_measurements_created_site"
    t.string "reconsent_for_study_enrollment_authored"
    t.string "reconsent_for_electronic_health_records_authored"
    t.string "questionnaire_on_life_functioning"
    t.string "questionnaire_on_life_functioning_authored"
    t.string "questionnaire_on_behaviorial_health_and_personality"
    t.string "questionnaire_on_emotional_health_history_and_well_being"
    t.string "questionnaire_on_behaviorial_health_and_personality_authored"
    t.string "questionnaire_on_emotional_health_history_and_well_being_author"
    t.string "questionnaire_on_environmental_exposures"
    t.string "questionnaire_on_environmental_exposures_authored"
    t.index ["batch_health_pro_id"], name: "idx_health_pros_batch_health_pro_id"
    t.index ["pmi_id"], name: "idx_health_pros_pmi_id"
    t.index ["status"], name: "index_health_pros_on_status"
  end

  create_table "invitation_code_assignments", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "invitation_code_id", null: false
    t.boolean "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code", null: false
    t.string "assignment_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batch_invitation_code_id"
  end

  create_table "login_audits", force: :cascade do |t|
    t.string "username", null: false
    t.string "login_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "matches", force: :cascade do |t|
    t.integer "health_pro_id", null: false
    t.integer "patient_id", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nicknames", force: :cascade do |t|
    t.string "name", null: false
    t.integer "nickname_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_empi_matches", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "empi_match_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_features", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.string "feature", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_health_pro_api_migrations", force: :cascade do |t|
    t.string "record_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pmi_id"
    t.string "gender"
    t.string "nmhc_mrn"
    t.string "registration_status"
    t.string "general_consent_status"
    t.string "general_consent_date"
    t.string "ehr_consent_status"
    t.string "ehr_consent_date"
    t.string "withdrawal_status"
    t.string "withdrawal_date"
    t.string "biospecimens_location"
    t.string "uuid"
    t.date "birth_date"
    t.string "ethnicity"
    t.string "participant_status"
    t.datetime "deleted_at"
    t.string "physical_measurements_completion_date"
    t.string "paired_site"
    t.string "paired_organization"
    t.string "health_pro_email"
    t.string "health_pro_login_phone"
    t.string "phone_1"
    t.boolean "health_pro_api_migrated"
  end

  create_table "patients", force: :cascade do |t|
    t.string "record_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pmi_id"
    t.string "gender"
    t.string "nmhc_mrn"
    t.string "registration_status"
    t.string "general_consent_status"
    t.string "general_consent_date"
    t.string "ehr_consent_status"
    t.string "ehr_consent_date"
    t.string "withdrawal_status"
    t.string "withdrawal_date"
    t.string "biospecimens_location"
    t.string "uuid"
    t.date "birth_date"
    t.string "ethnicity"
    t.string "participant_status"
    t.datetime "deleted_at"
    t.string "physical_measurements_completion_date"
    t.string "paired_site"
    t.string "paired_organization"
    t.string "health_pro_email"
    t.string "health_pro_login_phone"
    t.string "phone_1"
    t.boolean "health_pro_api_migrated"
    t.string "genomic_consent_status"
    t.string "genomic_consent_status_date"
    t.string "health_pro_phone"
    t.string "core_participant_date"
    t.string "deactivation_status"
    t.string "deactivation_date"
    t.string "required_ppi_surveys_complete"
    t.string "completed_surveys"
    t.string "basics_ppi_survey_complete"
    t.string "basics_ppi_survey_completion_date"
    t.string "health_ppi_survey_complete"
    t.string "health_ppi_survey_completion_date"
    t.string "lifestyle_ppi_survey_complete"
    t.string "lifestyle_ppi_survey_completion_date"
    t.string "hist_ppi_survey_complete"
    t.string "hist_ppi_survey_completion_date"
    t.string "meds_ppi_survey_complete"
    t.string "meds_ppi_survey_completion_date"
    t.string "family_ppi_survey_complete"
    t.string "family_ppi_survey_completion_date"
    t.string "access_ppi_survey_complete"
    t.string "access_ppi_survey_completion_date"
    t.string "questionnaire_on_cope_may"
    t.string "questionnaire_on_cope_may_time"
    t.string "questionnaire_on_cope_june"
    t.string "questionnaire_on_cope_june_time"
    t.string "questionnaire_on_cope_july"
    t.string "questionnaire_on_cope_july_authored"
    t.string "date_of_first_primary_consent"
    t.string "date_of_first_ehr_consent"
  end

  create_table "patients_races", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "race_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "races", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "role_assignments", force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "auto_assign_invitation_codes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "username", null: false
    t.boolean "system_administrator"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
