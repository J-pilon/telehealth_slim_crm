# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    patient
    user
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    status { 'pending' }
    due_date { 1.week.from_now }

    trait :completed do
      status { 'completed' }
      completed_at { 1.day.ago }
    end

    trait :overdue do
      status { 'pending' }
      due_date { 1.day.ago }
    end

    trait :due_today do
      due_date { Date.current.end_of_day }
    end

    trait :due_tomorrow do
      due_date { 1.day.from_now }
    end

    trait :urgent do
      due_date { 1.hour.from_now }
    end

    trait :with_messages do
      after(:create) do |task|
        create_list(:message, 3, patient: task.patient, user: task.user)
      end
    end
  end
end
