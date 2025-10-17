# frozen_string_literal: true

# Patient model representing healthcare patients in the CRM system
class Patient < ApplicationRecord
  # Associations
  has_many :messages, dependent: :destroy
  has_many :tasks, dependent: :destroy

  # Enums
  enum :status, { active: 'active', inactive: 'inactive' }

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A\d{10,15}\z/, message: 'must be 10-15 digits' }
  validates :date_of_birth, presence: true
  validates :medical_record_number, presence: true, uniqueness: true, length: { minimum: 5, maximum: 20 }
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :by_name, -> { order(:last_name, :first_name) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def age
    return nil unless date_of_birth

    today = Date.current
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end

  def pending_tasks_count
    tasks.pending.count
  end

  def recent_messages_count
    messages.where('created_at > ?', 7.days.ago).count
  end
end
