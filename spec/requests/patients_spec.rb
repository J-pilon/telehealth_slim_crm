# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Patients', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:patient) { create(:patient) }

  describe 'GET /patients' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get patients_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get patients_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is authenticated as patient' do
      before { sign_in patient_user }

      it 'redirects with unauthorized message' do
        get patients_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end
  end

  describe 'GET /patients/:id' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get patient_path(patient)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get patient_path(patient)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /patients/new' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get new_patient_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get new_patient_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /patients' do
    let(:valid_attributes) { attributes_for(:patient) }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post patients_path, params: { patient: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'creates a new patient and redirects' do
        expect do
          post patients_path, params: { patient: valid_attributes }
        end.to change(Patient, :count).by(1)

        expect(response).to redirect_to(Patient.last)
      end
    end
  end

  describe 'GET /patients/:id/edit' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get edit_patient_path(patient)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get edit_patient_path(patient)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /patients/:id' do
    let(:new_attributes) { { first_name: 'Jane' } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch patient_path(patient), params: { patient: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'updates the patient and redirects' do
        patch patient_path(patient), params: { patient: new_attributes }
        patient.reload
        expect(patient.first_name).to eq('Jane')
        expect(response).to redirect_to(patient)
      end
    end
  end

  describe 'DELETE /patients/:id' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete patient_path(patient)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before do
        sign_in admin
        Patient.destroy_all # Clear existing data
      end

      it 'destroys the patient and redirects' do
        test_patient = create(:patient) # Create patient after clearing database

        expect do
          delete patient_path(test_patient)
        end.to change(Patient, :count).by(-1)

        expect(response).to redirect_to(patients_path)
      end
    end
  end
end
