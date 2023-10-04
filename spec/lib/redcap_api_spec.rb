require 'rails_helper'
require 'redcap_api'

RSpec.describe RedcapApi do
  before(:each) do
    @patient_1 = FactoryBot.create(:patient, record_id: '1', first_name: 'Little', last_name: 'My', email: 'little.my@moomin.com')
    @patient_2 = FactoryBot.create(:patient, record_id: '2', first_name: 'The', last_name: 'Groke', email: 'the.groke@moomin.com')
    @invitation_code_1 = FactoryBot.create(:invitation_code, code: '1A')
    @invitation_code_2 = FactoryBot.create(:invitation_code, code: '2B')
    FactoryBot.create(:api_token, api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP, token: 'foo')
    @api_token = ApiToken.where(api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP).first
    @record_id = '5'

    WebMock.enable!
@pending_invitation_code_assignments = <<END_OF_STRING
[{"record_id":"#{@record_id}","first_name":"Paul","last_name":"Konerko","email":"paul.konerko@whitesox.com","invitationcode":"","staff_assigned":"","codeassign_notes":"","code_assignment_complete":"0"},{"record_id":"6","first_name":"Ernie","last_name":"Banks","email":"ernie.banks@cubs.com","invitationcode":"","staff_assigned":"","codeassign_notes":"","code_assignment_complete":"0"}]
END_OF_STRING

@patient = <<END_OF_STRING
[{"record_id":"#{@record_id}","first_name":"Paul","last_name":"Konerko","email":"paul.konerko@whitesox.com","phone_1":"(312) 925-3268","phone1_type":"1","referralsource":"1","other_referral":"","preferred_contact":"1","preferred_time___1":"1","preferred_time___2":"0","preferred_time___3":"0","preferred_time___4":"0","preferred_time_oth":"","how_to_join_complete":"2"}]
END_OF_STRING

@duplicate_patients = <<END_OF_STRING
[{"record_id":"#{@record_id}","first_name":"Paul","last_name":"Konerko","email":"paul.konerko@whitesox.com","phone_1":"(312) 925-3268","phone1_type":"1","referralsource":"1","other_referral":"","preferred_contact":"1","preferred_time___1":"1","preferred_time___2":"0","preferred_time___3":"0","preferred_time___4":"0","preferred_time_oth":"","how_to_join_complete":"2"},{"record_id":"#{@record_id}","first_name":"Paul","last_name":"Konerko","email":"paul.konerko@whitesox.com","phone_1":"(312) 925-3268","phone1_type":"1","referralsource":"1","other_referral":"","preferred_contact":"1","preferred_time___1":"1","preferred_time___2":"0","preferred_time___3":"0","preferred_time___4":"0","preferred_time_oth":"","how_to_join_complete":"2"}]
END_OF_STRING

@assign_invitation_code_response = <<END_OF_STRING
{"count": 1}
END_OF_STRING
  end

  after(:each) do
    WebMock.disable!
  end

  it 'returns pending invitation code assignments', focus: false do
    redcap_api = RedcapApi.new(@api_token.token)

    WebMock.stub_request(:post, Rails.configuration.custom.app_config['redcap']['test']['host_url']).
           with(body: {"content"=>"record", "fields"=>["email", "first_name", "last_name", "record_id"], "filterLogic"=>"([invitationcode]=\"\") AND ([code_assignment_complete]=\"0\")", "format"=>"json", "forms"=>["code_assignment"], "returnFormat"=>"json", "token"=> @api_token.token, "type"=>"flat"}).
       to_return(status: 200, body: @pending_invitation_code_assignments, headers: {})


    pending_invitation_code_assignments = JSON.parse(@pending_invitation_code_assignments)
    expect(redcap_api.pending_invitation_code_assignments).to eq({ response: pending_invitation_code_assignments, error: nil })
  end

  it 'returns a patient', focus: false do
    redcap_api = RedcapApi.new(@api_token.token)
    WebMock.stub_request(:post, Rails.configuration.custom.app_config['redcap']['test']['host_url']).
      with(body: {"content"=>"record", "format"=>"json", "forms"=>["how_to_join"], "records"=>["#{@record_id}"], "returnFormat"=>"json", "token"=>@api_token.token, "type"=>"flat"}).
      to_return(status: 200, body: @patient, headers: {})

    patient = JSON.parse(@patient)
    patient = patient.first
    expect(redcap_api.patient(@record_id)).to eq({ response: patient, error: nil })
  end

  it 'raises an error if it returns duplicate patients', focus: false do
    redcap_api = RedcapApi.new(@api_token.token)
    WebMock.stub_request(:post, Rails.configuration.custom.app_config['redcap']['test']['host_url']).
      with(body: {"content"=>"record", "format"=>"json", "forms"=>["how_to_join"], "records"=>["#{@record_id}"], "returnFormat"=>"json", "token"=>@api_token.token, "type"=>"flat"}).
      to_return(status: 200, body: @duplicate_patients, headers: {})

    patient = JSON.parse(@duplicate_patients)
    patient = patient.first
    expect(redcap_api.patient(@record_id)).to eq({ response: nil, error: RedcapApi::ERROR_MESSAGE_DUPLICATE_PATIENT })
  end

  it 'assigns an invitation code', focus: false do
    redcap_api = RedcapApi.new(@api_token.token)

    WebMock.stub_request(:post, Rails.configuration.custom.app_config['redcap']['test']['host_url']).
      with(body: {"content"=>"record", "data"=>"record_id,invitationcode,code_assignment_complete\n\"#{@record_id}\",\"#{@invitation_code_1.code}\",\"2\"", "format"=>"csv", "overwriteBehavior"=>"overwrite", "returnContent"=>"count", "returnFormat"=>"json", "token"=>"foo", "type"=>"flat"}).
      to_return(status: 200, body: @assign_invitation_code_response, headers: {})

    assign_invitation_code_response = JSON.parse(@assign_invitation_code_response)
    expect(redcap_api.assign_invitation_code(@record_id, @invitation_code_1.code)).to eq({ response: assign_invitation_code_response, error: nil })
  end
end
