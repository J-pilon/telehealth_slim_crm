# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :edit, :update, :destroy]

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
    @tasks = @tasks.page(params[:page]).per(20)

    # Stats for dashboard
    @stats = {
      total_tasks: Task.count,
      pending_tasks: Task.pending.count,
      completed_tasks: Task.completed.count,
      overdue_tasks: Task.overdue.count,
      due_today_tasks: Task.due_today.count
    }
  end

  def show
    authorize @task
  end

  def new
    @task = Task.new
    @task.patient_id = params[:patient_id] if params[:patient_id]
    authorize @task
  end

  def create
    @task = Task.new(task_params)
    @task.user = current_user
    authorize @task

    respond_to do |format|
      if @task.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend('tasks-list', partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', html: Task.pending.count),
            turbo_stream.replace('task-form', partial: 'tasks/form', locals: { task: Task.new })
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task was successfully created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('task-form', partial: 'tasks/form', locals: { task: @task })
        end
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def edit
    authorize @task
  end

  def update
    authorize @task

    respond_to do |format|
      if @task.update(task_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', html: Task.pending.count)
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task was successfully updated.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("task_#{@task.id}", partial: 'tasks/form', locals: { task: @task })
        end
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @task
    @task.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("task_#{@task.id}"),
          turbo_stream.update('task-count', html: Task.pending.count)
        ]
      end
      format.html { redirect_to tasks_path, notice: 'Task was successfully deleted.' }
    end
  end

  def complete
    @task = Task.find(params[:id])
    authorize @task

    respond_to do |format|
      if @task.update(status: 'completed')
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', html: Task.pending.count)
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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: 'tasks/task', locals: { task: @task }),
            turbo_stream.update('task-count', html: Task.pending.count)
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
end
