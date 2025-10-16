# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    patient
    user
    content { Faker::Lorem.paragraph(sentence_count: 2) }
    message_type { 'outgoing' }

    trait :incoming do
      message_type { 'incoming' }
    end

    trait :outgoing do
      message_type { 'outgoing' }
    end

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 1.week.ago }
    end
  end
end
