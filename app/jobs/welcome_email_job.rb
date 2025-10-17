# frozen_string_literal: true

# Background job to send welcome emails to new patients
class WelcomeEmailJob < ApplicationJob
  queue_as :mailers

  def perform(patient_id)
    patient = Patient.find(patient_id)
    PatientMailer.welcome_email(patient).deliver_now
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "WelcomeEmailJob: Patient with ID #{patient_id} not found"
  end
end
