###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class EnrollmentCoc < Base
    include HudSharedScopes
    include ::HMIS::Structure::EnrollmentCoC

    self.table_name = 'EnrollmentCoC'
    self.hud_key = :EnrollmentCoCID
    acts_as_paranoid column: :DateDeleted

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :enrollment_cocs
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_enrollment_cocs
    has_one :client, through: :enrollment, inverse_of: :enrollment_cocs
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :enrollment_cocs, optional: true
    has_one :project, through: :enrollment
    belongs_to :data_source
    has_one :lookup_coc, class_name: '::GrdaWarehouse::Lookups::CocCode', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :enrollment_coc

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

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
        :ProjectID,
      ]
    end

  end
end