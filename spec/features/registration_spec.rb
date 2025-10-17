# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  describe 'Patient Registration' do
    it 'allows patients to register with default role' do
      visit new_user_registration_path

      fill_in 'Email', with: 'newpatient@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      expect do
        click_button 'Create account'
      end.to change(User, :count).by(1)

      user = User.find_by(email: 'newpatient@example.com')
      expect(user.role).to eq('patient')
      expect(user.patient).to be_present
      expect(user.patient.email).to eq('newpatient@example.com')
      expect(user.patient.first_name).to eq('New')
      expect(user.patient.last_name).to eq('Patient')
    end

    it 'redirects to dashboard after successful registration' do
      visit new_user_registration_path

      fill_in 'Email', with: 'newpatient@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      click_button 'Create account'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('Welcome! You have signed up successfully.')
    end

    it 'shows validation errors for invalid input' do
      visit new_user_registration_path

      fill_in 'Email', with: 'invalid-email'
      fill_in 'Password', with: '123'
      fill_in 'Password confirmation', with: '456'

      click_button 'Create account'

      # The form should stay on the registration page when there are errors
      expect(page).to have_current_path(new_user_registration_path)
      expect(page).to have_content('Create your account')
    end
  end

  describe 'Registration UI' do
    it 'has styled form with Tailwind CSS' do
      visit new_user_registration_path

      expect(page).to have_css('.min-h-screen.flex.items-center.justify-center')
      expect(page).to have_css('.bg-white.shadow.rounded-lg')
      expect(page).to have_css('.form-input')
      expect(page).to have_css('.btn-primary')
    end

    it 'has link to sign in page' do
      visit new_user_registration_path

      expect(page).to have_link('sign in to your existing account', href: new_user_session_path)
    end
  end
end
