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
      # rails 6.1 doesn't handle null lock_version reliably
      add_column table, :lock_version, :integer, null: false, default: 0
    end
  end
end
