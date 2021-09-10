class Add2022v1p1SpecItems < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :NativeHIPacific, :integer
    add_column :Client, :NoSingleGender, :integer
    add_column :Enrollments, :HOHLeaseholder, :integer
    rename_column :Event, :LocationCrisisorPHHousing, :LocationCrisisOrPHHousing
    rename_column :HealthAndDv, :SupportfromOthers, :SupportFromOthers
    change_column :CurrentLivingSituations, :VerifiedBy, :string, limit: 100
    change_column :AssessmentQuestions, :AssessmentAnswer, :string, limit: 500
  end
end
