# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts '🌱 Starting seed data creation...'

# Clear existing data
puts '🧹 Clearing existing data...'
User.destroy_all
Patient.destroy_all
Message.destroy_all
Task.destroy_all

# Create Admin Users
puts '👨‍💼 Creating admin users...'
admin_users = [
  { email: 'admin@telehealth-crm.com', first_name: 'John', last_name: 'Smith' },
  { email: 'sarah.johnson@telehealth-crm.com', first_name: 'Sarah', last_name: 'Johnson' },
  { email: 'michael.brown@telehealth-crm.com', first_name: 'Michael', last_name: 'Brown' },
  { email: 'emily.davis@telehealth-crm.com', first_name: 'Emily', last_name: 'Davis' },
  { email: 'david.wilson@telehealth-crm.com', first_name: 'David', last_name: 'Wilson' },
  { email: 'lisa.garcia@telehealth-crm.com', first_name: 'Lisa', last_name: 'Garcia' },
  { email: 'robert.martinez@telehealth-crm.com', first_name: 'Robert', last_name: 'Martinez' }
]

admin_users.each do |admin_data|
  User.create!(
    email: admin_data[:email],
    password: 'password123',
    password_confirmation: 'password123',
    role: 'admin'
  )
end

puts "✅ Created #{User.admins.count} admin users"

# Create Patient Users
puts '👥 Creating patient users...'
patient_users = []
10.times do
  patient_users << User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    password_confirmation: 'password123',
    role: 'patient'
  )
end

puts "✅ Created #{User.patients.count} patient users"

# Create Patients
puts '🏥 Creating patients...'
patients = []
25.times do
  patients << Patient.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.unique.email,
    phone: Faker::PhoneNumber.subscriber_number(length: 10),
    date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 90),
    medical_record_number: "MR#{Faker::Number.unique.between(from: 10_000_000, to: 99_999_999)}",
    status: %w[active inactive].sample
  )
end

puts "✅ Created #{Patient.count} patients"

# Create Messages
puts '💬 Creating messages...'
message_templates = [
  "Hello, I hope you're feeling better today. Please let me know if you have any questions about your treatment plan.",
  'I wanted to follow up on your recent appointment. How are you feeling?',
  'Please remember to take your medication as prescribed. Contact us if you experience any side effects.',
  "Your test results are in. I'll call you to discuss them in detail.",
  "I'm checking in to see how your recovery is progressing. Please update me on your condition.",
  "Thank you for your patience. I'll have an update on your case by tomorrow.",
  'Please schedule your next appointment at your earliest convenience.',
  'I wanted to share some additional resources that might be helpful for your condition.',
  'Your insurance has been processed. You should receive confirmation within 2-3 business days.',
  "I'm here if you need to discuss any concerns about your treatment."
]

# Create messages for each patient
patients.each do |patient|
  # Random number of messages (2-8 per patient)
  message_count = rand(2..8)
  admin = User.admins.sample

  message_count.times do |i|
    # Alternate between incoming and outgoing messages
    message_type = i.even? ? 'incoming' : 'outgoing'
    user = message_type == 'incoming' ? User.patients.sample : admin

    Message.create!(
      patient: patient,
      user: user,
      content: message_templates.sample,
      message_type: message_type,
      created_at: rand(1..90).days.ago
    )
  end
end

puts "✅ Created #{Message.count} messages"

# Create Tasks
puts '📋 Creating tasks...'
task_templates = [
  { title: 'Follow up on test results', description: 'Review and discuss lab results with patient' },
  { title: 'Schedule follow-up appointment', description: 'Book next appointment based on treatment plan' },
  { title: 'Review medication compliance', description: 'Check if patient is taking medications as prescribed' },
  { title: 'Insurance verification', description: 'Verify insurance coverage for upcoming procedures' },
  { title: 'Patient education materials', description: 'Provide educational resources about condition' },
  { title: 'Referral to specialist', description: 'Coordinate referral to appropriate specialist' },
  { title: 'Treatment plan update', description: "Review and update patient's treatment plan" },
  { title: 'Discharge planning', description: 'Prepare discharge instructions and follow-up care' },
  { title: 'Medication adjustment', description: 'Review and adjust medication dosages if needed' },
  { title: 'Patient check-in call', description: 'Call patient to check on their condition' },
  { title: 'Documentation review', description: 'Review and update patient documentation' },
  { title: 'Care coordination', description: 'Coordinate care with other healthcare providers' }
]

# Create tasks for each patient
patients.each do |patient|
  # Random number of tasks (1-5 per patient)
  task_count = rand(1..5)
  admin = User.admins.sample

  task_count.times do
    template = task_templates.sample
    due_date = rand(1..30).days.from_now
    status = rand < 0.7 ? 'pending' : 'completed' # 70% pending, 30% completed
    completed_at = status == 'completed' ? rand(1..7).days.ago : nil

    Task.create!(
      patient: patient,
      user: admin,
      title: template[:title],
      description: template[:description],
      status: status,
      due_date: due_date,
      completed_at: completed_at,
      created_at: rand(1..60).days.ago
    )
  end
end

puts "✅ Created #{Task.count} tasks"

# Create some overdue tasks
puts '⚠️  Creating overdue tasks...'
overdue_count = 0
Task.pending.each do |task|
  next unless rand < 0.2 # 20% chance of being overdue

  task.update!(
    due_date: rand(1..14).days.ago,
    created_at: rand(15..45).days.ago
  )
  overdue_count += 1
end

puts "✅ Created #{overdue_count} overdue tasks"

# Create some tasks due today
puts '📅 Creating tasks due today...'
today_count = 0
Task.pending.each do |task|
  if rand < 0.15 # 15% chance of being due today
    task.update!(due_date: Date.current.end_of_day)
    today_count += 1
  end
end

puts "✅ Created #{today_count} tasks due today"

# Summary
puts "\n🎉 Seed data creation complete!"
puts '📊 Summary:'
puts "   👨‍💼 Admin users: #{User.admins.count}"
puts "   👥 Patient users: #{User.patients.count}"
puts "   🏥 Patients: #{Patient.count}"
puts "   💬 Messages: #{Message.count}"
puts "   📋 Total tasks: #{Task.count}"
puts "   ⏰ Pending tasks: #{Task.pending.count}"
puts "   ✅ Completed tasks: #{Task.completed.count}"
puts "   ⚠️  Overdue tasks: #{Task.overdue.count}"
puts "   📅 Due today: #{Task.due_today.count}"

puts "\n🔑 Default admin login:"
puts '   Email: admin@telehealth-crm.com'
puts '   Password: password123'

puts "\n🔑 Default patient login:"
puts "   Email: #{User.patients.first.email}"
puts '   Password: password123'

puts "\n✨ You can now run 'bin/rails server' and 'bin/rails sidekiq' to start the application!"
