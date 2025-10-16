# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_dashboard

  def index
    # Will be implemented in Unit 9 with proper dashboard logic
  end

  private

  def authorize_dashboard
    authorize :dashboard
  end
end
