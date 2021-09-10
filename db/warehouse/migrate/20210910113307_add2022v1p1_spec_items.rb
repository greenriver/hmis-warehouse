class Add2022v1p1SpecItems < ActiveRecord::Migration[5.2]
  def change
    Bi::ViewMaintainer.new.remove_views
    add_column :Client, :NativeHIPacific, :integer
    add_column :Client, :NoSingleGender, :integer
    add_column :Enrollment, :HOHLeaseholder, :integer
    rename_column :Event, :LocationCrisisorPHHousing, :LocationCrisisOrPHHousing
    rename_column :HealthAndDV, :SupportfromOthers, :SupportFromOthers
    change_column :CurrentLivingSituation, :VerifiedBy, :string, limit: 100
    change_column :AssessmentQuestions, :AssessmentAnswer, :string, limit: 500
  end
end
