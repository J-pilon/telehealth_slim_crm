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
    end
  end
end
