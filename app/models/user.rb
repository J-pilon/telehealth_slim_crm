# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role enum
  enum :role, { admin: 'admin', patient: 'patient' }

  # Associations
  has_one :patient, dependent: :destroy

  # Validations
  validates :role, presence: true

  # Callbacks
  after_initialize :set_default_role, if: :new_record?
  after_create :create_patient_if_needed, unless: :skip_patient_creation

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :patients, -> { where(role: 'patient') }

  # Attribute accessor to skip patient creation (used when creating user from patient)
  attr_accessor :skip_patient_creation

  private

  def set_default_role
    self.role ||= 'patient'
  end

  def create_patient_if_needed
    return unless patient? && patient.blank?

    Patient.create!(
      user: self,
      first_name: 'New',
      last_name: 'Patient',
      email: email,
      phone: '0000000000',
      date_of_birth: 18.years.ago,
      medical_record_number: "MR#{SecureRandom.hex(4).upcase}",
      status: 'active',
      health_question_one: 'health answer 1',
      health_question_two: 'health answer 2',
      health_question_three: 'health answer 3'
    )
  end
end
