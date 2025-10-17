# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatientPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:patient_user) { create(:user, :patient) }
  let(:other_patient) { create(:user, :patient) }
  let(:patient_record) { create(:patient) }

  describe '#index?' do
    it 'allows admins' do
      expect(described_class.new(admin, Patient).index?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, Patient).index?).to be false
    end
  end

  describe '#show?' do
    it 'allows admins to view any patient' do
      expect(described_class.new(admin, patient_record).show?).to be true
    end

    it 'denies patients from viewing patient records' do
      expect(described_class.new(patient_user, patient_record).show?).to be false
    end
  end

  describe '#create?' do
    it 'allows admins' do
      expect(described_class.new(admin, Patient).create?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, Patient).create?).to be false
    end
  end

  describe '#update?' do
    it 'allows admins' do
      expect(described_class.new(admin, patient_record).update?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, patient_record).update?).to be false
    end
  end

  describe '#destroy?' do
    it 'allows admins' do
      expect(described_class.new(admin, patient_record).destroy?).to be true
    end

    it 'denies patients' do
      expect(described_class.new(patient_user, patient_record).destroy?).to be false
    end
  end

  describe 'Scope' do
    it 'returns all patients for admins' do
      create_list(:patient, 3)
      expect(PatientPolicy::Scope.new(admin, Patient).resolve.count).to eq(3)
    end

    it 'returns no patients for patients' do
      create_list(:patient, 3)
      expect(PatientPolicy::Scope.new(patient_user, Patient).resolve.count).to eq(0)
    end
  end
end
