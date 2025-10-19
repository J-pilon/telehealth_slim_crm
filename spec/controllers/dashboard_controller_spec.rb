# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before do
        # Clear existing data
        Patient.destroy_all
        Task.destroy_all
        Message.destroy_all

        sign_in admin
        create_list(:patient, 3, :active)
        create_list(:patient, 2, :inactive)
        create_list(:task, 5, :pending)
        create_list(:task, 2, :overdue)
        create_list(:message, 3)
      end

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns recent patients' do
        get :index
        expect(assigns(:recent_patients)).to be_present
        expect(assigns(:recent_patients).count).to be <= 10
      end

      it 'assigns pending tasks' do
        get :index
        expect(assigns(:pending_tasks)).to be_present
        expect(assigns(:pending_tasks).count).to be <= 10
      end

      it 'assigns overdue tasks' do
        get :index
        expect(assigns(:overdue_tasks)).to be_present
        expect(assigns(:overdue_tasks).count).to eq(2)
      end

      it 'assigns recent messages count in stats' do
        get :index
        expect(assigns(:stats)[:recent_messages]).to eq(3)
      end

      it 'assigns stats hash' do
        get :index
        expect(assigns(:stats)).to be_a(Hash)
        expect(assigns(:stats)[:total_patients]).to be >= 5
        expect(assigns(:stats)[:active_patients]).to be >= 3
        expect(assigns(:stats)[:pending_tasks]).to be >= 5
        expect(assigns(:stats)[:overdue_tasks]).to be >= 2
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when user is authenticated as patient' do
      before do
        sign_in patient_user
      end

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns empty arrays for patient data' do
        get :index
        expect(assigns(:recent_messages)).to eq([])
        expect(assigns(:my_tasks)).to eq([])
      end

      it 'assigns stats hash with zeros' do
        get :index
        expect(assigns(:stats)).to be_a(Hash)
        expect(assigns(:stats)[:total_messages]).to eq(0)
        expect(assigns(:stats)[:pending_tasks]).to eq(0)
        expect(assigns(:stats)[:completed_tasks]).to eq(0)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end
  end
end
