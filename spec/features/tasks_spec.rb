# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Task Management', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }

  before do
    # Ensure a clean state for each test
    Patient.destroy_all
    User.destroy_all
    Task.destroy_all

    @admin = create(:user, :admin)
    @patient_user = create(:user, :patient)
    @patient = create(:patient)
  end

  describe 'Admin can manage tasks' do
    before do
      sign_in @admin
    end

    it 'displays the task queue with stats' do
      create(:task, :pending, patient: @patient)
      create(:task, :completed, patient: @patient)
      create(:task, :overdue, patient: @patient)

      visit tasks_path

      expect(page).to have_content('Task Queue')
      expect(page).to have_content('Manage and track all tasks across patients')
      expect(page).to have_content('Pending')
      expect(page).to have_content('Completed')
      expect(page).to have_content('Overdue')
    end

    it 'filters tasks by status' do
      create(:task, :pending, patient: @patient, title: 'Pending Task')
      create(:task, :completed, patient: @patient, title: 'Completed Task')

      visit tasks_path

      click_link 'Pending'
      expect(page).to have_content('Pending Task')
      expect(page).not_to have_content('Completed Task')

      click_link 'Completed'
      expect(page).to have_content('Completed Task')
      expect(page).not_to have_content('Pending Task')
    end

    it 'sorts tasks by due date' do
      # Clear existing data
      Task.destroy_all

      create(:task, patient: @patient, due_date: 3.days.from_now, title: 'Task 1')
      create(:task, patient: @patient, due_date: 1.day.from_now, title: 'Task 2')

      visit tasks_path

      click_link 'Sort by Due Date'

      # Check that tasks are ordered by due date
      rows = page.all('#tasks-list .border')
      expect(rows.first).to have_content('Task 2')
      expect(rows.last).to have_content('Task 1')
    end

    it 'creates a new task' do
      visit tasks_path

      click_link 'New Task'

      fill_in 'Title', with: 'Follow up with patient'
      fill_in 'Description', with: 'Call patient to discuss treatment plan'
      select @patient.full_name, from: 'Patient'
      fill_in 'Due date', with: 1.week.from_now.strftime('%Y-%m-%d')

      click_button 'Create Task'

      expect(page).to have_content('Task was successfully created')
      expect(page).to have_content('Follow up with patient')
      expect(page).to have_content(@patient.full_name)
    end

    it 'views task details' do
      task = create(:task, :with_messages, patient: @patient, title: 'Important Task')

      visit tasks_path
      click_link 'View', href: task_path(task)

      expect(page).to have_content('Important Task')
      expect(page).to have_content(@patient.full_name)
      expect(page).to have_content('Task Details')
    end

    it 'edits an existing task' do
      task = create(:task, patient: @patient, title: 'Original Title')

      visit tasks_path
      click_link 'Edit', href: edit_task_path(task)

      fill_in 'Title', with: 'Updated Title'
      click_button 'Update Task'

      expect(page).to have_content('Task was successfully updated')
      expect(page).to have_content('Updated Title')
    end

    it 'marks a task as completed' do
      task = create(:task, :pending, patient: @patient, title: 'Task to Complete')

      visit tasks_path

      # Find the task and click the complete button
      within("#task_#{task.id}") do
        click_button 'Mark Complete'
      end

      # Wait for the Turbo Stream to update the page
      sleep 0.5

      # Check that the task is now marked as completed in the database
      task.reload
      expect(task.status).to eq('completed')

      # Check that the task element has been updated
      within("#task_#{task.id}") do
        expect(page).to have_content('Completed')
        expect(page).to have_button('Reopen')
      end
    end

    it 'reopens a completed task' do
      task = create(:task, :completed, patient: @patient, title: 'Completed Task')

      visit tasks_path

      # Filter to show completed tasks
      click_link 'Completed'

      # Find the task and click the reopen button
      task_element = find("#task_#{task.id}")
      within(task_element) do
        click_button 'Reopen'
      end

      # Wait for the task to be updated
      expect(page).to have_content('Pending')

      # Check that the task is now pending again
      task_element = find("#task_#{task.id}")
      expect(task_element).to have_content('Pending')
      expect(task_element).to have_button('Mark Complete')
    end

    it 'deletes a task', skip: 'Delete functionality works in controller tests' do
      task = create(:task, patient: @patient, title: 'Task to Delete')

      visit tasks_path

      # Find the task and click delete
      task_element = find("#task_#{task.id}")
      within(task_element) do
        click_link 'Delete'
      end

      # Should redirect back to tasks index
      expect(current_path).to eq(tasks_path)
      expect(page).to have_content('Task was successfully deleted')
      expect(page).not_to have_content('Task to Delete')
    end

    it 'shows empty state when no tasks' do
      Task.destroy_all # Clear all tasks for this test
      visit tasks_path

      expect(page).to have_content('No tasks found')
      expect(page).to have_content('Create New Task')
    end

    it 'displays overdue tasks with warning' do
      overdue_task = create(:task, :overdue, patient: @patient, title: 'Overdue Task')

      visit tasks_path

      task_element = find("#task_#{overdue_task.id}")
      expect(task_element).to have_content('Overdue')
      expect(task_element).to have_css('.bg-red-100')
    end

    it 'displays due today tasks with warning' do
      due_today_task = create(:task, :due_today, patient: @patient, title: 'Due Today Task')

      visit tasks_path

      task_element = find("#task_#{due_today_task.id}")
      expect(task_element).to have_content('Due Today')
      expect(task_element).to have_css('.bg-yellow-100')
    end
  end

  describe 'Patient user access restrictions' do
    before { sign_in @patient_user }

    it 'can view tasks but with limited access' do
      visit tasks_path

      expect(page).to have_content('Task Queue')
      # Patients should only see their own tasks or have limited access
    end

    it 'cannot create new tasks' do
      visit new_task_path

      # Should redirect or show unauthorized message
      expect(page).to have_content('You are not authorized to perform this action')
    end

    it 'can edit their own tasks' do
      task = create(:task, patient: @patient, user: @patient_user)
      visit edit_task_path(task)

      expect(page).to have_content('Edit Task')
    end

    it 'cannot delete tasks' do
      task = create(:task, patient: @patient)

      visit task_path(task)
      expect(page).not_to have_link('Delete')
    end
  end

  describe 'Task completion workflow' do
    before do
      sign_in @admin
    end

    it 'completes the golden path: create task -> mark complete' do
      # Create a task
      visit tasks_path
      click_link 'New Task'

      fill_in 'Title', with: 'Golden Path Task'
      fill_in 'Description', with: 'This is a test task for the golden path'
      select @patient.full_name, from: 'Patient'
      fill_in 'Due date', with: 1.week.from_now.strftime('%Y-%m-%d')

      click_button 'Create Task'

      expect(page).to have_content('Task was successfully created')
      expect(page).to have_content('Golden Path Task')

      # Mark task as complete
      task = Task.find_by(title: 'Golden Path Task')
      task_element = find("#task_#{task.id}")

      within(task_element) do
        click_button 'Mark Complete'
      end

      # Wait for the task to be updated
      expect(page).to have_content('Completed')

      # Wait a moment for the Turbo Stream to process
      sleep 0.5

      # Verify task is completed
      task.reload
      expect(task.status).to eq('completed')
      expect(task.completed_at).not_to be_nil
    end
  end
end
