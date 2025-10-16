# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_dashboard

  def index
    if current_user.admin?
      @recent_patients = Patient.recent.limit(5)
      @pending_tasks = Task.pending.limit(10)
      @overdue_tasks = Task.overdue.limit(5)
      @recent_messages = Message.recent.limit(10)
      @stats = {
        total_patients: Patient.count,
        active_patients: Patient.active.count,
        pending_tasks: Task.pending.count,
        overdue_tasks: Task.overdue.count,
        recent_messages: Message.where('created_at > ?', 7.days.ago).count
      }
    else
      # Patient dashboard - simplified for current data model
      @recent_messages = []
      @my_tasks = []
      @stats = {
        total_messages: 0,
        pending_tasks: 0,
        completed_tasks: 0
      }
    end
  end

  private

  def authorize_dashboard
    authorize :dashboard
  end
end
