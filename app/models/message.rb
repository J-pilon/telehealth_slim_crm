# frozen_string_literal: true

# Message model representing communication between users and patients
class Message < ApplicationRecord
  belongs_to :patient
  belongs_to :user

  # Enums
  enum :message_type, { incoming: 'incoming', outgoing: 'outgoing' }

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :message_type, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_patient, ->(patient) { where(patient: patient) }
  scope :by_user, ->(user) { where(user: user) }
  scope :incoming, -> { where(message_type: 'incoming') }
  scope :outgoing, -> { where(message_type: 'outgoing') }

  # Instance methods
  def sender_name
    user.email
  end

  def formatted_created_at
    return unless persisted?

    created_at.strftime('%B %d, %Y at %I:%M %p')
  end

  def is_recent?
    created_at > 1.hour.ago
  end
end
