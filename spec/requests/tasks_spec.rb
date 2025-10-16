# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:patient) { create(:patient) }
  let(:task) { create(:task, patient: patient) }

  before do
    # Clear existing data
    Patient.destroy_all
    User.destroy_all
    Task.destroy_all

    @admin = create(:user, :admin)
    @patient_user = create(:user, :patient)
    @patient = create(:patient)
    @task = create(:task, patient: @patient)
  end

  describe 'GET /tasks' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get tasks_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns http success' do
        get tasks_path
        expect(response).to have_http_status(:success)
      end

      it 'assigns tasks and stats' do
        get tasks_path
        expect(assigns(:tasks)).to be_present
        expect(assigns(:stats)).to be_a(Hash)
      end
    end

    context 'when user is authenticated as patient' do
      before { sign_in @patient_user }

      it 'returns http success' do
        get tasks_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /tasks/:id' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get task_path(@task)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns http success' do
        get task_path(@task)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /tasks/new' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get new_task_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns http success' do
        get new_task_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /tasks' do
    let(:valid_attributes) do
      {
        title: 'Test Task',
        description: 'Test Description',
        due_date: 1.week.from_now,
        patient_id: @patient.id,
        status: 'pending'
      }
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post tasks_path, params: { task: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'creates a new task and redirects' do
        expect do
          post tasks_path, params: { task: valid_attributes }
        end.to change(Task, :count).by(1)

        expect(response).to redirect_to(tasks_path)
      end

      it 'responds with turbo stream' do
        post tasks_path, params: { task: valid_attributes }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'GET /tasks/:id/edit' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get edit_task_path(@task)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns http success' do
        get edit_task_path(@task)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /tasks/:id' do
    let(:new_attributes) { { title: 'Updated Task' } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch task_path(@task), params: { task: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'updates the task and redirects' do
        patch task_path(@task), params: { task: new_attributes }
        @task.reload
        expect(@task.title).to eq('Updated Task')
        expect(response).to redirect_to(tasks_path)
      end

      it 'responds with turbo stream' do
        patch task_path(@task), params: { task: new_attributes }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'DELETE /tasks/:id' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete task_path(@task)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'deletes the task and redirects' do
        expect do
          delete task_path(@task)
        end.to change(Task, :count).by(-1)

        expect(response).to redirect_to(tasks_path)
      end

      it 'responds with turbo stream' do
        delete task_path(@task), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'PATCH /tasks/:id/complete' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch complete_task_path(@task)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'marks the task as completed' do
        patch complete_task_path(@task)
        @task.reload
        expect(@task.status).to eq('completed')
        expect(@task.completed_at).not_to be_nil
      end

      it 'responds with turbo stream' do
        patch complete_task_path(@task), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'PATCH /tasks/:id/reopen' do
    let(:completed_task) { create(:task, :completed, patient: @patient) }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch reopen_task_path(completed_task)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'reopens the task' do
        patch reopen_task_path(completed_task)
        completed_task.reload
        expect(completed_task.status).to eq('pending')
        expect(completed_task.completed_at).to be_nil
      end

      it 'responds with turbo stream' do
        patch reopen_task_path(completed_task), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end
    end
  end
end
