# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe 'enums' do
    it do
      expect(subject).to define_enum_for(:role)
        .with_values(admin: 'admin', patient: 'patient')
        .backed_by_column_of_type(:string)
    end
  end

  describe 'scopes' do
    let!(:admin_user) { create(:user, :admin) }
    let!(:patient_user) { create(:user, :patient) }

    describe '.admins' do
      it 'returns only admin users' do
        expect(described_class.admins).to include(admin_user)
        expect(described_class.admins).not_to include(patient_user)
      end
    end

    describe '.patients' do
      it 'returns only patient users' do
        expect(described_class.patients).to include(patient_user)
        expect(described_class.patients).not_to include(admin_user)
      end
    end
  end
end

RSpec.describe User, 'factory' do
  it 'creates a valid user' do
    user = build(:user)
    expect(user).to be_valid
  end

  it 'creates a valid admin user' do
    user = build(:user, :admin)
    expect(user).to be_valid
    expect(user.role).to eq('admin')
  end

  it 'creates a valid patient user' do
    user = build(:user, :patient)
    expect(user).to be_valid
    expect(user.role).to eq('patient')
  end
end
