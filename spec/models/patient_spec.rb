# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Patient, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:date_of_birth) }
    it { should validate_presence_of(:medical_record_number) }
    it { should validate_presence_of(:status) }

    it { should validate_length_of(:first_name).is_at_least(2).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_least(2).is_at_most(50) }
    it { should validate_length_of(:medical_record_number).is_at_least(5).is_at_most(20) }

    it { should validate_uniqueness_of(:medical_record_number) }

    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }

    it { should allow_value('1234567890').for(:phone) }
    it { should_not allow_value('123').for(:phone) }
    it { should_not allow_value('abc1234567').for(:phone) }
  end

  describe 'enums' do
    it do
      should define_enum_for(:status)
        .with_values(active: 'active', inactive: 'inactive')
        .backed_by_column_of_type(:string)
    end
  end

  # Associations will be tested after Message and Task models are created
  # describe 'associations' do
  #   it { should have_many(:messages).dependent(:destroy) }
  #   it { should have_many(:tasks).dependent(:destroy) }
  # end

  describe 'scopes' do
    let!(:active_patient) { create(:patient, :active) }
    let!(:inactive_patient) { create(:patient, :inactive) }

    describe '.active' do
      it 'returns only active patients' do
        expect(Patient.active).to include(active_patient)
        expect(Patient.active).not_to include(inactive_patient)
      end
    end

    describe '.inactive' do
      it 'returns only inactive patients' do
        expect(Patient.inactive).to include(inactive_patient)
        expect(Patient.inactive).not_to include(active_patient)
      end
    end

    describe '.by_name' do
      it 'orders by last name then first name' do
        Patient.destroy_all # Clear existing data
        patient1 = create(:patient, first_name: 'John', last_name: 'Doe')
        patient2 = create(:patient, first_name: 'Jane', last_name: 'Doe')
        patient3 = create(:patient, first_name: 'Alice', last_name: 'Smith')

        expect(Patient.by_name.pluck(:first_name, :last_name)).to eq([['Jane', 'Doe'], ['John', 'Doe'], ['Alice', 'Smith']])
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        Patient.destroy_all # Clear existing data
        patient1 = create(:patient)
        patient2 = create(:patient)

        expect(Patient.recent.first).to eq(patient2)
        expect(Patient.recent.last).to eq(patient1)
      end
    end
  end

  describe 'instance methods' do
    let(:patient) { build(:patient, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns the full name' do
        expect(patient.full_name).to eq('John Doe')
      end
    end

    describe '#age' do
      it 'calculates age correctly' do
        patient.date_of_birth = 25.years.ago
        expect(patient.age).to eq(25)
      end

      it 'returns nil if date_of_birth is nil' do
        patient.date_of_birth = nil
        expect(patient.age).to be_nil
      end
    end
  end
end

RSpec.describe Patient, 'factory' do
  it 'creates a valid patient' do
    patient = build(:patient)
    expect(patient).to be_valid
  end

  it 'creates an inactive patient' do
    patient = build(:patient, :inactive)
    expect(patient).to be_valid
    expect(patient.status).to eq('inactive')
  end

  # These tests will be enabled after Message and Task models are created
  # it 'creates a patient with messages' do
  #   patient = create(:patient, :with_messages)
  #   expect(patient.messages.count).to eq(3)
  # end

  # it 'creates a patient with tasks' do
  #   patient = create(:patient, :with_tasks)
  #   expect(patient.tasks.count).to eq(2)
  # end
end
