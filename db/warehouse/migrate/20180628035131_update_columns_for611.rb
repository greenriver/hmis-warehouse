class UpdateColumnsFor611 < ActiveRecord::Migration
  def change
    rename_column :Disabilities, :ProjectEntryID, :EnrollmentID
    rename_column :EmploymentEducation, :ProjectEntryID, :EnrollmentID
    rename_column :Enrollment, :ProjectEntryID, :EnrollmentID
    rename_column :EnrollmentCoC, :ProjectEntryID, :EnrollmentID
    rename_column :Exit, :ProjectEntryID, :EnrollmentID
    rename_column :HealthAndDV, :ProjectEntryID, :EnrollmentID
    rename_column :IncomeBenefits, :ProjectEntryID, :EnrollmentID
    rename_column :Services, :ProjectEntryID, :EnrollmentID

    rename_column :Enrollment, :ResidencePrior, :LivingSituation
    rename_column :Enrollment, :ResidencePriorLengthOfStay, :LengthOfStay
    rename_column :Enrollment, :ResidentialMoveInDate, :MoveInDate
    rename_column :Enrollment, :FYSBYouth, :EligibleForRHY
  end
end
