# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:message_type) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(2000) }
  end

  describe 'enums' do
    it do
      should define_enum_for(:message_type)
        .with_values(incoming: 'incoming', outgoing: 'outgoing')
        .backed_by_column_of_type(:string)
    end
  end

  describe 'associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    let!(:message1) { create(:message, :recent) }
    let!(:message2) { create(:message, :old) }
    let!(:incoming_message) { create(:message, :incoming) }
    let!(:outgoing_message) { create(:message, :outgoing) }

    describe '.recent' do
      it 'orders by created_at desc' do
        Message.destroy_all # Clear existing data
        message1 = create(:message, :recent)
        message2 = create(:message, :old)

        expect(Message.recent.first).to eq(message1)
      end
    end

    describe '.incoming' do
      it 'returns only incoming messages' do
        expect(Message.incoming).to include(incoming_message)
        expect(Message.incoming).not_to include(outgoing_message)
      end
    end

    describe '.outgoing' do
      it 'returns only outgoing messages' do
        expect(Message.outgoing).to include(outgoing_message)
        expect(Message.outgoing).not_to include(incoming_message)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient) }
    let(:message) { create(:message, user: user, patient: patient) }

    describe '#sender_name' do
      it 'returns the user email' do
        expect(message.sender_name).to eq(user.email)
      end
    end

    describe '#formatted_created_at' do
      it 'formats the created_at timestamp' do
        expect(message.formatted_created_at).to match(/\w+ \d+, \d+ at \d+:\d+ [AP]M/)
      end
    end

    describe '#is_recent?' do
      it 'returns true for recent messages' do
        # Create a message that was created 30 minutes ago
        recent_message = create(:message, created_at: 30.minutes.ago)
        expect(recent_message.is_recent?).to be true
      end

      it 'returns false for old messages' do
        old_message = create(:message, :old)
        expect(old_message.is_recent?).to be false
      end
    end
  end
end

RSpec.describe Message, 'factory' do
  it 'creates a valid message' do
    message = build(:message)
    expect(message).to be_valid
  end

  it 'creates an incoming message' do
    message = build(:message, :incoming)
    expect(message).to be_valid
    expect(message.message_type).to eq('incoming')
  end

  it 'creates an outgoing message' do
    message = build(:message, :outgoing)
    expect(message).to be_valid
    expect(message.message_type).to eq('outgoing')
  end
end
