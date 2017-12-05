require 'rails_helper'
require 'active_support'

RSpec.describe Patient, type: :model do
  it { should have_many :invitation_code_assignments }

  before(:each) do
    @patient_1 = FactoryGirl.create(:patient, record_id: '1', first_name: 'Little', last_name: 'My', email: 'little.my@moomin.com')
    @patient_2 = FactoryGirl.create(:patient, record_id: '2', first_name: 'The', last_name: 'Groke', email: 'the.groke@moomin.com')
    @invitation_code_1 = FactoryGirl.create(:invitation_code, code: '1A')
    @invitation_code_2 = FactoryGirl.create(:invitation_code, code: '2B')
  end

  it 'can search across fields (by first_name)', focus: false do
    expect(Patient.search_across_fields('Little')).to match_array([@patient_1])
  end

  it 'can search across fields (by first_name) case insensitively', focus: false do
    expect(Patient.search_across_fields('little')).to match_array([@patient_1])
  end

  it 'can search across fields (and sort ascending/descending by a passed in column first_name)', focus: false do
    expect(Patient.search_across_fields(nil, { sort_column: 'first_name', sort_direction: 'asc' })).to eq([@patient_1, @patient_2])
    expect(Patient.search_across_fields(nil, { sort_column: 'first_name', sort_direction: 'desc' })).to eq([@patient_2, @patient_1])
  end

  it 'can search across fields (by last_name)', focus: false do
    expect(Patient.search_across_fields('My')).to match_array([@patient_1])
  end

  it 'can search across fields (by last_name) case insensitively', focus: false do
    expect(Patient.search_across_fields('my')).to match_array([@patient_1])
  end

  it 'can search across fields (and sort ascending/descending by a passed in column last_name)', focus: false do
    expect(Patient.search_across_fields(nil, { sort_column: 'last_name', sort_direction: 'asc' })).to eq([@patient_2, @patient_1])
    expect(Patient.search_across_fields(nil, { sort_column: 'last_name', sort_direction: 'desc' })).to eq([@patient_1, @patient_2])
  end

  it 'can search across fields (by email)', focus: false do
    expect(Patient.search_across_fields('little.my@moomin.com')).to match_array([@patient_1])
  end

  it 'can search across fields (by email) case insensitively', focus: false do
    expect(Patient.search_across_fields('LITTLE.MY@MOOMIN.COM')).to match_array([@patient_1])
  end

  it 'can search across fields (and sort ascending/descending by a passed in column email)', focus: false do
    expect(Patient.search_across_fields(nil, { sort_column: 'email', sort_direction: 'asc' })).to eq([@patient_1, @patient_2])
    expect(Patient.search_across_fields(nil, { sort_column: 'email', sort_direction: 'desc' })).to eq([@patient_2, @patient_1])
  end

  it 'can search across fields (by record_id)', focus: false do
    expect(Patient.search_across_fields('2')).to match_array([@patient_2])
  end

  it 'can search across fields (and sort ascending/descending by a passed in column record_id)', focus: false do
    expect(Patient.search_across_fields(nil, { sort_column: 'email', sort_direction: 'asc' })).to eq([@patient_1, @patient_2])
    expect(Patient.search_across_fields(nil, { sort_column: 'email', sort_direction: 'desc' })).to eq([@patient_2, @patient_1])
  end

  it "can present a patients's full name", focus: false do
    expect(@patient_1.full_name).to eq('Little My')
  end

  it 'can emit its active invitation code', focus: false do
    invitation_code_assignment_1 = InvitationCodeAssignment.create(invitation_code: @invitation_code_1, patient: @patient_1)
    invitation_code_assignment_2 = InvitationCodeAssignment.create(invitation_code: @invitation_code_2, patient: @patient_1)
    expect(@patient_1.invitation_code).to eq(@invitation_code_2.code)
  end
end