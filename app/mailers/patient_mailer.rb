# frozen_string_literal: true

# Mailer for patient-related emails
class PatientMailer < ApplicationMailer
  default from: 'noreply@telehealth-crm.com'

  def welcome_email(patient, reset_token)
    @patient = patient
    @url = edit_user_password_url(reset_password_token: reset_token)

    mail(
      to: @patient.email,
      subject: 'Welcome to Telehealth CRM'
    )
  end
end
