class FactRelationship < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  self.table_name = 'cdm.fact_relationship'
end