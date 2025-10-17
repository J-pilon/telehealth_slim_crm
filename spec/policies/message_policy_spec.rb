# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessagePolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:other_patient) { create(:user, :patient) }
  let(:patient_record) { create(:patient) }
  let(:message) { create(:message, patient: patient_record, user: admin) }

  describe '#index?' do
    it 'allows logged in users' do
      expect(described_class.new(admin, Message).index?).to be true
      expect(described_class.new(patient_user, Message).index?).to be true
    end
  end

  describe '#show?' do
    it 'allows admins to view any message' do
      expect(described_class.new(admin, message).show?).to be true
    end

    it 'allows patients to view messages' do
      patient_message = create(:message, patient: patient_record, user: patient_user)
      expect(described_class.new(patient_user, patient_message).show?).to be true
    end
  end

  describe '#create?' do
    it 'allows logged in users' do
      expect(described_class.new(admin, Message).create?).to be true
      expect(described_class.new(patient_user, Message).create?).to be true
    end
  end

  describe '#update?' do
    it 'allows admins to update any message' do
      expect(described_class.new(admin, message).update?).to be true
    end

    it 'allows patients to update their own messages' do
      patient_message = create(:message, patient: patient_record, user: patient_user)
      expect(described_class.new(patient_user, patient_message).update?).to be true
    end

    it 'denies patients from updating other users messages' do
      expect(described_class.new(patient_user, message).update?).to be false
    end
  end

  describe '#destroy?' do
    it 'allows admins' do
      expect(described_class.new(admin, message).destroy?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, message).destroy?).to be false
    end
  end

  describe 'Scope' do
    it 'returns all messages for admins' do
      create_list(:message, 3)
      expect(MessagePolicy::Scope.new(admin, Message).resolve.count).to eq(3)
    end

    it 'returns only patient own messages for patients' do
      patient_messages = create_list(:message, 2, patient: patient_record, user: patient_user)
      create(:message, patient: create(:patient), user: admin)

      expect(MessagePolicy::Scope.new(patient_user, Message).resolve.count).to eq(2)
      expect(MessagePolicy::Scope.new(patient_user, Message).resolve).to include(*patient_messages)
    end
  end
end
