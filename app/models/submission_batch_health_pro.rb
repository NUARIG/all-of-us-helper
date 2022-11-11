class SubmissionBatchHealthPro < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  belongs_to :submission
  belongs_to :batch_health_pro
end