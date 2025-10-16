# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasksController, type: :controller do
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

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns all tasks' do
        get :index
        expect(assigns(:tasks)).to include(@task)
      end

      it 'assigns stats hash' do
        get :index
        expect(assigns(:stats)).to be_a(Hash)
        expect(assigns(:stats)[:total_tasks]).to be >= 1
        expect(assigns(:stats)[:pending_tasks]).to be >= 1
      end

      it 'filters by pending status' do
        create(:task, :completed, patient: @patient)
        get :index, params: { status: 'pending' }
        expect(assigns(:tasks)).to all(be_pending)
      end

      it 'filters by completed status' do
        completed_task = create(:task, :completed, patient: @patient)
        get :index, params: { status: 'completed' }
        expect(assigns(:tasks)).to include(completed_task)
        expect(assigns(:tasks)).not_to include(@task)
      end

      it 'filters by overdue status' do
        overdue_task = create(:task, :overdue, patient: @patient)
        get :index, params: { status: 'overdue' }
        expect(assigns(:tasks)).to include(overdue_task)
        expect(assigns(:tasks)).not_to include(@task)
      end

      it 'sorts by due date' do
        get :index, params: { sort: 'due_date' }
        expect(assigns(:tasks).order_values).to eq(Task.by_due_date.order_values)
      end
    end

    context 'when user is authenticated as patient' do
      before { sign_in @patient_user }

      it 'returns a successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns tasks for the patient' do
        patient_task = create(:task, patient: @patient, user: @patient_user)
        get :index
        expect(assigns(:tasks)).to include(patient_task)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :show, params: { id: @task.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :show, params: { id: @task.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested task' do
        get :show, params: { id: @task.id }
        expect(assigns(:task)).to eq(@task)
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
      before { sign_in @admin }

      it 'returns a successful response' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'assigns a new task' do
        get :new
        expect(assigns(:task)).to be_a_new(Task)
      end

      it 'sets patient_id if provided' do
        get :new, params: { patient_id: @patient.id }
        expect(assigns(:task).patient_id).to eq(@patient.id)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'Test Task',
        description: 'Test Description',
        due_date: 1.week.from_now,
        patient_id: @patient.id,
        status: 'pending'
      }
    end
    let(:invalid_attributes) { { title: nil } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        post :create, params: { task: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      context 'with valid parameters' do
        it 'creates a new Task' do
          expect do
            post :create, params: { task: valid_attributes }
          end.to change(Task, :count).by(1)
        end

        it 'assigns the current user to the task' do
          post :create, params: { task: valid_attributes }
          expect(assigns(:task).user).to eq(@admin)
        end

        it 'responds with turbo stream' do
          post :create, params: { task: valid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'redirects to tasks index for HTML format' do
          post :create, params: { task: valid_attributes }, format: :html
          expect(response).to redirect_to(tasks_path)
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Task' do
          expect do
            post :create, params: { task: invalid_attributes }
          end.not_to change(Task, :count)
        end

        it 'responds with turbo stream for errors' do
          post :create, params: { task: invalid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'renders the new template for HTML format' do
          post :create, params: { task: invalid_attributes }, format: :html
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :edit, params: { id: @task.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'returns a successful response' do
        get :edit, params: { id: @task.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested task' do
        get :edit, params: { id: @task.id }
        expect(assigns(:task)).to eq(@task)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { title: 'Updated Task' } }
    let(:invalid_attributes) { { title: nil } }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :update, params: { id: @task.id, task: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      context 'with valid parameters' do
        it 'updates the requested task' do
          patch :update, params: { id: @task.id, task: new_attributes }
          @task.reload
          expect(@task.title).to eq('Updated Task')
        end

        it 'responds with turbo stream' do
          patch :update, params: { id: @task.id, task: new_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'redirects to tasks index for HTML format' do
          patch :update, params: { id: @task.id, task: new_attributes }, format: :html
          expect(response).to redirect_to(tasks_path)
        end
      end

      context 'with invalid parameters' do
        it 'responds with turbo stream for errors' do
          patch :update, params: { id: @task.id, task: invalid_attributes }, format: :turbo_stream
          expect(response.content_type).to include('text/vnd.turbo-stream.html')
        end

        it 'renders the edit template for HTML format' do
          patch :update, params: { id: @task.id, task: invalid_attributes }, format: :html
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete :destroy, params: { id: @task.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'destroys the task' do
        expect do
          delete :destroy, params: { id: @task.id }
        end.to change(Task, :count).by(-1)
      end

      it 'responds with turbo stream' do
        delete :destroy, params: { id: @task.id }, format: :turbo_stream
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'redirects to tasks index for HTML format' do
        delete :destroy, params: { id: @task.id }, format: :html
        expect(response).to redirect_to(tasks_path)
      end
    end
  end

  describe 'PATCH #complete' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :complete, params: { id: @task.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'marks the task as completed' do
        patch :complete, params: { id: @task.id }
        @task.reload
        expect(@task.status).to eq('completed')
        expect(@task.completed_at).not_to be_nil
      end

      it 'responds with turbo stream' do
        patch :complete, params: { id: @task.id }, format: :turbo_stream
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'redirects to tasks index for HTML format' do
        patch :complete, params: { id: @task.id }, format: :html
        expect(response).to redirect_to(tasks_path)
      end
    end
  end

  describe 'PATCH #reopen' do
    let(:completed_task) { create(:task, :completed, patient: @patient) }

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch :reopen, params: { id: completed_task.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated as admin' do
      before { sign_in @admin }

      it 'reopens the task' do
        patch :reopen, params: { id: completed_task.id }
        completed_task.reload
        expect(completed_task.status).to eq('pending')
        expect(completed_task.completed_at).to be_nil
      end

      it 'responds with turbo stream' do
        patch :reopen, params: { id: completed_task.id }, format: :turbo_stream
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'redirects to tasks index for HTML format' do
        patch :reopen, params: { id: completed_task.id }, format: :html
        expect(response).to redirect_to(tasks_path)
      end
    end
  end
end
