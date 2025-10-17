# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
  end

  describe 'enums' do
    it do
      expect(subject).to define_enum_for(:status)
        .with_values(pending: 'pending', completed: 'completed')
        .backed_by_column_of_type(:string)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:patient) }
  end

  describe 'scopes' do
    let!(:pending_task) { create(:task, :pending) }
    let!(:completed_task) { create(:task, :completed) }
    let!(:overdue_task) { create(:task, :overdue) }
    let!(:due_today_task) { create(:task, :due_today) }

    describe '.pending' do
      it 'returns only pending tasks' do
        expect(described_class.pending).to include(pending_task)
        expect(described_class.pending).not_to include(completed_task)
      end
    end

    describe '.completed' do
      it 'returns only completed tasks' do
        expect(described_class.completed).to include(completed_task)
        expect(described_class.completed).not_to include(pending_task)
      end
    end

    describe '.overdue' do
      it 'returns only overdue pending tasks' do
        described_class.destroy_all # Clear existing data
        overdue_task = create(:task, :overdue)
        completed_task = create(:task, :completed)
        due_today_task = create(:task, due_date: Date.current.end_of_day)

        expect(described_class.overdue).to include(overdue_task)
        expect(described_class.overdue).not_to include(completed_task)
        expect(described_class.overdue).not_to include(due_today_task)
      end
    end

    describe '.due_today' do
      it 'returns tasks due today' do
        expect(described_class.due_today).to include(due_today_task)
      end
    end
  end

  describe 'callbacks' do
    it 'sets completed_at when status changes to completed' do
      task = create(:task, :pending)
      expect(task.completed_at).to be_nil

      task.update!(status: 'completed')
      expect(task.completed_at).not_to be_nil
    end

    it 'clears completed_at when status changes to pending' do
      task = create(:task, :completed)
      expect(task.completed_at).not_to be_nil

      task.update!(status: 'pending')
      expect(task.completed_at).to be_nil
    end
  end
end

RSpec.describe Task, 'instance methods' do
  let(:task) { create(:task, due_date: 1.day.ago) }

  describe '#overdue?' do
    it 'returns true for overdue pending tasks' do
      expect(task.overdue?).to be true
    end

    it 'returns false for completed tasks' do
      task.update!(status: 'completed')
      expect(task.overdue?).to be false
    end
  end

  describe '#due_today?' do
    it 'returns true for tasks due today' do
      task.update!(due_date: Date.current)
      expect(task.due_today?).to be true
    end

    it 'returns false for tasks due tomorrow' do
      task.update!(due_date: 1.day.from_now)
      expect(task.due_today?).to be false
    end
  end

  describe '#completion_time' do
    it 'returns nil for pending tasks' do
      expect(task.completion_time).to be_nil
    end

    it 'returns completion time for completed tasks' do
      task.update!(status: 'completed')
      expect(task.completion_time).to be > 0
    end
  end

  describe '#days_overdue' do
    it 'returns days overdue for overdue tasks' do
      expect(task.days_overdue).to be > 0
    end

    it 'returns 0 for non-overdue tasks' do
      task.update!(due_date: 1.day.from_now)
      expect(task.days_overdue).to eq(0)
    end
  end
end

RSpec.describe Task, 'factory' do
  it 'creates a valid task' do
    task = build(:task)
    expect(task).to be_valid
  end

  it 'creates a completed task' do
    task = build(:task, :completed)
    expect(task).to be_valid
    expect(task.status).to eq('completed')
    expect(task.completed_at).not_to be_nil
  end

  it 'creates an overdue task' do
    task = build(:task, :overdue)
    expect(task).to be_valid
    expect(task.overdue?).to be true
  end
end
