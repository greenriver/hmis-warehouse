class AddFileToParticipationForms < ActiveRecord::Migration
  def change
    add_column :participation_forms, :file, :string
  end
end
