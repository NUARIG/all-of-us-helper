require 'rest_client'
class StudyTrackerApi
  SEARCH_TYPE_IDENTIFIERS = 'identifiers'
  SEARCH_TYPE_DEMOGRAPHICS = 'demographics'
  SEARCH_TYPES = [SEARCH_TYPE_IDENTIFIERS, SEARCH_TYPE_DEMOGRAPHICS]
  IRB_NUMBER = 'STU00204480'
  ORG_NMHC = 'nmhc'
  EVENT_TYPE_NAME_CONSENTED = 'Consented'
  EVENT_TYPE_NAME_EHR_CONSENT = 'EHR Consent'
  EVENT_TYPE_NAME_EHR_REMOVAL = 'EHR Consent Removal'
  EVENT_TYPE_NAME_WITHDRAWN = 'Withdrawn'
  SYSTEM = 'study tracker'

  def initialize
    @user = Rails.application.config.all_of_us_helper_api_users['study_tracker']['api_user']
    @password = Rails.application.config.all_of_us_helper_api_users['study_tracker']['password']
    @auth_token = nil

    if Rails.env.development? || Rails.env.test?
      @verify_ssl = Rails.configuration.custom.app_config['study_tracker'][Rails.env]['verify_ssl'] || true
    else
      @verify_ssl = true
    end
  end

  def empi_lookup(options)
    options = { 'study_id' => StudyTrackerApi::IRB_NUMBER, 'search_type' => StudyTrackerApi::SEARCH_TYPE_DEMOGRAPHICS }.merge(options)
    url = Rails.configuration.custom.app_config['study_tracker'][Rails.env]['empi_lookup'] + '?' + URI.encode_www_form(options)
    api_response = study_tracker_api_request_wrapper(url: url, method: :get, parse_response: true)
    { response: api_response[:response], error: api_response[:error] }
  end

  def register(options, patient)
    begin
      payload = {}
      payload[:subject] = {}
      payload[:proxy_user] = options[:proxy_user]
      options.delete(:proxy_user)
      payload[:subject][:irb_number] = StudyTrackerApi::IRB_NUMBER
      payload[:subject][:ethnicity] = patient.ethnicity
      payload[:subject][:gender] = patient.gender
      payload[:subject][:case_number] = patient.pmi_id
      payload[:subject][:uuid] = patient.uuid
      payload[:subject][:first_name] = patient.first_name
      payload[:subject][:last_name] = patient.last_name
      payload[:subject][:birth_date] = patient.birth_date.to_s
      payload[:subject][:races] = patient.races.map { |race| race.name }
      if patient.nmhc_mrn.present?
        payload[:subject][:record_numbers] = []
        payload[:subject][:record_numbers] << { org: StudyTrackerApi::ORG_NMHC, record_number: patient.nmhc_mrn }
      end
      payload[:subject][:events] = []

      if patient.general_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_CONSENTED, date: Date.parse(patient.general_consent_date).to_s }
      end

      if patient.ehr_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_EHR_CONSENT, date: Date.parse(patient.ehr_consent_date).to_s }
      end

      if patient.withdrawal_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_WITHDRAWN
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_WITHDRAWN, date: Date.parse(patient.withdrawal_date).to_s }
      end

      if patient.date_of_first_primary_consent.present?
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_CONSENTED, date: Date.parse(patient.date_of_first_primary_consent).to_s }
      end

      if patient.date_of_first_ehr_consent.present?
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_EHR_CONSENT, date: Date.parse(patient.date_of_first_ehr_consent).to_s }
      end

      if patient.date_of_first_ehr_consent.present? && patient.ehr_consent_date.blank?
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_EHR_REMOVAL, date: Date.parse(patient.date_of_first_ehr_consent).to_s }
      end

      if patient.ehr_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_DECLINED && patient.ehr_consent_date.present?
        payload[:subject][:events] << { name: StudyTrackerApi::EVENT_TYPE_NAME_EHR_REMOVAL, date: Date.parse(patient.ehr_consent_date).to_s }
      end

      url = Rails.configuration.custom.app_config['study_tracker'][Rails.env]['register'].gsub(':id', patient.uuid)

      api_response = study_tracker_api_request_wrapper(url: url, method: :put, parse_response: true, payload: payload)

      { response: api_response[:response], error: api_response[:error] }
    rescue Exception => e
      error = e
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
      { response: nil, error: error }
    end
  end

  def generate_token
    url = Rails.configuration.custom.app_config['study_tracker'][Rails.env]['generate_token']
    response = nil
    error =  nil
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        user: @user,
        password: @password,
        accept: 'json',
        verify_ssl: @verify_ssl,
        headers: {
          content_type: 'application/json; charset=utf-8'
        }
      )
      ApiLog.create_api_log(url, nil, response, nil, StudyTrackerApi::SYSTEM)
      response =  JSON.parse(response)
      if response[:errors].present?
        error = response[:errors]
      else
        @auth_token = response['auth_token']
      end
    rescue RestClient::ExceptionWithResponse => e
      error = e.response.present? ? e.to_s + e.response : e.to_s
      ExceptionNotifier.notify_exception(error)
      ApiLog.create_api_log(url, nil, nil, error, StudyTrackerApi::SYSTEM)
      Rails.logger.info(error)
      Rails.logger.info(e.class)
      Rails.logger.info(e.backtrace.join("\n"))
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      ApiLog.create_api_log(url, nil, nil, e.message, StudyTrackerApi::SYSTEM)
      error = e
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
    end

    { response: response, error: error }
  end

  def cohorts(options)
    options = { 'irb_number' => StudyTrackerApi::IRB_NUMBER, 'proxy_user' => 'mjg994', 'current_status_after' => Date.parse('1/1/1900'), 'fields' => 'status_history' }.merge(options)
    url = Rails.configuration.custom.app_config['study_tracker'][Rails.env]['cohorts'] + '?' + URI.encode_www_form(options)
    response = nil
    error =  nil
    headers = { "content-type": 'application/json', 'Authorization': "Bearer #{@auth_token}" }
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        accept: 'json',
        verify_ssl: @verify_ssl,
        headers: headers
      )
      ApiLog.create_api_log(url, nil, response, nil, StudyTrackerApi::SYSTEM)

      response =  JSON.parse(response)

      if response[:errors].present?
        error = response[:errors]
      else
        @auth_token = response['auth_token']
      end
    rescue RestClient::ExceptionWithResponse => e
      error = e.response.present? ? e.to_s + e.response : e.to_s
      ExceptionNotifier.notify_exception(error)
      ApiLog.create_api_log(url, nil, nil, error, StudyTrackerApi::SYSTEM)
      Rails.logger.info(error)
      Rails.logger.info(e.class)
      Rails.logger.info(e.backtrace.join("\n"))
      raise e
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      ApiLog.create_api_log(url, nil, nil, e.message, StudyTrackerApi::SYSTEM)
      error = e
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
      raise e
    end

    { response: response, error: error }
  end

  private
    def study_tracker_api_request_wrapper(options={})
      response = nil
      error =  nil
      begin
        case options[:method]
        when :get
          response = RestClient::Request.execute(
            method: options[:method],
            url: options[:url],
            user: @user,
            password: @password,
            accept: 'json',
            verify_ssl: @verify_ssl,
            headers: {
              content_type: 'application/json; charset=utf-8'
            }
          )
          ApiLog.create_api_log(options[:url], nil, response, nil, StudyTrackerApi::SYSTEM)
        else
           # payload = options[:payload].to_json
           payload = ActiveSupport::JSON.encode(options[:payload])
           options[:payload] = payload
           response = RestClient::Request.execute(
            method: options[:method],
            user: @user,
            password: @password,
            url: options[:url],
            payload: payload,
            # content_type:  'application/json',
            # accept: 'json',
            verify_ssl: @verify_ssl,
            headers: {
              content_type: 'application/json; charset=utf-8'
            }
          )
          ApiLog.create_api_log(options[:url], payload, response, nil, StudyTrackerApi::SYSTEM)
        end
        response = JSON.parse(response) if options[:parse_response]
        if response[:errors].present?
          error = response[:errors]
        end
      rescue RestClient::ExceptionWithResponse => e
        error = e.response.present? ? e.to_s + e.response : e.to_s
        ExceptionNotifier.notify_exception(e)
        ApiLog.create_api_log(options[:url], options[:payload], nil, error, StudyTrackerApi::SYSTEM)
        Rails.logger.info(error)
        Rails.logger.info(e.class)
        Rails.logger.info(e.backtrace.join("\n"))
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        ApiLog.create_api_log(options[:url], options[:payload], nil, e.message, StudyTrackerApi::SYSTEM)
        error = e
        Rails.logger.info(e.class)
        Rails.logger.info(e.message)
        Rails.logger.info(e.backtrace.join("\n"))
      end

      { response: response, error: error }
    end
end