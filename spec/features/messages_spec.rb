# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages Management', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }

  before do
    # Ensure a clean state for each test
    Patient.destroy_all
    User.destroy_all
    Message.destroy_all

    @admin = create(:user, :admin)
    @patient_user = create(:user, :patient)
  end

  describe 'Admin can manage messages' do
    before do
      sign_in @admin
      @patient = create(:patient, first_name: 'John', last_name: 'Doe')
    end

    it 'displays message thread for a patient' do
      create(:message, :outgoing, patient: @patient, user: @admin, content: 'Hello John!')
      create(:message, :incoming, patient: @patient, user: @admin, content: 'Hi there!')

      visit patient_messages_path(@patient)

      expect(page).to have_content('Messages for John Doe')
      expect(page).to have_content('Hello John!')
      expect(page).to have_content('Hi there!')
      expect(page).to have_content('2 messages')
    end

    it 'creates a new outgoing message' do
      visit patient_messages_path(@patient)

      fill_in 'message[content]', with: 'How are you feeling today?'
      select 'Outgoing', from: 'message[message_type]'
      click_button 'Send Message'

      expect(page).to have_content('Message was successfully sent.')
      expect(page).to have_content('How are you feeling today?')
      expect(page).to have_content('1 message')
    end

    it 'creates a new incoming message' do
      visit patient_messages_path(@patient)

      fill_in 'message[content]', with: 'I am feeling better, thank you!'
      select 'Incoming', from: 'message[message_type]'
      click_button 'Send Message'

      expect(page).to have_content('Message was successfully sent.')
      expect(page).to have_content('I am feeling better, thank you!')
    end

    it 'shows empty state when no messages' do
      visit patient_messages_path(@patient)

      expect(page).to have_content('No messages yet. Start the conversation below.')
      expect(page).to have_content('0 messages')
    end

    it 'edits an existing message' do
      message = create(:message, :outgoing, patient: @patient, user: @admin, content: 'Original message')

      visit patient_messages_path(@patient)
      click_link 'Edit'

      within("#message_#{message.id}") do
        fill_in 'message[content]', with: 'Updated message content'
        select 'Outgoing', from: 'message[message_type]'
        click_button 'Update'
      end

      expect(page).to have_content('Message was successfully updated.')
      expect(page).to have_content('Updated message content')
    end

    it 'shows delete button for messages' do
      create(:message, :outgoing, patient: @patient, user: @admin, content: 'Message to delete')

      visit patient_messages_path(@patient)

      expect(page).to have_content('Message to delete')
      expect(page).to have_button('Delete')
    end

    it 'displays message types with different styling' do
      create(:message, :outgoing, patient: @patient, user: @admin, content: 'Outgoing message')
      create(:message, :incoming, patient: @patient, user: @admin, content: 'Incoming message')

      visit patient_messages_path(@patient)

      # Check that outgoing messages have blue styling
      expect(page).to have_css('.bg-blue-500', text: 'Outgoing message')
      # Check that incoming messages have gray styling
      expect(page).to have_css('.bg-gray-200', text: 'Incoming message')
    end

    it 'shows message timestamps' do
      message = create(:message, :outgoing, patient: @patient, user: @admin, content: 'Test message')

      visit patient_messages_path(@patient)

      expect(page).to have_content(message.formatted_created_at)
    end
  end

  describe 'Patient user message access' do
    before do
      sign_in @patient_user
      @patient = create(:patient)
    end

    it 'can access messages index' do
      visit patient_messages_path(@patient)
      expect(page).to have_content('Messages for')
      expect(current_path).to eq(patient_messages_path(@patient))
    end

    it 'can create messages' do
      visit patient_messages_path(@patient)

      fill_in 'message[content]', with: 'Test message from patient'
      select 'Outgoing', from: 'message[message_type]'
      click_button 'Send Message'

      expect(page).to have_content('Message was successfully sent.')
      expect(page).to have_content('Test message from patient')
    end
  end

  describe 'Navigation and links' do
    before do
      sign_in @admin
      @patient = create(:patient, first_name: 'Jane', last_name: 'Smith')
    end

    it 'has proper navigation links' do
      visit patient_messages_path(@patient)

      expect(page).to have_link('Back to Patient', href: patient_path(@patient))
      expect(page).to have_link('All Patients', href: patients_path)
    end

    it 'shows patient information in header' do
      visit patient_messages_path(@patient)

      expect(page).to have_content('Messages for Jane Smith')
      expect(page).to have_content("Medical Record ##{@patient.medical_record_number}")
    end
  end

  describe 'Message form validation' do
    before do
      sign_in @admin
      @patient = create(:patient)
    end

    it 'shows validation errors for empty content' do
      visit patient_messages_path(@patient)

      click_button 'Send Message'

      expect(page).to have_content("Content can't be blank")
    end

    it 'shows validation errors for missing message type' do
      visit patient_messages_path(@patient)

      fill_in 'message[content]', with: 'Test message'
      # Don't select message type
      click_button 'Send Message'

      expect(page).to have_content("Message type can't be blank")
    end
  end
end
