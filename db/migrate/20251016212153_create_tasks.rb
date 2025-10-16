class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :status
      t.datetime :due_date
      t.datetime :completed_at

      t.timestamps
    end
  end
end
