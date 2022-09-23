class HealthProPolicy < ApplicationPolicy
  def update?
    user.has_role?(Role::ROLE_ALL_OF_US_HELPER_USER)
  end

  def declined_patients_index?
    user.has_role?(Role::ROLE_ALL_OF_US_HELPER_USER)
  end

  def declined_patient_update?
    user.has_role?(Role::ROLE_ALL_OF_US_HELPER_USER)
  end
end