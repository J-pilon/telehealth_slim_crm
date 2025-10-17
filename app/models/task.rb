# frozen_string_literal: true

# Task model representing tasks assigned to patients
class Task < ApplicationRecord
  belongs_to :patient
  belongs_to :user

  # Enums
  enum :status, { pending: 'pending', completed: 'completed' }

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, length: { maximum: 1000 }
  validates :status, presence: true
  validates :due_date, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :overdue, -> { where('due_date < ? AND status = ?', Date.current.beginning_of_day, 'pending') }
  scope :due_today, -> { where(due_date: Date.current.all_day) }
  scope :due_this_week, -> { where(due_date: Date.current.all_week) }
  scope :by_due_date, -> { order(:due_date) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_save :set_completed_at, if: :status_changed?

  # Instance methods
  def overdue?
    due_date < Time.current && pending?
  end

  def due_today?
    due_date.to_date == Date.current
  end

  def due_this_week?
    due_date.to_date.cweek == Date.current.cweek && due_date.to_date.year == Date.current.year
  end

  def completion_time
    return nil unless completed_at

    completed_at - created_at
  end

  def days_overdue
    return 0 unless overdue?

    (Time.current - due_date) / 1.day
  end

  private

  def set_completed_at
    self.completed_at = completed? ? Time.current : nil
  end
end
