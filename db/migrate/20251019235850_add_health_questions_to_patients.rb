class AddHealthQuestionsToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :health_question_one, :text
    add_column :patients, :health_question_two, :text
    add_column :patients, :health_question_three, :text
  end
end
