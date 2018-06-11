module GrdaWarehouse::Export::HMISSixOneOne
  class Client < GrdaWarehouse::Import::HMISSixOneOne::Client
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :PersonalID,
        :FirstName,
        :MiddleName,
        :LastName,
        :NameSuffix,
        :NameDataQuality,
        :SSN,
        :SSNDataQuality,
        :DOB,
        :DOBDataQuality,
        :AmIndAKNative,
        :Asian,
        :BlackAfAmerican,
        :NativeHIOtherPacific,
        :White,
        :RaceNone,
        :Ethnicity,
        :Gender,
        :OtherGender,
        :VeteranStatus,
        :YearEnteredService,
        :YearSeparated,
        :WorldWarII,
        :KoreanWar,
        :VietnamWar,
        :DesertStorm,
        :AfghanistanOEF,
        :IraqOIF,
        :IraqOND,
        :OtherTheater,
        :MilitaryBranch,
        :DischargeStatus,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID
      ]
    )

    self.hud_key = :PersonalID

    # Setup an association to enrollment that allows us to pull the records even if the 
    # enrollment has been deleted
    has_many :enrollments_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id]


    def export! client_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = client_scope
      when 1
        export_scope = client_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      
      export_to_path(
        export_scope: export_scope, 
        path: path, 
        export: export
      )
    end
  end
end