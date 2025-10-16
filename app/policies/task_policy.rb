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
    admin? || (patient? && user.patient?)
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.patient?
        scope.none # Patients don't have direct access to tasks
      else
        scope.none
      end
    end
  end
end
