class Submission < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  has_many :submission_batch_health_pros
  has_many :submission_persons
  has_many :submission_tables
  has_many :participant_matches
end