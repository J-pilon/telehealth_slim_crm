# frozen_string_literal: true

# Policy for Patient resource authorization
class PatientPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || (user.patient? && record.user == user)
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.patient?
        scope.none # Patients don't have direct access to patient records
      else
        scope.none
      end
    end
  end
end
