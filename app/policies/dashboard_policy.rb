# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
