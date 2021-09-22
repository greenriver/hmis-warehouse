class Add2022v1p1SpecItems < ActiveRecord::Migration[5.2]
  def up
    Bi::ViewMaintainer.new.remove_views
    add_column :Client, :NativeHIPacific, :integer
    add_column :Client, :NoSingleGender, :integer
    add_column :Enrollment, :HOHLeaseholder, :integer
    rename_column :Event, :LocationCrisisorPHHousing, :LocationCrisisOrPHHousing
    rename_column :HealthAndDV, :SupportfromOthers, :SupportFromOthers
    change_column :CurrentLivingSituation, :VerifiedBy, :string, limit: 100
    change_column :AssessmentQuestions, :AssessmentAnswer, :string, limit: 500
  end

  def down
    remove_column :Client, :NativeHIPacific, :integer
    remove_column :Client, :NoSingleGender, :integer
    remove_column :Enrollment, :HOHLeaseholder, :integer
    rename_column :Event, :LocationCrisisOrPHHousing, :LocationCrisisorPHHousing
    rename_column :HealthAndDV, :SupportFromOthers, :SupportfromOthers
  end
end
