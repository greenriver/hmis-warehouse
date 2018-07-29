module GrdaWarehouse::Hud
  class EnrollmentCoc < Base
    include HudSharedScopes
    self.table_name = 'EnrollmentCoC'
    self.hud_key = :EnrollmentCoCID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :EnrollmentCoCID,
          :ProjectEntryID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      else
        [
          :EnrollmentCoCID,
          :EnrollmentID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :project_coc, **hud_belongs(ProjectCoc), inverse_of: :enrollment_cocs
    belongs_to :direct_client, **hud_belongs(Client), inverse_of: :direct_enrollment_cocs
    has_one :client, through: :enrollment, inverse_of: :enrollment_cocs
    belongs_to :export, **hud_belongs(Export), inverse_of: :enrollment_cocs
    belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], inverse_of: :enrollment_cocs
    has_one :project, through: :enrollment

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.coc_codes.none?
        none
      else
        where( CoCCode: user.coc_codes )
      end
    end

    scope :in_coc, -> (coc_code:) do
      where(CoCCode: coc_code)
    end

  end
end