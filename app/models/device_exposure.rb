class DeviceExposure < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  self.table_name = 'cdm.device_exposure'
end