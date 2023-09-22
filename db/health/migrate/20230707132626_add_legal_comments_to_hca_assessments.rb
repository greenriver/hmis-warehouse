class AddLegalCommentsToHcaAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :hca_assessments, :legal_comments, :string
  end
end
