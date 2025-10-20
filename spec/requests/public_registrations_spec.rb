# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicRegistrations', type: :request do
  let(:admin) { create(:user, :admin) }

  describe 'GET /apply' do
    it 'returns http success' do
      get patient_application_path
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get patient_application_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe 'POST /apply' do
    let(:valid_attributes) do
      FactoryBot.attributes_for(:patient)
    end

    context 'with valid attributes (happy path)' do
      before { admin } # Ensure admin exists for task creation

      it 'creates a new patient' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.to change(Patient, :count).by(1)
      end

      it 'creates an associated user account' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.to change(User, :count).by(1)

        patient = Patient.last
        expect(patient.user).to be_present
        expect(patient.user.email).to eq(valid_attributes[:email])
        expect(patient.user.role).to eq('patient')
      end

      it 'sets the patient status to active' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(Patient.last.status).to eq('active')
      end

      it 'generates a medical record number' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(Patient.last.medical_record_number).to be_present
      end

      it 'stores health question responses' do
        post patient_application_path, params: { patient: valid_attributes }
        patient = Patient.last
        expect(patient.health_question_one).to eq('Sample answer 1')
        expect(patient.health_question_two).to eq('Sample answer 2')
        expect(patient.health_question_three).to eq('Sample answer 3')
      end

      it 'generates a password reset token for the user' do
        post patient_application_path, params: { patient: valid_attributes }
        user = User.last
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present
      end

      it 'enqueues a welcome email job' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.to have_enqueued_job(WelcomeEmailJob).with(kind_of(Integer), kind_of(String))
      end

      it 'creates a task for the admin' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.to change(Task, :count).by(1)
      end

      it 'redirects to success page' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(response).to redirect_to(success_patient_application_path)
      end

      it 'sets a success notice' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(flash[:notice]).to eq('Thank you for registering! Please check your email to set your password.')
      end

      it 'returns a redirect status code (302)' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'with invalid attributes (unhappy path)' do
      let(:invalid_attributes) do
        {
          first_name: '',
          last_name: 'Doe',
          email: 'invalid-email',
          phone: '123',
          date_of_birth: nil
        }
      end

      it 'does not create a new patient' do
        expect do
          post patient_application_path, params: { patient: invalid_attributes }
        end.not_to change(Patient, :count)
      end

      it 'does not create a user account' do
        expect do
          post patient_application_path, params: { patient: invalid_attributes }
        end.not_to change(User, :count)
      end

      it 'does not enqueue a welcome email' do
        expect do
          post patient_application_path, params: { patient: invalid_attributes }
        end.not_to have_enqueued_job(WelcomeEmailJob)
      end

      it 'does not create a task' do
        expect do
          post patient_application_path, params: { patient: invalid_attributes }
        end.not_to change(Task, :count)
      end

      it 'renders the new template' do
        post patient_application_path, params: { patient: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable_content status code (422)' do
        post patient_application_path, params: { patient: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with missing required fields' do
      let(:missing_email) do
        {
          first_name: 'John',
          last_name: 'Doe',
          email: '',
          phone: '1234567890',
          date_of_birth: '1990-01-01'
        }
      end

      it 'returns unprocessable_content status' do
        post patient_application_path, params: { patient: missing_email }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create patient or user records' do
        expect do
          post patient_application_path, params: { patient: missing_email }
        end.not_to(change { [Patient.count, User.count] })
      end
    end

    context 'when no admin exists' do
      before { User.admins.destroy_all }

      it 'still creates the patient and user' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.to change(Patient, :count).by(1).and change(User, :count).by(1)
      end

      it 'does not create a task' do
        expect do
          post patient_application_path, params: { patient: valid_attributes }
        end.not_to change(Task, :count)
      end

      it 'redirects to success page' do
        post patient_application_path, params: { patient: valid_attributes }
        expect(response).to redirect_to(success_patient_application_path)
      end
    end
  end

  describe 'GET /apply/success' do
    it 'returns http success' do
      get success_patient_application_path
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get success_patient_application_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end
end
