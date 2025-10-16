# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatientsController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:patient) { create(:patient) }

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before do
        sign_in admin
        create_list(:patient, 3)
      end

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns all patients' do
        get :index
        expect(assigns(:patients)).to be_present
      end

      it 'filters by active status' do
        create(:patient, :inactive)
        get :index, params: { status: 'active' }
        expect(assigns(:patients)).to all(be_active)
      end

      it 'filters by inactive status' do
        create(:patient, :inactive)
        get :index, params: { status: 'inactive' }
        expect(assigns(:patients)).to all(be_inactive)
      end

      it 'sorts by name' do
        get :index, params: { sort: 'name' }
        expect(assigns(:patients).order_values).to eq(Patient.by_name.order_values)
      end

      it 'sorts by recent' do
        get :index, params: { sort: 'recent' }
        expect(assigns(:patients).order_values).to eq(Patient.recent.order_values)
      end
    end

    context 'when user is authenticated as patient' do
      before do
        sign_in patient_user
      end

      it 'redirects with unauthorized message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

  describe 'GET #show' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :show, params: { id: patient.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before do
        sign_in admin
        create_list(:message, 3, patient: patient)
        create_list(:task, 2, :pending, patient: patient)
        create_list(:task, 1, :completed, patient: patient)
      end

      it 'returns successful response' do
        get :show, params: { id: patient.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the patient' do
        get :show, params: { id: patient.id }
        expect(assigns(:patient)).to eq(patient)
      end

      it 'assigns recent messages' do
        get :show, params: { id: patient.id }
        expect(assigns(:recent_messages)).to be_present
        expect(assigns(:recent_messages).count).to eq(3)
      end

      it 'assigns pending tasks' do
        get :show, params: { id: patient.id }
        expect(assigns(:pending_tasks)).to be_present
        expect(assigns(:pending_tasks).count).to eq(2)
      end

      it 'assigns completed tasks' do
        get :show, params: { id: patient.id }
        expect(assigns(:completed_tasks)).to be_present
        expect(assigns(:completed_tasks).count).to eq(1)
      end
    end
  end

  describe 'GET #new' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns successful response' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'assigns a new patient' do
        get :new
        expect(assigns(:patient)).to be_a_new(Patient)
      end
    end

    context 'when user is authenticated as patient' do
      before { sign_in patient_user }

      it 'redirects with unauthorized message' do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        phone: '1234567890',
        date_of_birth: 30.years.ago,
        medical_record_number: 'MR123456',
        status: 'active'
      }
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post :create, params: { patient: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      context 'with valid attributes' do
        it 'creates a new patient' do
          expect {
            post :create, params: { patient: valid_attributes }
          }.to change(Patient, :count).by(1)
        end

        it 'redirects to the patient' do
          post :create, params: { patient: valid_attributes }
          expect(response).to redirect_to(Patient.last)
        end

        it 'sets a success notice' do
          post :create, params: { patient: valid_attributes }
          expect(flash[:notice]).to eq('Patient was successfully created.')
        end
      end

      context 'with invalid attributes' do
        let(:invalid_attributes) { { first_name: '' } }

        it 'does not create a new patient' do
          expect {
            post :create, params: { patient: invalid_attributes }
          }.not_to change(Patient, :count)
        end

        it 'renders the new template' do
          post :create, params: { patient: invalid_attributes }
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :edit, params: { id: patient.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns successful response' do
        get :edit, params: { id: patient.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the patient' do
        get :edit, params: { id: patient.id }
        expect(assigns(:patient)).to eq(patient)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { first_name: 'Jane' } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :update, params: { id: patient.id, patient: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      context 'with valid attributes' do
        it 'updates the patient' do
          patch :update, params: { id: patient.id, patient: new_attributes }
          patient.reload
          expect(patient.first_name).to eq('Jane')
        end

        it 'redirects to the patient' do
          patch :update, params: { id: patient.id, patient: new_attributes }
          expect(response).to redirect_to(patient)
        end

        it 'sets a success notice' do
          patch :update, params: { id: patient.id, patient: new_attributes }
          expect(flash[:notice]).to eq('Patient was successfully updated.')
        end
      end

      context 'with invalid attributes' do
        let(:invalid_attributes) { { first_name: '' } }

        it 'does not update the patient' do
          original_name = patient.first_name
          patch :update, params: { id: patient.id, patient: invalid_attributes }
          patient.reload
          expect(patient.first_name).to eq(original_name)
        end

        it 'renders the edit template' do
          patch :update, params: { id: patient.id, patient: invalid_attributes }
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete :destroy, params: { id: patient.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before {
        sign_in admin
        Patient.destroy_all # Clear existing data
      }

      it 'destroys the patient' do
        test_patient = create(:patient) # Create patient after clearing database

        expect {
          delete :destroy, params: { id: test_patient.id }
        }.to change(Patient, :count).by(-1)

        expect(response).to redirect_to(patients_path)
        expect(flash[:notice]).to eq('Patient was successfully deleted.')
      end

      it 'redirects to patients index' do
        delete :destroy, params: { id: patient.id }
        expect(response).to redirect_to(patients_path)
      end

      it 'sets a success notice' do
        delete :destroy, params: { id: patient.id }
        expect(flash[:notice]).to eq('Patient was successfully deleted.')
      end
    end
  end
end
