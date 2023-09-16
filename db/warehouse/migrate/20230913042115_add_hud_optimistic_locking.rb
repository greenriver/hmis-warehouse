class AddHudOptimisticLocking < ActiveRecord::Migration[6.1]
  def change
    [
      # TODO: We may want locking on additional tables in the future
      # :Project,
      # :CurrentLivingSituation,
      :Client,
      :Enrollment,
      :CustomAssessments,
    ].each do |table|
      add_column table, :lock_version, :integer
    end
  end
end
