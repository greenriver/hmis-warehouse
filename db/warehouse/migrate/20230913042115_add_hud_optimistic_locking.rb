class AddHudOptimisticLocking < ActiveRecord::Migration[6.1]
  def change
    [
      #:Project,
      :Client,
      :Enrollment,
      :CustomAssessments,
    ].each do |table|
      add_column table, :lock_version, :integer
    end
  end
end
