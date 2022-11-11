class ParticipantMatchDetail < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  belongs_to :participant_match

  MATCH_STATUS_MATCH = 'match'
  MATCH_STATUS_NO_MATCH = 'no_match'
  MATCH_STATUSES = [MATCH_STATUS_MATCH, MATCH_STATUS_NO_MATCH]

  MANUAL_VALIDATION_STATUS_NOT_APPLCIABLE = 'not_applicable'
  MANUAL_VALIDATION_STATUS_UNDETERMINED = 'undetermined'
  MANUAL_VALIDATION_STATUS_ACCEPTED = 'accepted'
  MANUAL_VALIDATION_STATUS_PREVIOUSLY_ACCEPTED = 'previously_accepted'
  MANUAL_VALIDATION_STATUS_REJECTED = 'rejected'
  MANUAL_VALIDATION_STATUSES = [MANUAL_VALIDATION_STATUS_UNDETERMINED, MANUAL_VALIDATION_STATUS_ACCEPTED, MANUAL_VALIDATION_STATUS_PREVIOUSLY_ACCEPTED, MANUAL_VALIDATION_STATUS_REJECTED]
end