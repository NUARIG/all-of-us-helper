class PiiPhoneNumber < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  self.table_name = 'cdm.pii_phone_number'
end