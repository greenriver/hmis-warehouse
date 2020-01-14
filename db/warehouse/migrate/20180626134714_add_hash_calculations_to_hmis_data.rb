class AddHashCalculationsToHmisData < ActiveRecord::Migration[4.2]
  def change
    [
      "Affiliation",
      "Client",
      "Disabilities",
      "EmploymentEducation",
      "Enrollment",
      "EnrollmentCoC",
      "Exit",
      "Export",
      "Funder",
      "HealthAndDV",
      "IncomeBenefits",
      "Inventory",
      "Organization",
      "Project",
      "ProjectCoC",
      "Services",
      "Site"
    ].each do |table|
      add_column table, :source_hash, :string
    end
  end
end
