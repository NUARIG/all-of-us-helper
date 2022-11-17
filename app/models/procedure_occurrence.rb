class ProcedureOccurrence < ApplicationRecord
  establish_connection "#{Rails.env}_omop".to_sym
  self.table_name = 'cdm.procedure_occurrence'
end