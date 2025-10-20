# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    # Create associated patient record if it doesn't exist
    unless resource.patient
      Patient.create!(
        user: resource,
        first_name: 'New',
        last_name: 'Patient',
        email: resource.email,
        phone: '0000000000',
        date_of_birth: 18.years.ago,
        medical_record_number: "MR#{SecureRandom.hex(4).upcase}",
        status: 'active',
        health_question_one: 'answer one',
        health_question_two: 'answer two',
        health_question_three: 'answer three'
      )
    end
    root_path
  end
end
