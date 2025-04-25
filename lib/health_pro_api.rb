require 'googleauth'
require 'google/apis/iam_v1'
require 'base64'
require "fileutils"
class HealthProApi
  SYSTEM = 'health pro'
  def initialize
    if Rails.env.development? || Rails.env.test?
      @verify_ssl = Rails.configuration.custom.app_config['health_pro'][Rails.env]['verify_ssl'] || true
    else
      @verify_ssl = true
    end
  end

  def participant_summary(options)
    # options = { sort: 'lastModified', count: 1000, participantId: '' }.merge(options)
    options = { sort: 'lastModified', count: 1000 }.merge(options)
    awardee = Rails.configuration.custom.app_config['health_pro'][Rails.env]['awardee']
    project = Rails.configuration.custom.app_config['health_pro'][Rails.env]['project']
    url = Rails.configuration.custom.app_config['health_pro'][Rails.env]['awardee_insite_summary_url']
    if options[:participantId]
      url = url + '?' + "_sort=#{options[:sort]}" + '&' + "_count=#{options[:count]}" + '&' + "awardee=#{awardee}"+ '&' + "participantId=#{options[:participantId]}"
    else
      url = url + '?' + "_sort=#{options[:sort]}" + '&' + "_count=#{options[:count]}" + '&' + "awardee=#{awardee}"
    end
    if options[:_token]
      url = url + '&_token=' + options[:_token]
    end
    api_response = health_pro_api_request_wrapper(url: url, method: :get, parse_response: true)
    { response: api_response[:response], error: api_response[:error] }
  end

  def create_service_account_key
    service = Google::Apis::IamV1::IamService.new
    service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/cloud-platform'])
    project_id = Rails.configuration.custom.app_config['health_pro'][Rails.env]['project_id']
    service_account = Rails.configuration.custom.app_config['health_pro'][Rails.env]['service_account']
    name = "projects/#{project_id}/serviceAccounts/#{service_account}"
    request_body = Google::Apis::IamV1::CreateServiceAccountKeyRequest.new
    response = service.create_service_account_key(name, request_body)
    privateKeyData = JSON.parse(response.to_json)['privateKeyData']
    privateKeyData = Base64.strict_decode64(privateKeyData)
    privateKeyData = JSON.parse(privateKeyData)
    privateKeyData.to_json
    json_key_io_path = Rails.configuration.custom.app_config['health_pro'][Rails.env]['json_key_io_path']
    File.open("#{json_key_io_path}gcloud_key_new.json", 'w') do |f|
      f.write(privateKeyData.to_json)
    end
  end

  def rotate_service_account_key(options={})
    json_key_io_path = Rails.configuration.custom.app_config['health_pro'][Rails.env]['json_key_io_path']
    options = {service_account_key: "#{json_key_io_path}gcloud_key.json", new_service_account_key: "#{json_key_io_path}gcloud_key_new.json"}.merge(options)
    File.rename(options[:service_account_key], "#{json_key_io_path}gcloud_key_old.json")
    File.rename(options[:new_service_account_key], "#{json_key_io_path}gcloud_key.json")
  end

  def delete_project_service_account_key
    service = Google::Apis::IamV1::IamService.new
    service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/cloud-platform'])
    project_id = Rails.configuration.custom.app_config['health_pro'][Rails.env]['project_id']
    service_account = Rails.configuration.custom.app_config['health_pro'][Rails.env]['service_account']
    json_key_io_path = Rails.configuration.custom.app_config['health_pro'][Rails.env]['json_key_io_path']
    json_key_io = "#{json_key_io_path}gcloud_key_old.json"
    name = "projects/#{project_id}/serviceAccounts/#{service_account}/keys/#{private_key_id(json_key_io)}"
    service.delete_project_service_account_key(name)
  end

  def archive_service_account_key
    json_key_io_path = Rails.configuration.custom.app_config['health_pro'][Rails.env]['json_key_io_path']
    json_key_io = "#{json_key_io_path}gcloud_key_old.json"
    FileUtils.move json_key_io, "#{json_key_io_path}/archive/gcloud_key#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.json"
  end

  private
    def private_key_id(json_key_io)
      json_key_io = File.open(json_key_io)
      json_key_io = JSON.parse(json_key_io.read)
      json_key_io['private_key_id']
    end

    def headers
      scope = 'https://www.googleapis.com/auth/userinfo.email'
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(Rails.configuration.custom.app_config['health_pro'][Rails.env]['json_key_io']),
        scope: scope
      )

      access_token = authorizer.fetch_access_token!
      headers = { "content-type": 'application/json', 'Authorization': "Bearer #{access_token['access_token']}" }
    end

    def health_pro_api_request_wrapper(options={})
      response = nil
      error =  nil
      begin
        case options[:method]
        when :get
          response = RestClient::Request.execute(
            method: options[:method],
            url: options[:url],
            accept: 'json',
            verify_ssl: @verify_ssl,
            headers: headers
          )
          ApiLog.create_api_log(options[:url], nil, response, nil, HealthProApi::SYSTEM)
        else
           # payload = options[:payload].to_json
           payload = ActiveSupport::JSON.encode(options[:payload])
           options[:payload] = payload
           response = RestClient::Request.execute(
            method: options[:method],
            url: options[:url],
            payload: payload,
            verify_ssl: @verify_ssl,
            headers: headers
          )
          ApiLog.create_api_log(options[:url], payload, response, nil, HealthProApi::SYSTEM)
        end
        response = JSON.parse(response) if options[:parse_response]
        if response[:errors].present?
          error = response[:errors]
        end
      rescue RestClient::ExceptionWithResponse => e
        error = e.response.present? ? e.to_s + e.response : e.to_s
        ExceptionNotifier.notify_exception(error)
        ApiLog.create_api_log(options[:url], options[:payload], nil, error, HealthProApi::SYSTEM)
        Rails.logger.info(error)
        Rails.logger.info(e.class)
        Rails.logger.info(e.backtrace.join("\n"))
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        ApiLog.create_api_log(options[:url], options[:payload], nil, e.message, HealthProApi::SYSTEM)
        error = e
        Rails.logger.info(e.class)
        Rails.logger.info(e.message)
        Rails.logger.info(e.backtrace.join("\n"))
      end

      { response: response, error: error }
    end
end
