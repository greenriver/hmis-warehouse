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


    def self.export! enrollment_scope:, client_scope:, project_scope:, path:, export:
      changed_scope = modified_within_range(range: (export.start_date..export.end_date), include_deleted: export.include_deleted)
      if export.include_deleted
        changed_scope = changed_scope.joins(:warehouse_client_source, enrollments_with_deleted: :project_with_deleted).merge(project_scope)
      else
        changed_scope = changed_scope.joins(:warehouse_client_source, enrollments: :project).merge(project_scope)
      end

      if export.include_deleted
        model_scope = client_scope.with_deleted
      else
        model_scope = client_scope
      end

      case export.period_type
      when 4
        union_scope = from(
        arel_table.create_table_alias(
          model_scope.select(*columns_to_pluck, :id).
            union(changed_scope.select(*columns_to_pluck, :id)
          ),
          table_name
        )
      )
      when 3
        union_scope = model_scope.select(*columns_to_pluck, :id)
      else
        raise NotImplementedError
      end

      export_to_path(
        export_scope: union_scope, 
        path: path, 
        export: export
      )
    end

    def self.includes_union?
      true
    end

  end
end