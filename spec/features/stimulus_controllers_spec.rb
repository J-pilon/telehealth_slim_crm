# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Stimulus Controllers', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:patient) { create(:patient) }

  before do
    sign_in admin
  end

  describe 'Patient Search Controller' do
    before do
      create(:patient, first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      create(:patient, first_name: 'Jane', last_name: 'Smith', email: 'jane@example.com')
    end

    it 'has the correct data attributes for Stimulus controller' do
      visit patients_path

      # Check that the search container has the patient-search controller
      search_container = find('[data-controller="patient-search"]')
      expect(search_container).to be_present

      # Check that the input has the correct target
      search_input = find('input[data-patient-search-target="input"]')
      expect(search_input).to be_present

      # Check that the results container exists
      results_container = find('[data-patient-search-target="results"]')
      expect(results_container).to be_present
    end

    it 'shows search results when typing' do
      visit patients_path

      search_input = find('input[data-patient-search-target="input"]')
      search_input.fill_in with: 'John'

      # Wait for search results to appear
      expect(page).to have_content('John Doe')
      expect(page).to have_content('john@example.com')
    end
  end

  describe 'Notification Controller' do
    it 'has the correct data attributes for Stimulus controller' do
      visit root_path

      # Check that the notification container exists
      notification_container = find('[data-controller="notification"]')
      expect(notification_container).to be_present

      # Check that the message element exists
      message_element = find('[data-notification-target="message"]')
      expect(message_element).to be_present
    end
  end
end
