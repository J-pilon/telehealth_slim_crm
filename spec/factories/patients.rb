# frozen_string_literal: true

FactoryBot.define do
  factory :patient do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone.gsub(/\D/, '')[0, 10] }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 80) }
    medical_record_number { "MR#{Faker::Number.number(digits: 8)}" }
    status { 'active' }

    trait :inactive do
      status { 'inactive' }
    end

    trait :with_messages do
      after(:create) do |patient|
        create_list(:message, 3, patient: patient)
      end
    end

    trait :with_tasks do
      after(:create) do |patient|
        create_list(:task, 2, patient: patient)
      end
    end
  end
end
