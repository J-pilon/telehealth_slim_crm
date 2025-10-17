# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:other_patient) { create(:user, :patient) }
  let(:patient_record) { create(:patient) }
  let(:task) { create(:task, patient: patient_record) }

  describe '#index?' do
    it 'allows logged in users' do
      expect(described_class.new(admin, Task).index?).to be true
      expect(described_class.new(patient_user, Task).index?).to be true
    end
  end

  describe '#show?' do
    it 'allows admins to view any task' do
      expect(described_class.new(admin, task).show?).to be true
    end

    it 'allows patients to view tasks' do
      patient_task = create(:task, patient: patient_record)
      expect(described_class.new(patient_user, patient_task).show?).to be true
    end
  end

  describe '#create?' do
    it 'allows admins' do
      expect(described_class.new(admin, Task).create?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, Task).create?).to be false
    end
  end

  describe '#update?' do
    it 'allows admins to update any task' do
      expect(described_class.new(admin, task).update?).to be true
    end

    it 'allows patients to update tasks' do
      patient_task = create(:task, patient: patient_record)
      expect(described_class.new(patient_user, patient_task).update?).to be true
    end
  end

  describe '#destroy?' do
    it 'allows admins' do
      expect(described_class.new(admin, task).destroy?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, task).destroy?).to be false
    end
  end

  describe 'Scope' do
    it 'returns all tasks for admins' do
      create_list(:task, 3)
      expect(TaskPolicy::Scope.new(admin, Task).resolve.count).to eq(3)
    end

    it 'returns no tasks for patients' do
      create_list(:task, 2, patient: patient_record)
      create(:task, patient: create(:patient))

      expect(TaskPolicy::Scope.new(patient_user, Task).resolve.count).to eq(0)
    end
  end
end
