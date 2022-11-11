# scp -r ~/hold/STU00204480_subjects.csv all-of-us-helper-deployer@vfsmnubicapps01.fsm.northwestern.edu:/var/www/apps/all-of-us-helper/current/lib/setup/data/
# scp -r ~/hold/STU00204480_activities.csv all-of-us-helper-deployer@vfsmnubicapps01.fsm.northwestern.edu:/var/www/apps/all-of-us-helper/current/lib/setup/data/

#1 RAILS_ENV=production bundle exec rake ehr531:compare_healthpro_to_study_tracker
#2  bundle exec rake ehr531:prepare_submission
#3  bundle exec rake ehr531:process_detail_manual_validation_status

# select
#       p.person_source_value
#     , pn.last_name
#     , pn.middle_name
#     , pn.first_name
#     , p.birth_datetime
#     , p.gender_source_value
#     , pmrn.health_system
#     , pmrn.mrn
#     , pmd.id
#     , pmd.health_pro_column
#     , pmd.health_pro_value
#     , pmd.omop_column
#     , pmd.omop_value
#     , pmd.match_status
#     , pmd.manual_validation_status
# from submissions s  join participant_matches pm on s.id = pm.submission_id
#                     join participant_match_details pmd on pm.id = participant_match_id
#                     join cdm.person p ON pm.person_id = p.person_id
#                     join cdm.pii_name pn ON  pm.person_id = pn.person_id
#                     join cdm.pii_mrn pmrn ON pm.person_id = pmrn.person_id
# where s.id = ?
# and pm.algorithm_validation = 'no'
# and pmd.match_status = 'no_match'
# and pm.manual_validation = 'undetermined'
# and pmd.manual_validation_status = 'undetermined'
# order by pm.person_id
#
# update participant_match_details
# set manual_validation_status = 'rejected'
# where id in(
# ?
# )
#
# update participant_match_details
# set manual_validation_status = 'accepted'
# where id in(
# ?
# )
#
# select pmd.*
# from submissions s join participant_matches pm on s.id = pm.submission_id
#                    join participant_match_details pmd on pm.id = participant_match_id
# where s.id = ?
# and pm.algorithm_validation = 'no'
# and pmd.match_status = 'no_match'
# and pmd.manual_validation_status = 'undetermined'
# order by pm.person_id

#4  bundle exec rake ehr531:process_manual_validation_status
#5  bundle exec rake ehr531:submission_report
#6  bundle exec rake ehr531:create_submission
#7  bundle exec rake ehr531:create_participant_match
require 'csv'
namespace :ehr531 do
  desc 'Compare HealthPro to StudyTracker'
  task(compare_healthpro_to_study_tracker: :environment) do  |t, args|
    batch_health_pro_ids =[BatchHealthPro.maximum(:id)]
    subjects = []
    subject_template = { source: nil, pmi_id: nil, biospecimens_location: nil, general_consent_status: nil, general_consent_date: nil, general_consent_status_st: nil, general_consent_date_st: nil,  ehr_consent_status: nil, ehr_consent_date: nil, ehr_consent_status_st: nil, ehr_consent_date_st: nil, withdrawal_status: nil, withdrawal_date: nil, withdrawal_status_st: nil, withdrawal_date_st: nil, nmhc_mrn: nil, status: nil, participant_status: nil }
    st_subjects = CSV.new(File.open('lib/setup/data/STU00204480_subjects.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    pmi_ids = st_subjects.map { |subject| subject.to_hash['case number']  }

    study_tracker_activities = CSV.new(File.open('lib/setup/data/STU00204480_activities.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    study_tracker_activities = study_tracker_activities.to_a
    # batch_health_pro = BatchHealthPro.last
    health_pros = HealthPro.where(batch_health_pro_id: batch_health_pro_ids)
    health_pros.where("pmi_id in (?)", pmi_ids).each do |health_pro|
      puts 'hello'
      puts 'here is the pmi_id'
      puts health_pro.pmi_id
    # batch_health_pro.health_pros.where("pmi_id in (?)", pmi_ids).each do |health_pro|
    # batch_health_pro.health_pros.where("pmi_id in (?) AND biospecimens_location = ? AND general_consent_status = '1' AND general_consent_date IS NOT NULL AND ehr_consent_status = '1' AND ehr_consent_date IS NOT NULL AND withdrawal_status = '0' AND withdrawal_date IS NULL", 'nwfeinberggalter').each do |health_pro|

      study_tracker_activities_by_case_number = study_tracker_activities.select { |study_tracker_activity| study_tracker_activity.to_hash['case number'] ==  health_pro.pmi_id }
      subject = subject_template.dup
      subject[:source] = 'HealthPro'
      subject[:pmi_id] = health_pro.pmi_id
      subject[:participant_status] = health_pro.participant_status
      subject[:biospecimens_location] = health_pro.biospecimens_location

      subject[:general_consent_status] = health_pro.general_consent_status
      subject[:general_consent_date] = Date.parse(health_pro.general_consent_date) if health_pro.general_consent_date.present?

      study_tracker_activities_by_case_number.each do |study_tracker_activity|
        puts 'activity_name'
        puts study_tracker_activity.to_hash['activity_name']
        puts 'activity_date'
        puts study_tracker_activity.to_hash['activity_date']
        puts 'activity_state'
        puts study_tracker_activity.to_hash['activity_state']
      end

      study_tracker_activity_consented = study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'Consented' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.max_by { |study_tracker_activity| Date.parse(study_tracker_activity.to_hash['activity_date']) }
      if study_tracker_activity_consented
        subject[:nmhc_mrn] = study_tracker_activity_consented.to_hash['nmhc_record_number']
        subject[:general_consent_status_st] = '1'
        subject[:general_consent_date_st] = Date.parse(study_tracker_activity_consented.to_hash['activity_date'])
      else
        subject[:general_consent_status_st] = '0'
      end

      subject[:ehr_consent_status] = health_pro.ehr_consent_status
      subject[:ehr_consent_date] = Date.parse(health_pro.ehr_consent_date) if health_pro.ehr_consent_date
      study_tracker_activity_ehr_consent = study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'EHR Consent' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.max_by { |study_tracker_activity| Date.parse(study_tracker_activity.to_hash['activity_date']) }
      if study_tracker_activity_ehr_consent
        subject[:ehr_consent_status_st] = '1'
        subject[:ehr_consent_date_st] = Date.parse(study_tracker_activity_ehr_consent.to_hash['activity_date'])
      else
        subject[:ehr_consent_status_st] = '0'
      end

      subject[:withdrawal_status] = health_pro.withdrawal_status
      subject[:withdrawal_date] = Date.parse(health_pro.withdrawal_date) if health_pro.withdrawal_date
      study_tracker_activity_withdrawal = study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'Withdrawn' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.first
      if study_tracker_activity_withdrawal
        subject[:withdrawal_status_st] = '1'
        subject[:withdrawal_date_st] = Date.parse(study_tracker_activity_withdrawal.to_hash['activity_date']) if study_tracker_activity_withdrawal.to_hash['activity_date']
      else
        subject[:withdrawal_status_st] = '0'
      end

      # if subject[:general_consent_status] == subject[:general_consent_status_st] &&
      #    subject[:general_consent_date] == subject[:general_consent_date_st] &&
      #    subject[:ehr_consent_status] == subject[:ehr_consent_status_st] &&
      #    subject[:ehr_consent_date] == subject[:ehr_consent_date_st] &&
      #    subject[:withdrawal_status] == subject[:withdrawal_status_st] &&
      #    subject[:withdrawal_date] == subject[:withdrawal_date_st]

      if match_status_general_ehr(subject[:general_consent_status], subject[:general_consent_date], subject[:general_consent_status_st], subject[:general_consent_date_st]) &&
         subject[:general_consent_date] == subject[:general_consent_date_st] &&
         match_status_general_ehr(subject[:ehr_consent_status], subject[:ehr_consent_date], subject[:ehr_consent_status_st], subject[:ehr_consent_date_st]) &&
         subject[:ehr_consent_date] == subject[:ehr_consent_date_st] &&
         match_status_withdrawal(subject[:withdrawal_status], subject[:withdrawal_date],subject[:withdrawal_status_st], subject[:withdrawal_date_st]) &&
         subject[:withdrawal_date] == subject[:withdrawal_date_st]

         subject[:status] = 'matches'
         puts 'we got a match'
       else
         puts 'we got a mismatch'
         puts 'begin'
         puts 'general_consent_status'
         puts subject[:general_consent_status]
         puts subject[:general_consent_status_st]

         puts 'general_consent_date'
         puts subject[:general_consent_date]
         puts subject[:general_consent_date_st]

         puts 'ehr_consent_status'
         puts subject[:ehr_consent_status]
         puts subject[:ehr_consent_status_st]

         puts 'ehr_consent_date'
         puts subject[:ehr_consent_date]
         puts subject[:ehr_consent_date_st]

         puts 'withdrawal_status'
         puts subject[:withdrawal_status]
         puts subject[:withdrawal_status_st]

         puts 'withdrawal_date'
         puts subject[:withdrawal_date]
         puts subject[:withdrawal_date_st]

         puts 'end'

         if match_status_general_ehr(subject[:general_consent_status], subject[:general_consent_date], subject[:general_consent_status_st], subject[:general_consent_date_st]) &&
            match_status_general_ehr(subject[:ehr_consent_status], subject[:ehr_consent_date], subject[:ehr_consent_status_st], subject[:ehr_consent_date_st]) &&
            match_status_withdrawal(subject[:withdrawal_status], subject[:withdrawal_date],subject[:withdrawal_status_st], subject[:withdrawal_date_st])

            subject[:status] = 'matches'
          else
            subject[:status] = 'mismatches'
          end
       end
       puts 'Stay alive!'
       puts BatchHealthPro.count
      subjects << subject
    end

    study_tracker_activities_by_case_number  = CSV.new(File.open('lib/setup/data/STU00204480_activities.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    study_tracker_activities_by_case_number = study_tracker_activities_by_case_number.reject { |study_tracker_activity| subjects.detect { |subject| subject[:pmi_id] == study_tracker_activity.to_hash['case number'] } }
    case_numbers = study_tracker_activities_by_case_number.map { |study_tracker_activity| study_tracker_activity.to_hash['case number'] }.uniq

    case_numbers.each do |case_number|
      case_number_study_tracker_activities_by_case_number = study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['case number'] == case_number }
      health_pro = health_pros.where(pmi_id: case_number).first

      subject = subject_template.dup
      subject[:source] = 'StudyTracker'
      subject[:pmi_id] = case_number
      subject[:participant_status] = health_pro.participant_status if health_pro
      subject[:biospecimens_location] = health_pro.biospecimens_location if health_pro

      subject[:general_consent_status] = health_pro.general_consent_status if health_pro
      subject[:general_consent_date] = Date.parse(health_pro.general_consent_date) if health_pro && health_pro.general_consent_date
      study_tracker_activity_consented = case_number_study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'Consented' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.first
      if study_tracker_activity_consented
        subject[:nmhc_mrn] = study_tracker_activity_consented.to_hash['nmhc_record_number']
        subject[:general_consent_status_st] = '1'
        subject[:general_consent_date_st] = Date.parse(study_tracker_activity_consented.to_hash['activity_date']) if study_tracker_activity_consented.to_hash['activity_date']
      else
        subject[:general_consent_status_st] = '0'
      end

      subject[:ehr_consent_status] = health_pro.ehr_consent_status if health_pro
      subject[:ehr_consent_date] = Date.parse(health_pro.ehr_consent_date) if health_pro && health_pro.ehr_consent_date
      study_tracker_activity_ehr_consent = case_number_study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'EHR Consent' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.first
      if study_tracker_activity_ehr_consent
        subject[:ehr_consent_status_st] = '1'
        subject[:ehr_consent_date_st] = Date.parse(study_tracker_activity_ehr_consent.to_hash['activity_date']) if study_tracker_activity_ehr_consent.to_hash['activity_date']
      else
        subject[:ehr_consent_status_st] = '0'
      end

      subject[:withdrawal_status] = health_pro.withdrawal_status if health_pro
      subject[:withdrawal_date] = Date.parse(health_pro.withdrawal_date) if health_pro && health_pro.withdrawal_date
      study_tracker_activity_withdrawal = case_number_study_tracker_activities_by_case_number.select { |study_tracker_activity| study_tracker_activity.to_hash['activity_name'] == 'Withdrawn' && study_tracker_activity.to_hash['activity_date'].present? &&  study_tracker_activity.to_hash['activity_state'] == 'completed' }.first
      if study_tracker_activity_withdrawal
        subject[:withdrawal_status_st] = '1'
        subject[:withdrawal_date_st] = Date.parse(study_tracker_activity_withdrawal.to_hash['activity_date']) if study_tracker_activity_withdrawal.to_hash['activity_date']
      else
        subject[:withdrawal_status_st] = '0'
      end

      if match_status_general_ehr(subject[:general_consent_status], subject[:general_consent_date], subject[:general_consent_status_st], subject[:general_consent_date_st]) &&
         match_status_general_ehr(subject[:ehr_consent_status], subject[:ehr_consent_date], subject[:ehr_consent_status_st], subject[:ehr_consent_date_st]) &&
         match_status_withdrawal(subject[:withdrawal_status], subject[:withdrawal_date] , subject[:withdrawal_status_st], subject[:withdrawal_date_st])
         subject[:status] = 'matches'
       else
         subject[:status] = 'mismatches'
       end

      subjects << subject
    end

    headers = subject_template.keys
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    CSV.open('lib/setup/data_out/subjects.csv', "wb") do |csv|
      csv << row_header
      subjects.each do |subject|
        row = row_template.dup
        row[:source] = subject[:source]
        row[:pmi_id] = subject[:pmi_id]
        row[:status] = subject[:status]
        row[:participant_status] = subject[:participant_status]

        row[:nmhc_mrn] = subject[:nmhc_mrn]
        row[:biospecimens_location] = subject[:biospecimens_location]

        row[:general_consent_status] = subject[:general_consent_status]
        row[:general_consent_date] = subject[:general_consent_date]
        row[:general_consent_status_st] = subject[:general_consent_status_st]
        row[:general_consent_date_st] = subject[:general_consent_date_st]

        row[:ehr_consent_status] = subject[:ehr_consent_status]
        row[:ehr_consent_date] = subject[:ehr_consent_date]
        row[:ehr_consent_status_st] = subject[:ehr_consent_status_st]
        row[:ehr_consent_date_st] = subject[:ehr_consent_date_st]

        row[:withdrawal_status] = subject[:withdrawal_status]
        row[:withdrawal_date] = subject[:withdrawal_date]
        row[:withdrawal_status_st] = subject[:withdrawal_status_st]
        row[:withdrawal_date_st] = subject[:withdrawal_date_st]
        csv << row
      end
    end
  end

  desc "Prepare Submission"
  task(prepare_submission: :environment) do  |t, args|
    batch_health_pro_ids =[BatchHealthPro.maximum(:id)]
    submissions = Submission.where(submitted_at: Date.today)

    if submissions.blank?
      version = 1
      submission = Submission.create(submitted_at: Date.today, version: version)
    else
      version = Submission.where(submitted_at: Date.today).maximum(:version)
      version += 1
      submission = Submission.create(submitted_at: Date.today, version: version)
    end

    batch_health_pro_ids.each do |batch_health_pro_id|
      submission.submission_batch_health_pros.build(batch_health_pro_id: batch_health_pro_id)
    end

    submission.save!
    pmi_ids = []
    submission.submission_batch_health_pros.each do |submission_batch_health_pro|
      pmi_ids.concat(submission_batch_health_pro.batch_health_pro.health_pros.where(deactivation_status: '0', withdrawal_status: '0', participant_status: HealthPro::HEALTH_PRO_PARTICIPANT_STATUS_CORE_PARTICIPANT, biospecimens_location: HealthPro::BIOSPECIMEN_LOCATIONS, general_consent_status: '1', ehr_consent_status: '1').map(&:pmi_id))
    end
    person_ids = Person.where(person_source_value: pmi_ids).map(&:person_id)

    puts 'how many people'
    puts person_ids.size
    person_ids.each_with_index do |person_id, i|
      puts 'we are on person'
      puts i
      puts person_id
      person = Person.where(person_id: person_id).first
      pii_name = PiiName.where(person_id: person_id).first
      health_pro = HealthPro.where(batch_health_pro_id: batch_health_pro_ids, pmi_id: "P#{person_id}").first

      puts person.year_of_birth
      puts person.month_of_birth
      puts person.day_of_birth
      birth_date = Date.new(person.year_of_birth, person.month_of_birth, person.day_of_birth)
      if health_pro.first_name.downcase.strip == pii_name.first_name.downcase.strip && health_pro.last_name.downcase.strip == pii_name.last_name.downcase.strip && Date.parse(health_pro.date_of_birth).to_s == birth_date.to_s
        participant_match = ParticipantMatch.create!(submission_id: submission.id, person_id: person_id, first_name: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, last_name: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, dob: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, sex: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, address: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, phone_number: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, email: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, algorithm_validation: ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_YES, manual_validation: ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_NO)
        participant_match.participant_match_details.build(health_pro_column: 'health_pros.first_name', health_pro_value: health_pro.first_name.downcase.strip, omop_column: 'pii.first_name' , omop_value: pii_name.first_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        participant_match.participant_match_details.build(health_pro_column: 'health_pros.last_name', health_pro_value: health_pro.last_name.downcase.strip, omop_column: 'pii.last_name' , omop_value: pii_name.last_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        participant_match.participant_match_details.build(health_pro_column: 'health_pros.date_of_birth', health_pro_value: Date.parse(health_pro.date_of_birth).to_s, omop_column: 'person.year_of_birth,person.month_of_birth,person.day_of_birth', omop_value: Date.new(person.year_of_birth, person.month_of_birth, person.day_of_birth).to_s, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        participant_match.save!

        puts 'we have a match!'
      else
        participant_match = ParticipantMatch.create!(submission_id: submission.id, person_id: person_id, first_name: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, last_name: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, dob: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_MATCH, sex: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, address: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, phone_number: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, email: ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_EXCLUDED, algorithm_validation: ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_NO, manual_validation: ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_UNDETERMINED)

        if health_pro.first_name.downcase.strip != pii_name.first_name.downcase.strip
          participant_match.first_name = ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_NO_MATCH
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.first_name', health_pro_value: health_pro.first_name.downcase.strip, omop_column: 'pii.first_name' , omop_value: pii_name.first_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_NO_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_UNDETERMINED)
        else
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.first_name', health_pro_value: health_pro.first_name.downcase.strip, omop_column: 'pii.first_name' , omop_value: pii_name.first_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        end

        if health_pro.last_name.downcase.strip != pii_name.last_name.downcase.strip
          participant_match.last_name = ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_NO_MATCH
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.last_name', health_pro_value: health_pro.last_name.downcase.strip, omop_column: 'pii.last_name' , omop_value: pii_name.last_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_NO_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_UNDETERMINED)
        else
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.last_name', health_pro_value: health_pro.last_name.downcase.strip, omop_column: 'pii.last_name' , omop_value: pii_name.last_name.downcase.strip, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        end

        if Date.parse(health_pro.date_of_birth).to_s != birth_date.to_s
          participant_match.dob = ParticipantMatch::PARTICIPANT_MATCH_DETERMINATION_NO_MATCH
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.date_of_birth', health_pro_value: Date.parse(health_pro.date_of_birth).to_s, omop_column: 'person.year_of_birth,person.month_of_birth,person.day_of_birth', omop_value: Date.new(person.year_of_birth, person.month_of_birth, person.day_of_birth).to_s, match_status: ParticipantMatchDetail::MATCH_STATUS_NO_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_UNDETERMINED)
        else
          participant_match.participant_match_details.build(health_pro_column: 'health_pros.date_of_birth', health_pro_value: Date.parse(health_pro.date_of_birth).to_s, omop_column: 'person.year_of_birth,person.month_of_birth,person.day_of_birth', omop_value: Date.new(person.year_of_birth, person.month_of_birth, person.day_of_birth).to_s, match_status: ParticipantMatchDetail::MATCH_STATUS_MATCH, manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE)
        end

        participant_match.save!

        puts 'we have a mismatch!'
        puts "P#{person_id}"
        puts "HealthPro: #{health_pro.first_name.downcase.strip} | OMOP: #{pii_name.first_name.downcase.strip}"
        puts "HealthPro: #{health_pro.last_name.downcase.strip} | OMOP: #{pii_name.last_name.downcase.strip}"
        puts "HealthPro: #{Date.parse(health_pro.date_of_birth).to_s} | OMOP: #{birth_date.to_s}"
      end
    end
  end

  desc "Process detail manual validation status "
  task(process_detail_manual_validation_status: :environment) do  |t, args|
    last_submission_id = Submission.maximum(:id)
    prior_submission_id = Submission.where('id != ?', last_submission_id).maximum(:id)
    submission = Submission.find(last_submission_id)
    if prior_submission_id
      prior_submission = Submission.find(prior_submission_id)

      undetermined_participant_matches = submission.participant_matches.where(manual_validation: ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_UNDETERMINED)
      undetermined_participant_matches.each do |undetermined_participant_match|
        undetermined_participant_match.participant_match_details.where(manual_validation_status: ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_UNDETERMINED).each do |participant_match_detail|
          prior_participant_match = prior_submission.participant_matches.where(person_id: undetermined_participant_match.person_id).first
          if prior_participant_match
            look = prior_participant_match.participant_match_details.where(health_pro_column: participant_match_detail.health_pro_column, health_pro_value: participant_match_detail.health_pro_value, omop_column: participant_match_detail.omop_column, omop_value: participant_match_detail.omop_value, manual_validation_status: [ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_ACCEPTED, ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_PREVIOUSLY_ACCEPTED]).count
            puts look
            if look == 1
              puts 'we got you!'
              participant_match_detail.manual_validation_status = ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_PREVIOUSLY_ACCEPTED
              participant_match_detail.save!
            else
              puts 'no such luck!'
            end
          end
        end
      end
    end
  end

  desc "Process manual validation status"
  task(process_manual_validation_status: :environment) do  |t, args|
    last_submission_id = Submission.maximum(:id)
    submission = Submission.find(last_submission_id)

    undetermined_participant_matches = submission.participant_matches.where(manual_validation: ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_UNDETERMINED)
    undetermined_participant_matches.each do |undetermined_participant_match|
      if undetermined_participant_match.participant_match_details.map(&:manual_validation_status).include?(ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_REJECTED)
        undetermined_participant_match.manual_validation = ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_NO
      elsif undetermined_participant_match.participant_match_details.map(&:manual_validation_status).include?(ParticipantMatchDetail::MANUAL_VALIDATION_STATUS_UNDETERMINED)
        undetermined_participant_match.manual_validation = undetermined_participant_match.manual_validation
      else
        undetermined_participant_match.manual_validation = ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_YES
      end
      undetermined_participant_match.save
    end
  end

  desc "Submission Report"
  task(submission_report: :environment) do  |t, args|
    submission = Submission.find(Submission.maximum(:id))
    batch_health_pro_ids = submission.submission_batch_health_pros.map(&:batch_health_pro_id)
    health_pros = HealthPro.where(batch_health_pro_id: batch_health_pro_ids, participant_status: HealthPro::HEALTH_PRO_PARTICIPANT_STATUS_CORE_PARTICIPANT, deactivation_status: '0', withdrawal_status: '0',  biospecimens_location: HealthPro::BIOSPECIMEN_LOCATIONS, general_consent_status: '1', ehr_consent_status: '1').all

    pmi_ids = submission.participant_matches.where('algorithm_validation = ? OR manual_validation = ?', ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_YES, ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_YES).map{ |participant_match| "P#{participant_match.person_id}"}
    mismatch_pmi_ids = submission.participant_matches.where('algorithm_validation = ? AND manual_validation = ?', ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_NO, ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_NO).map { |participant_match| "P#{participant_match.person_id}"}
    submitted_pmi_ids = Person.where('trim(person_source_value) in(?)', pmi_ids).map(&:person_source_value)

    headers = ['pmi_id','status']
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    CSV.open("lib/setup/data_out/submission_report#{DateTime.now.iso8601.gsub(':','-')}.csv", "wb", force_quotes: true) do |csv|
      csv << row_header
      health_pros.each do |health_pro|
        row = row_template.dup
        if submitted_pmi_ids.include?(health_pro.pmi_id)
          row['pmi_id'] = health_pro.pmi_id
          row['status'] = 'submitted'
        else
          subjects = CSV.new(File.open('lib/setup/data/STU00204480_subjects.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
          subject = subjects.select { |subject| subject.to_hash['case number'].strip == health_pro.pmi_id  }.first

          if subject.nil?
            row['pmi_id'] = health_pro.pmi_id
            row['status'] = 'not entered into Study Tracker'
          elsif Date.parse(health_pro.ehr_consent_date) >= Date.parse('4/24/2018') && Date.parse(health_pro.ehr_consent_date) <= Date.parse('6/7/2018')
            row['pmi_id'] = health_pro.pmi_id
            row['status'] = 'not submitted because in the dark age'
          elsif mismatch_pmi_ids.include?(health_pro.pmi_id)
            row['pmi_id'] = health_pro.pmi_id
            row['status'] = 'not submitted because of mismatch'
          elsif subject.to_hash['nmhc_record_number'].blank?
            row['pmi_id'] = health_pro.pmi_id
            row['status'] = 'not submitted because no NMHC mrn in Study Tracker'
          else
            row['pmi_id'] = health_pro.pmi_id
            row['status'] = 'not submitted'
          end
        end
        csv << row
      end
    end
  end

  desc "Create submission"
  task(create_submission: :environment) do  |t, args|
    puts '1'
    submission = Submission.find(Submission.maximum(:id))
    puts '2'
    person_ids = submission.participant_matches.where('algorithm_validation = ? OR manual_validation = ?', ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_YES, ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_YES).map{ |participant_match| participant_match.person_id}
    puts '3'
    dir = "#{Rails.root}/lib/setup/data_out/#{submission.submitted_at}-v#{submission.version}"
    Dir.mkdir dir

    if submission.submission_persons.empty?
      puts '4'
      person_ids.each do |person_id|
        submission.submission_persons.build(person_id: person_id)
      end
      submission.save!
    end

    puts '5'
    child_pid = fork do
      puts 'PERSON'
      submission.submission_tables.build(table_name: Person.table_name)
      persons = Person.where(person_id: person_ids)
      headers = Person.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/person.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Person.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys

        persons.each do |person|
          # puts i
          row = row_template.dup
          attributes.each do |attribute|
            if person[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = person[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'VISIT_DETAIL'
      submission.submission_tables.build(table_name: VisitDetail.table_name)
      visit_details = VisitDetail.where(person_id: person_ids)
      headers = VisitDetail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/visit_detail.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = VisitDetail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        visit_details.each do |visit_detail|
          row = row_template.dup
          attributes.each do |attribute|
            if visit_detail[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = visit_detail[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'VISIT_DETAIL'
      submission.submission_tables.build(table_name: VisitDetail.table_name)
      headers = VisitDetail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/visit_detail.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = VisitDetail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          VisitDetail.where(person_id: person_id).each do |visit_detail|
            row = row_template.dup
            attributes.each do |attribute|
              if visit_detail[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = visit_detail[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'VISIT_OCCURRENCE'
      submission.submission_tables.build(table_name: VisitOccurrence.table_name)
      headers = VisitOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/visit_occurrence.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = VisitOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          VisitOccurrence.where(person_id: person_id).each do |visit_occurrence|
            row = row_template.dup
            attributes.each do |attribute|
              if visit_occurrence[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = visit_occurrence[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'CONDITION_OCCURRENCE'
      submission.submission_tables.build(table_name: ConditionOccurrence.table_name)
      #MGURLEY 9/11/2019 Datetime fix
      # headers = ConditionOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      headers =  ['condition_occurrence_id', 'person_id', 'condition_concept_id', 'condition_start_date', 'condition_start_datetime', 'condition_end_date', 'condition_end_datetime', 'condition_type_concept_id', 'condition_status_concept_id', 'stop_reason', 'provider_id', 'visit_occurrence_id', 'visit_detail_id', 'condition_source_value', 'condition_source_concept_id', 'condition_status_source_value']
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/condition_occurrence.csv", "wb", force_quotes: true) do |csv|
        csv << row_header

        # attributes = ConditionOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        attributes =['condition_occurrence_id', 'person_id', 'condition_concept_id', 'condition_start_date', 'condition_start_datetime', 'condition_end_date', 'condition_end_datetime', 'condition_type_concept_id', 'condition_status_concept_id', 'stop_reason', 'provider_id', 'visit_occurrence_id', 'visit_detail_id', 'condition_source_value', 'condition_source_concept_id', 'condition_status_source_value']
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          condition_occurrences = ConditionOccurrence.where(person_id: person_id).select('condition_occurrence_id,person_id,condition_concept_id,condition_start_date,condition_start_datetime,condition_end_date,condition_end_datetime,condition_type_concept_id,condition_status_concept_id,stop_reason,provider_id,visit_occurrence_id,visit_detail_id,condition_source_value,condition_source_concept_id,condition_status_source_value').each do |condition_occurrence|
            row = row_template.dup
            attributes.each do |attribute|
              if condition_occurrence[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = condition_occurrence[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'DRUG_EXPOSURE'
      submission.submission_tables.build(table_name: DrugExposure.table_name)
      headers = DrugExposure.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/drug_exposure.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = DrugExposure.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          #MGURLEY 9/11/2019 Datetime fix
          drug_exposures = DrugExposure.where(person_id: person_id).select('drug_exposure_id,person_id,drug_concept_id,drug_exposure_start_date,drug_exposure_start_datetime,drug_exposure_end_date,drug_exposure_end_datetime,verbatim_end_date,drug_type_concept_id,stop_reason,refills,quantity,days_supply,sig,route_concept_id,lot_number,provider_id,visit_occurrence_id,visit_detail_id,drug_source_value,drug_source_concept_id,route_source_value,dose_unit_source_value').each do |drug_exposure|
            row = row_template.dup
            attributes.each do |attribute|
              if drug_exposure[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = drug_exposure[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'MEASUREMENT'
      submission.submission_tables.build(table_name: Measurement.table_name)
      # headers = Measurement.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      headers = ['measurement_id','person_id','measurement_concept_id','measurement_date','measurement_datetime','measurement_time','measurement_type_concept_id','operator_concept_id','value_as_number','value_as_concept_id','unit_concept_id','range_low','range_high','provider_id','visit_occurrence_id','visit_detail_id','measurement_source_value','measurement_source_concept_id','unit_source_value','value_source_value']
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/measurement.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        # attributes = Measurement.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        attributes = ['measurement_id','person_id','measurement_concept_id','measurement_date','measurement_datetime','measurement_time','measurement_type_concept_id','operator_concept_id','value_as_number','value_as_concept_id','unit_concept_id','range_low','range_high','provider_id','visit_occurrence_id','visit_detail_id','measurement_source_value','measurement_source_concept_id','unit_source_value','value_source_value']
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          measurements = Measurement.where(person_id: person_id).select('measurement_id,person_id,measurement_concept_id,measurement_date,measurement_datetime,measurement_time,measurement_type_concept_id,operator_concept_id,value_as_number,value_as_concept_id,unit_concept_id,range_low,range_high,provider_id,visit_occurrence_id,visit_detail_id,measurement_source_value,measurement_source_concept_id,unit_source_value,value_source_value').each do |measurement|
            row = row_template.dup
            attributes.each do |attribute|
              if measurement[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = measurement[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'NOTE'
      submission.submission_tables.build(table_name: Note.table_name)
      #MGURLEY 9/11/2019 Datetime fix
      # notes = Note.where(person_id: person_ids).select('note_id,person_id,note_date,CONVERT(DATETIME,note_date) AS note_datetime,note_type_concept_id,note_class_concept_id,note_title,note_text,encoding_concept_id,language_concept_id,provider_id,visit_occurrence_id,note_source_value')
      headers = Note.new.attributes.to_hash.except('note_time', 'meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/note.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Note.new.attributes.to_hash.except('note_time','meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        person_ids.each_with_index do |person_id, i|
          puts i
          puts person_id
          Note.where(person_id: person_id).select('note_id,person_id,note_date,note_datetime,note_type_concept_id,note_class_concept_id,note_title,note_text,encoding_concept_id,language_concept_id,provider_id,visit_occurrence_id,visit_detail_id,note_source_value').each do |note|
            row = row_template.dup
            attributes.each do |attribute|
              if note[attribute].blank?
                row[attribute] = ""
              else
                row[attribute] = note[attribute]
              end
            end
            csv << row
          end
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PROCEDURE_OCCURRENCE'
      submission.submission_tables.build(table_name: ProcedureOccurrence.table_name)
      #MGURLEY 9/11/2019 Datetime fix
      procedure_occurrences = ProcedureOccurrence.where(person_id: person_ids).select('procedure_occurrence_id,person_id,procedure_concept_id,procedure_date,procedure_datetime,procedure_type_concept_id,modifier_concept_id,quantity,provider_id,visit_occurrence_id,visit_detail_id,procedure_source_value,procedure_source_concept_id,modifier_source_value')
      headers = ProcedureOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/procedure_occurrence.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = ProcedureOccurrence.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        procedure_occurrences.each do |procedure_occurrence|
          row = row_template.dup
          attributes.each do |attribute|
            if procedure_occurrence[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = procedure_occurrence[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'OBSERVATION'
      submission.submission_tables.build(table_name: Observation.table_name)
      observations = Observation.where(person_id: person_ids).select('observation_id,person_id,observation_concept_id,observation_date,observation_datetime,observation_type_concept_id,value_as_number,value_as_string,value_as_concept_id,qualifier_concept_id,unit_concept_id,provider_id,visit_occurrence_id,visit_detail_id,observation_source_value,observation_source_concept_id,unit_source_value,qualifier_source_value')
      headers = Observation.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/observation.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Observation.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        observations.each do |observation|
          row = row_template.dup
          attributes.each do |attribute|
            if observation[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = observation[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'LOCATION'
      submission.submission_tables.build(table_name: Location.table_name)
      locations = Location.all
      headers = Location.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/location.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Location.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        locations.each do |location|
          row = row_template.dup
          attributes.each do |attribute|
            if location[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = location[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PROVIDER'
      submission.submission_tables.build(table_name: Provider.table_name)
      providers = Provider.select('provider_id,provider_name,NPI AS npi,DEA as dea,specialty_concept_id,care_site_id,year_of_birth,gender_concept_id,provider_source_value,specialty_source_value,specialty_source_concept_id,gender_source_value,gender_source_concept_id').all
      # headers = Provider.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      headers =  ["provider_id", "provider_name", "npi", "dea", "specialty_concept_id", "care_site_id", "year_of_birth", "gender_concept_id", "provider_source_value", "specialty_source_value", "specialty_source_concept_id", "gender_source_value", "gender_source_concept_id"]
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/provider.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        # attributes = Provider.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        attributes = ["provider_id", "provider_name", "npi", "dea", "specialty_concept_id", "care_site_id", "year_of_birth", "gender_concept_id", "provider_source_value", "specialty_source_value", "specialty_source_concept_id", "gender_source_value", "gender_source_concept_id"]
        providers.each do |provider|
          row = row_template.dup
          attributes.each do |attribute|
            if provider[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = provider[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'DEVICE_EXPOSURE'
      submission.submission_tables.build(table_name: DeviceExposure.table_name)
      device_exposures = DeviceExposure.where(person_id: person_ids)
      headers = DeviceExposure.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/device_exposure.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = DeviceExposure.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        device_exposures.each do |device_exposure|
          row = row_template.dup
          attributes.each do |attribute|
            if device_exposure[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = device_exposure[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'DEATH'
      submission.submission_tables.build(table_name: Death.table_name)
      deaths = Death.where(person_id: person_ids)
      headers = Death.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/death.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Death.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        deaths.each do |death|
          row = row_template.dup
          attributes.each do |attribute|
            if death[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = death[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'CARE_SITE'
      submission.submission_tables.build(table_name: CareSite.table_name)
      care_sites = CareSite.all
      headers = CareSite.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/care_site.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = CareSite.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        care_sites.each do |care_site|
          row = row_template.dup
          attributes.each do |attribute|
            if care_site[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = care_site[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'FACT_RELATIONSHIP'
      submission.submission_tables.build(table_name: FactRelationship.table_name)
      fact_relationships = FactRelationship.all
      headers = FactRelationship.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/fact_relationship.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = FactRelationship.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        fact_relationships.each do |fact_relationship|
          row = row_template.dup
          attributes.each do |attribute|
            if fact_relationship[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = fact_relationship[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'SPECIMEN'
      submission.submission_tables.build(table_name: Specimen.table_name)
      specimens = Specimen.where(person_id: person_ids)
      headers = Specimen.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/specimen.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = Specimen.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        specimens.each do |specimen|
          row = row_template.dup
          attributes.each do |attribute|
            if specimen[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = specimen[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PII_ADDRESS'
      submission.submission_tables.build(table_name: PiiAddress.table_name)
      pii_addresses = PiiAddress.where(person_id: person_ids)
      headers = PiiAddress.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/pii_address.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = PiiAddress.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        pii_addresses.each do |pii_address|
          row = row_template.dup
          attributes.each do |attribute|
            if pii_address[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = pii_address[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PII_NAME'
      submission.submission_tables.build(table_name: PiiName.table_name)
      pii_names = PiiName.where(person_id: person_ids)
      headers = PiiName.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/pii_name.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = PiiName.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        pii_names.each do |pii_name|
          row = row_template.dup
          attributes.each do |attribute|
            if pii_name[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = pii_name[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PII_EMAIL'
      submission.submission_tables.build(table_name: PiiEmail.table_name)
      pii_emails = PiiEmail.where(person_id: person_ids)
      headers = PiiEmail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/pii_email.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = PiiEmail.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        pii_emails.each do |pii_email|
          row = row_template.dup
          attributes.each do |attribute|
            if pii_email[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = pii_email[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PII_MRN'
      submission.submission_tables.build(table_name: PiiMrn.table_name)
      pii_mrns = PiiMrn.where(person_id: person_ids)
      headers = PiiMrn.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/pii_mrn.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = PiiMrn.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        pii_mrns.each do |pii_mrn|
          row = row_template.dup
          attributes.each do |attribute|
            if pii_mrn[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = pii_mrn[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)

    child_pid = fork do
      puts 'PII_PHONE_NUMBER'
      submission.submission_tables.build(table_name: PiiPhoneNumber.table_name)
      pii_phone_numbers = PiiPhoneNumber.where(person_id: person_ids)
      headers = PiiPhoneNumber.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
      row_header = CSV::Row.new(headers, headers, true)
      row_template = CSV::Row.new(headers, [], false)
      CSV.open("#{dir}/pii_phone_number.csv", "wb", force_quotes: true) do |csv|
        csv << row_header
        attributes = PiiPhoneNumber.new.attributes.to_hash.except('meta_load_exectn_guid', 'meta_orignl_load_dts').keys
        pii_phone_numbers.each do |pii_phone_number|
          row = row_template.dup
          attributes.each do |attribute|
            if pii_phone_number[attribute].blank?
              row[attribute] = ""
            else
              row[attribute] = pii_phone_number[attribute]
            end
          end
          csv << row
        end
      end
    end
    Process.wait(child_pid)
    submission.save!
  end

  desc "Create participant match"
  task(create_participant_match: :environment) do  |t, args|
    submission = Submission.find(Submission.maximum(:id))
    submission.submission_tables.build(table_name: ParticipantMatch.table_name)
    submission.save!
    dir = "#{Rails.root}/lib/setup/data_out/#{submission.submitted_at}-v#{submission.version}"
    participant_matches = submission.participant_matches.where('algorithm_validation = ? OR manual_validation = ?', ParticipantMatch::PARTICIPANT_MATCH_ALGORITHM_VALIDATION_YES, ParticipantMatch::PARTICIPANT_MATCH_MANUAL_VALIDATION_YES)
    headers = ParticipantMatch.new.attributes.to_hash.keys - ['id', 'submission_id', 'created_at', 'updated_at']
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    CSV.open("#{dir}/participant_match.csv", "wb", force_quotes: true) do |csv|
      csv << row_header
      participant_matches.each do |participant_match|
        row = row_template.dup
        headers.each do |attribute|
          if participant_match[attribute].blank?
            row[attribute] = ""
          else
            row[attribute] = participant_match[attribute]
          end
        end
        csv << row
      end
    end
  end
end

def match_status_general_ehr(status, date, status_st, date_st)
  status_normalized = nil
  if status == 'SUBMITTED'
    status_normalized = '1'
  else
    status_normalized = '0'
  end

  match = false
  if status_normalized == status_st && status_normalized == '1' && date == date_st
    match = true
  elsif status_normalized == status_st && status_normalized == '1' && date != date_st
    match = false
  elsif status_normalized == status_st && status_normalized == '0'
    match = true
  end
  match
end

def match_status_withdrawal(status, date, status_st, date_st)
  status_normalized = nil
  if status == 'NO_USE'
    status_normalized = '1'
  else
    status_normalized = '0'
  end

  match = false
  if status_normalized == status_st && status_normalized == '1' && date == date_st
    match = true
  elsif status_normalized == status_st && status_normalized == '1' && date != date_st
    match = false
  elsif status_normalized == status_st && status_normalized == '0'
    match = true
  end
  match
end

# def match_status(status, date, status_st, date_st)
#   match = false
#   if status == status_st && status == '1' && date == date_st
#     match = true
#   elsif status == status_st && status == '1' && date != date_st
#     match = false
#   elsif status == status_st && status == '0'
#     match = true
#   end
#   match
# end