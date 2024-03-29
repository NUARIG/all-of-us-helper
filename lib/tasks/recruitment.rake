require 'redcap_api'
require 'study_tracker_api'
require 'csv'
require 'tempfile'

namespace :recruitment do
  desc 'Load export and update cohorts'
  task load_export_and_cohorts: [:environment, :load_export, :load_cohorts]

  desc 'Load export, use FILENAME to provide filename (without path), e.g FILENAME=AoU_Recruitment_Report_20220531.csv'
  task(load_export: :environment) do  |t, args|
    begin
      filename = ENV['FILENAME'] || "AoU_Recruitment_Report_#{Date.today.to_s.gsub('-','')}.csv"
      clean_file = clean_file(filename)

      options = { system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP_RECRUITMENT }
      redcap_api = RedcapApi.initialize_redcap_api(options)

      counter = 0
      buffer = []
      CSV.foreach(clean_file, headers: true, col_sep: ",", return_headers: false,  quote_char: "\"") do |row|
        counter +=1
        buffer << row

        if counter == 20
          mrns = buffer.map{|edw_patient| edw_patient['mrn']}
          response = redcap_api.recruitment_patients_by_mrns(mrns)
          recruitment_patients = response[:response]

          buffer.each do |edw_patient|
            recruitment_patient = recruitment_patients.detect{ |recruitment_patient| recruitment_patient['mrn'] ==  edw_patient['mrn'] }
            if recruitment_patient.blank? && !edw_patient['mrn'].blank?
              redcap_api.create_recruitment_patient(edw_patient['mrn'], edw_patient['patient_name'], edw_patient['race'], edw_patient['gender'], edw_patient['dob'], edw_patient['ethnicity'], edw_patient['patient_address_1'], edw_patient['patient_address_2'], edw_patient['patient_city'], edw_patient['patient_state_province'], edw_patient['patient_email_address'], edw_patient['patient_postal_code'], edw_patient['patient_home_phone'], edw_patient['patient_work_phone'], edw_patient['patient_mobile_phone'], edw_patient['department_name'], edw_patient['department_external_name'], edw_patient['appointment_datetime'])
            end
          end
          counter = 0
          buffer = []
        end
      end
      clean_file.close
    rescue => error
      handle_error(t, error)
    end
  end

  desc 'Load cohorts'
  task(load_cohorts: :environment) do  |t, args|
    begin
      options = { system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP_RECRUITMENT }
      redcap_api = RedcapApi.initialize_redcap_api(options)
      cohorts = get_st_cohorts

      cohorts.each_slice(20) do |buffer|
        mrns = buffer.map{|cohort| cohort['identifier']['primary_record_number']['record_number']}
        response = redcap_api.recruitment_patients_by_mrns(mrns)
        recruitment_patients = response[:response]

        buffer.each do |cohort|
          mrn = cohort['identifier']['primary_record_number']['record_number']
          recruitment_patient = recruitment_patients.detect{ |recruitment_patient| recruitment_patient['mrn'] == mrn }
          if recruitment_patient.present?
            st_event = cohort['current_status']['status']
            st_event_d = cohort['current_status']['date']
            st_import_d = cohort['status_history'].map { |status| status['date'].present? ? Date.parse(status['date']) : nil}.compact.min
            st_import_d = st_import_d.to_s(:date)
            # sleep(1)
            redcap_api.update_recruitment_patient(recruitment_patient['record_id'], st_event, st_event_d, st_import_d)
          else
            ApiError.create!(system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_operation: ApiMetadata::API_OPERATION_REDCAP_RECRUITMENT_UPDATE_PATIENT,  error: "The following NMHC MRN was not able to be found the All of Us MyChart Recruitment Tracking REDCap project: #{mrn}.")
          end
        end
      end
      ApiMetadata.update_last_called_at(ApiMetadata::API_OPERATION_STUDY_TRACKER_COHORTS)
    rescue => error
      handle_error(t, error)
    end
  end

  desc "Delete Patients"
  task(delete_patients: :environment) do  |t, args|
    begin
      options = { system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP_RECRUITMENT }
      redcap_api = RedcapApi.initialize_redcap_api(options)
      response = redcap_api.recruitment_patients
      recruitment_patients = response[:response]

      file = "#{Rails.root}/lib/setup/data/AoU_Recruitment_Report_delete.csv"
      edw_patients = CSV.new(File.open(file), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      edw_patients.each do |edw_patient|
        recruitment_patient = recruitment_patients.detect{ |recruitment_patient| recruitment_patient['mrn'] ==  edw_patient['mrn'] }
        if recruitment_patient.present?
          redcap_api.delete_recruitment_patient(recruitment_patient['record_id'])
        end
      end
    rescue => error
      handle_error(t, error)
    end
  end

  desc "Delete Patients by Email"
  task(delete_patients_by_email: :environment) do  |t, args|
    begin
      options = { system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP_RECRUITMENT }
      redcap_api = RedcapApi.initialize_redcap_api(options)
      response = redcap_api.recruitment_patients
      recruitment_patients = response[:response]

      # file = "#{Rails.root}/lib/setup/data/AoU_Recruitment_Report_delete.csv"
      file = "#{Rails.root}/lib/setup/data/patients_to_add_to_redcap_2022_03_01_fix.csv"
      edw_patients = CSV.new(File.open(file), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      edw_patients.each do |edw_patient|
        puts edw_patient['patient_email_address']
        rp = recruitment_patients.select{ |recruitment_patient| recruitment_patient['patient_email_address'] ==  edw_patient['patient_email_address'] }
        rp.each do |recruitment_patient|
          if recruitment_patient.present? && recruitment_patient['mrn'].blank?
            puts 'we going to delete!'
            puts recruitment_patient['record_id']
            puts 'we we did it!'
            redcap_api.delete_recruitment_patient(recruitment_patient['record_id'])
          end
        end
      end
    rescue => error
      handle_error(t, error)
    end
  end

  desc "Delete Patients by REDcap record_id"
  task(delete_patients_by_record_id: :environment) do  |t, args|
    begin
      options = { system: RedcapApi::SYSTEM_REDCAP_RECRUITMENT, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP_RECRUITMENT }
      redcap_api = RedcapApi.initialize_redcap_api(options)

      file = ENV['FILE']
      raise "File does not exist: #{file}" unless FileTest.exist?(file)

      record_ids = CSV.new(File.open(file), headers: false, col_sep: ",", return_headers: false,  quote_char: "\"")
      record_ids.each do |record_id|
        puts record_id[0].inspect
        puts 'we going to delete!'
        redcap_api.delete_recruitment_patient(record_id[0])
        puts 'we we did it!'
      end
    rescue => error
      handle_error(t, error)
    end
  end
end

def handle_error(t, error)
  puts error.class
  puts error.message
  puts error.backtrace.join("\n")

  Rails.logger.info(error.class)
  Rails.logger.info(error.message)
  Rails.logger.info(error.backtrace.join("\n"))
  ExceptionNotifier.notify_exception(error)
end

def clean_file(filename)
  filepath = Rails.env.development? ? "#{Rails.root}/lib/setup/data" : '/mnt/fsmresfiles/vfsmnubicapps/STU00204480'

  # Remove non-UTF characters from the original file
  original_file = File.open("#{filepath}/#{filename}")
  clean_file = Tempfile.new("#{filename}.clean")

  original_file.each do |l|
    clean_file.write(l.encode("UTF-8", invalid: :replace, replace: ''))
  end
  clean_file.rewind
  clean_file
end

def get_st_cohorts
  last_called_at = ApiMetadata.last_called_at_by_api_operation(ApiMetadata::API_OPERATION_STUDY_TRACKER_COHORTS)
  if last_called_at.blank?
    last_called_at = Date.parse('1/1/1900')
  end

  last_called_at = last_called_at.to_date - 4
  study_tracker_api = StudyTrackerApi.new
  study_tracker_api.generate_token
  options = { 'current_status_after' =>  last_called_at }

  response = nil
  with_retries(:max_tries => 3) do |attempt_number|
    response = study_tracker_api.cohorts(options)
  end
  cohorts = response[:response]
  cohorts['cohorts'].select{|cohort| cohort['identifier'].present? && cohort['identifier']['primary_record_number'].present? && cohort['identifier']['primary_record_number']['type'] == 'nmhc'}
end