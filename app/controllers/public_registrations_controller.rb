# frozen_string_literal: true

# Public controller for patient self-registration
class PublicRegistrationsController < ApplicationController
  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)
    @patient.medical_record_number = rand(10**9)
    @patient.status = 'active'

    if @patient.save
      create_user_and_task
    else
      render :new, status: :unprocessable_content
    end
  end

  def success
    # Success page after registration
  end

  private

  def create_user_and_task
    user = create_patient_user
    return render :new, status: :unprocessable_content unless user

    @patient.update!(user: user)
    send_welcome_email(user)
    create_admin_task
    redirect_to success_patient_application_path,
                notice: 'Thank you for registering! Please check your email to set your password.'
  end

  def create_patient_user
    user = User.new(
      email: @patient.email,
      password: SecureRandom.hex(32),
      role: 'patient'
    )
    user.skip_patient_creation = true

    if user.save
      user
    else
      @patient.destroy
      nil
    end
  end

  def send_welcome_email(user)
    raw_token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
    user.update!(
      reset_password_token: encrypted_token,
      reset_password_sent_at: Time.current
    )
    WelcomeEmailJob.perform_later(@patient.id, raw_token)
  end

  def create_admin_task
    admin = User.admins.first
    return unless admin

    Task.create!(
      patient: @patient,
      user: admin,
      title: "New Applicant - #{@patient.full_name}",
      description: 'Verify ID & prep for provider',
      status: 'pending',
      due_date: 3.days.from_now
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to create admin task: #{e.message}"
  end

  def patient_params
    params.require(:patient).permit(
      :first_name, :last_name, :email, :phone, :date_of_birth,
      :health_question_one, :health_question_two, :health_question_three
    )
  end
end
