class InvalidateEnrollmentsWithMissingEnrollmentCoC < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: nil).
      joins(:imported_items_2024).
      merge(HmisCsvTwentyTwentyFour::Importer::Enrollment.where.not(EnrollmentCoC: nil)).
      update_all(source_hash: nil)
  end
end
