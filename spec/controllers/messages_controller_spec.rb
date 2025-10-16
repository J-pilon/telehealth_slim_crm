# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:patient) { create(:patient) }
  let(:message) { create(:message, patient: patient, user: admin) }

  before do
    # Clear existing data
    Patient.destroy_all
    User.destroy_all
    Message.destroy_all

    @admin = create(:user, :admin)
    @patient_user = create(:user, :patient)
    @patient = create(:patient)
    @message = create(:message, patient: @patient, user: @admin)
  end

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :index, params: { patient_id: @patient.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :index, params: { patient_id: @patient.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the patient' do
        get :index, params: { patient_id: @patient.id }
        expect(assigns(:patient)).to eq(@patient)
      end

      it 'assigns messages for the patient' do
        get :index, params: { patient_id: @patient.id }
        expect(assigns(:messages)).to include(@message)
      end

      it 'assigns a new message' do
        get :index, params: { patient_id: @patient.id }
        expect(assigns(:message)).to be_a_new(Message)
      end
    end

    context 'when user is authenticated as patient' do
      before { sign_in @patient_user }

      it 'returns a successful response' do
        get :index, params: { patient_id: @patient.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns messages for the patient' do
        # Create a message for the patient user
        patient_message = create(:message, patient: @patient, user: @patient_user)
        get :index, params: { patient_id: @patient.id }
        expect(assigns(:messages)).to include(patient_message)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :show, params: { patient_id: @patient.id, id: @message.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :show, params: { patient_id: @patient.id, id: @message.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested message' do
        get :show, params: { patient_id: @patient.id, id: @message.id }
        expect(assigns(:message)).to eq(@message)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        content: 'Test message',
        message_type: 'outgoing'
      }
    end
    let(:invalid_attributes) { { content: nil } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post :create, params: { patient_id: @patient.id, message: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      context 'with valid parameters' do
        it 'creates a new Message' do
          expect do
            post :create, params: { patient_id: @patient.id, message: valid_attributes }
          end.to change(Message, :count).by(1)
        end

        it 'assigns the current user to the message' do
          post :create, params: { patient_id: @patient.id, message: valid_attributes }
          expect(assigns(:message).user).to eq(@admin)
        end

        it 'assigns the patient to the message' do
          post :create, params: { patient_id: @patient.id, message: valid_attributes }
          expect(assigns(:message).patient).to eq(@patient)
        end

        it 'responds with turbo stream' do
          post :create, params: { patient_id: @patient.id, message: valid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'redirects to messages index for HTML format' do
          post :create, params: { patient_id: @patient.id, message: valid_attributes }, format: :html
          expect(response).to redirect_to(patient_messages_path(@patient))
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Message' do
          expect do
            post :create, params: { patient_id: @patient.id, message: invalid_attributes }
          end.not_to change(Message, :count)
        end

        it 'responds with turbo stream for errors' do
          post :create, params: { patient_id: @patient.id, message: invalid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'renders the index template for HTML format' do
          post :create, params: { patient_id: @patient.id, message: invalid_attributes }, format: :html
          expect(response).to render_template(:index)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :edit, params: { patient_id: @patient.id, id: @message.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :edit, params: { patient_id: @patient.id, id: @message.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested message' do
        get :edit, params: { patient_id: @patient.id, id: @message.id }
        expect(assigns(:message)).to eq(@message)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { content: 'Updated message' } }
    let(:invalid_attributes) { { content: nil } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :update, params: { patient_id: @patient.id, id: @message.id, message: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      context 'with valid parameters' do
        it 'updates the requested message' do
          patch :update, params: { patient_id: @patient.id, id: @message.id, message: new_attributes }
          @message.reload
          expect(@message.content).to eq('Updated message')
        end

        it 'responds with turbo stream' do
          patch :update, params: { patient_id: @patient.id, id: @message.id, message: new_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'redirects to messages index for HTML format' do
          patch :update, params: { patient_id: @patient.id, id: @message.id, message: new_attributes }, format: :html
          expect(response).to redirect_to(patient_messages_path(@patient))
        end
      end

      context 'with invalid parameters' do
        it 'responds with turbo stream for errors' do
          patch :update, params: { patient_id: @patient.id, id: @message.id, message: invalid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'renders the edit template for HTML format' do
          patch :update, params: { patient_id: @patient.id, id: @message.id, message: invalid_attributes }, format: :html
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete :destroy, params: { patient_id: @patient.id, id: @message.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'destroys the message' do
        expect do
          delete :destroy, params: { patient_id: @patient.id, id: @message.id }
        end.to change(Message, :count).by(-1)
      end

      it 'responds with turbo stream' do
        delete :destroy, params: { patient_id: @patient.id, id: @message.id }, format: :turbo_stream
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'redirects to messages index for HTML format' do
        delete :destroy, params: { patient_id: @patient.id, id: @message.id }, format: :html
        expect(response).to redirect_to(patient_messages_path(@patient))
      end
    end
  end
end
