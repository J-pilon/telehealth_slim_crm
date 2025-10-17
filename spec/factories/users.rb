# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'admin' }

    trait :admin do
      role { 'admin' }
    end

    trait :patient do
      role { 'patient' }

      after(:create) do |user|
        create(:patient, user: user, email: user.email)
      end
    end
  end
end
