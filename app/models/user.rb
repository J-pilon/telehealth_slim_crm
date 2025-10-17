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

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :patients, -> { where(role: 'patient') }
end
