module GrdaWarehouse::Export::HMISSixOneOne
  class HealthAndDv < GrdaWarehouse::Import::HMISSixOneOne::HealthAndDv
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::HealthAndDv.hud_csv_headers(version: '6.11') )

    self.hud_key = :HealthAndDVID

     # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]

  end
end