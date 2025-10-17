class AddUserToPatients < ActiveRecord::Migration[7.2]
  def change
    add_reference :patients, :user, null: true, foreign_key: true
  end
end
