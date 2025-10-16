# frozen_string_literal: true

# Policy for Message resource authorization
class MessagePolicy < ApplicationPolicy
  def index?
    admin? || (patient? && user.patient?)
  end

  def show?
    admin? || (patient? && user.patient?)
  end

  def create?
    admin? || (patient? && user.patient?)
  end

  def update?
    admin? || (patient? && record.user == user)
  end

  def destroy?
    admin? || (patient? && record.user == user)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.patient?
        scope.where(user: user) # Patients can see their own messages
      else
        scope.none
      end
    end
  end
end
