# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:patient) { create(:patient) }

  describe 'GET /patients/:patient_id/messages' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get patient_messages_path(patient)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get patient_messages_path(patient)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /patients/:patient_id/messages' do
    let(:valid_attributes) do
      {
        content: 'Test message',
        message_type: 'outgoing'
      }
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post patient_messages_path(patient), params: { message: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in admin }

      it 'creates a new message and redirects' do
        expect do
          post patient_messages_path(patient), params: { message: valid_attributes }
        end.to change(Message, :count).by(1)

        expect(response).to redirect_to(patient_messages_path(patient))
      end
    end
  end
end
