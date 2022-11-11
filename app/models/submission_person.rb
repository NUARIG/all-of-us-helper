class SubmissionPerson < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  belongs_to :submission
end