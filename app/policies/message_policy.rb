# frozen_string_literal: true

# Policy for Message resource authorization
class MessagePolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def show?
    admin? || (patient? && user.patient?)
  end

  def create?
    logged_in?
  end

  def update?
    admin? || (patient? && record.user == user)
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.patient?
        scope.none # Patients don't have direct access to messages
      else
        scope.none
      end
    end
  end
end
