# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_dashboard

  def index
    current_user.admin? ? load_admin_dashboard : load_patient_dashboard
  end

  private

  def load_admin_dashboard
    @recent_patients = Patient.recent.limit(10)
    @pending_tasks = Task.pending.recent.limit(10)
    @overdue_tasks = Task.overdue.recent.limit(5)
    @stats = {
      total_patients: Patient.count,
      active_patients: Patient.active.count,
      pending_tasks: Task.pending.count,
      overdue_tasks: Task.overdue.count,
      recent_messages: Message.where('created_at > ?', 7.days.ago).count
    }
  end

  def load_patient_dashboard
    scoped_tasks = policy_scope(Task)
    messages = current_user.patient.messages
    @recent_messages = messages.recent
    @my_tasks = scoped_tasks
    @stats = {
      total_messages: messages.count,
      pending_tasks: @my_tasks.pending.recent.count,
      completed_tasks: @my_tasks.completed.count
    }
  end

  def authorize_dashboard
    authorize :dashboard
  end
end
