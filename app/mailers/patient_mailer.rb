# frozen_string_literal: true

# Mailer for patient-related emails
class PatientMailer < ApplicationMailer
  default from: 'noreply@telehealth-crm.com'

  def welcome_email(patient)
    @patient = patient
    @url = root_url

    mail(
      to: @patient.email,
      subject: 'Welcome to Telehealth CRM'
    )
  end
end
