# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }

  describe 'Admin Dashboard' do
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

    it 'displays admin dashboard with stats' do
      visit root_path

      expect(page).to have_content('Welcome to Telehealth CRM')
      expect(page).to have_content('Total Patients')
      expect(page).to have_content('Active Patients')
      expect(page).to have_content('Pending Tasks')
      expect(page).to have_content('Overdue Tasks')
    end

    it 'shows recent patients' do
      visit root_path

      expect(page).to have_content('Recent Patients')
      # Check that we have recent patients displayed (at least 3)
      expect(page).to have_css('.bg-gray-50', minimum: 3)
    end

    it 'shows pending tasks' do
      visit root_path

      expect(page).to have_content('Pending Tasks')
      expect(page).to have_content(Task.first.title)
    end

    it 'shows overdue tasks alert' do
      visit root_path

      expect(page).to have_content('Overdue Tasks')
      expect(page).to have_content('You have 2 overdue tasks')
    end

    it 'displays correct stats numbers' do
      visit root_path

      expect(page).to have_content('5') # Total patients
      expect(page).to have_content('3') # Active patients
      expect(page).to have_content('5') # Pending tasks
      expect(page).to have_content('2') # Overdue tasks
    end
  end

  describe 'Patient Dashboard' do
    before do
      sign_in patient_user
    end

    it 'displays patient dashboard' do
      visit root_path

      expect(page).to have_content('Welcome to Telehealth CRM')
      expect(page).to have_content('My Messages')
      expect(page).to have_content('My Tasks')
      expect(page).to have_content('Quick Actions')
    end

    it 'shows zero counts for patient stats' do
      visit root_path

      expect(page).to have_content('You have 0 messages')
      expect(page).to have_content('You have 0 pending tasks')
    end

    it 'shows patient-specific quick actions' do
      visit root_path

      expect(page).to have_content('Send Message')
      expect(page).to have_link('Send Message', href: patient_messages_path(patient_user.patient))
      expect(page).to have_content('View My Profile')
      expect(page).to have_link('View My Profile', href: patient_path(patient_user.patient))
    end
  end

  describe 'Navigation' do
    before do
      sign_in admin
    end

    it 'shows admin navigation links' do
      visit root_path

      expect(page).to have_link('Dashboard')
      expect(page).to have_link('Patients')
      expect(page).to have_link('Tasks')
    end

    it 'shows user email and role in navigation' do
      visit root_path

      expect(page).to have_content(admin.email)
      expect(page).to have_content('Admin')
    end

    it 'has sign out button' do
      visit root_path

      expect(page).to have_button('Sign Out')
    end
  end
end
