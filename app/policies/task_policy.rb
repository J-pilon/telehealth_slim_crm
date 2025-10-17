# frozen_string_literal: true

# Policy for Task resource authorization
class TaskPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def show?
    admin? || (patient? && user.patient?)
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

  def complete?
    admin? || (patient? && user.patient?)
  end

  def reopen?
    admin? || (patient? && user.patient?)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.patient?
        scope.where(patient: user.patient) # Patients can see tasks for their patient record
      else
        scope.none
      end
    end
  end
end
