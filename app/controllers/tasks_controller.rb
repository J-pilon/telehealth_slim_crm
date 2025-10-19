# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: %i[show edit update destroy]

  def index
    authorize Task
    @tasks = policy_scope(Task)

    # Filter tasks based on status
    @tasks = @tasks.pending if params[:status] == 'pending'
    @tasks = @tasks.completed if params[:status] == 'completed'
    @tasks = @tasks.overdue if params[:status] == 'overdue'
    @tasks = @tasks.due_today if params[:status] == 'due_today'

    # Sort tasks
    @tasks = @tasks.by_due_date if params[:sort] == 'due_date'
    @tasks = @tasks.recent if params[:sort] == 'recent'

    # Pagination
    @tasks = @tasks.order(updated_at: :desc).page(params[:page]).per(20)

    # Initialize task for inline form
    @task = Task.new

    # Stats for dashboard - use scoped tasks
    scoped_tasks = policy_scope(Task)
    @stats = {
      total_tasks: scoped_tasks.count,
      pending_tasks: scoped_tasks.pending.count,
      completed_tasks: scoped_tasks.completed.count,
      overdue_tasks: scoped_tasks.overdue.count,
      due_today_tasks: scoped_tasks.due_today.count
    }
  end

  def show
    authorize @task

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def new
    @task = Task.new
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    @task.patient = @patient if @patient
    authorize @task

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          # Turbo frame will request HTML, render the form partial
          render partial: 'tasks/form', locals: { task: @task, patient: @patient }
        elsif @patient
          redirect_to patient_tasks_path(@patient)
        else
          render :new
        end
      end
      format.turbo_stream do
        if @patient
          render turbo_stream: turbo_stream.replace('patient_task_form', partial: 'tasks/form',
                                                                         locals: { task: @task, patient: @patient })
        else
          render turbo_stream: turbo_stream.replace('task_form', partial: 'tasks/form',
                                                                 locals: { task: @task, patient: nil })
        end
      end
    end
  end

  def edit
    authorize @task

    respond_to do |format|
      format.turbo_stream
      format.html { render :edit }
    end
  end

  def create
    @task = Task.new(task_params)
    @task.user = current_user
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    authorize @task

    if @task.save
      update_stats
      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to @patient ? patient_path(@patient) : tasks_path, notice: 'Task was successfully created.'
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(frame_id, partial: 'tasks/form',
                                                              locals: { task: @task, patient: @patient })
        end
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @task

    respond_to do |format|
      if @task.update(task_params)
        # Update stats for turbo stream response
        update_stats
        format.turbo_stream
        format.html { redirect_to tasks_path, notice: 'Task was successfully updated.' }
      else
        format.turbo_stream
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @task
    @task.destroy

    respond_to do |format|
      # Update stats for turbo stream response
      update_stats
      format.turbo_stream
      format.html { redirect_to tasks_path, notice: 'Task was successfully deleted.' }
    end
  end

  def complete
    @task = Task.find(params[:id])
    authorize @task

    respond_to do |format|
      if @task.update(status: 'completed')
        @task.reload
        update_stats
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', @stats[:pending_tasks]),
            turbo_stream.replace('task_detail', partial: 'tasks/show_content', locals: { task: @task }),
            turbo_stream.update('flash-messages', partial: 'shared/flash_messages',
                                                  locals: { notice: 'Task marked as completed.' })
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task marked as completed.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task })
        end
        format.html { redirect_to tasks_path, alert: 'Failed to complete task.' }
      end
    end
  end

  def reopen
    @task = Task.find(params[:id])
    authorize @task

    respond_to do |format|
      if @task.update(status: 'pending')
        @task.reload
        update_stats
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', @stats[:pending_tasks]),
            turbo_stream.replace('task_detail', partial: 'tasks/show_content', locals: { task: @task }),
            turbo_stream.update('flash-messages', partial: 'shared/flash_messages',
                                                  locals: { notice: 'Task reopened.' })
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task reopened.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task })
        end
        format.html { redirect_to tasks_path, alert: 'Failed to reopen task.' }
      end
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :status, :patient_id, :user_id)
  end

  def update_stats
    scoped_tasks = policy_scope(Task)
    @stats = {
      total_tasks: scoped_tasks.count,
      pending_tasks: scoped_tasks.pending.count,
      completed_tasks: scoped_tasks.completed.count,
      overdue_tasks: scoped_tasks.overdue.count,
      due_today_tasks: scoped_tasks.due_today.count
    }
  end

  def frame_id
    @patient ? 'patient_task_form' : 'task_form'
  end
  helper_method :frame_id
end
