###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class EnrollmentCoc < Base
    include HudSharedScopes
    include ::HmisStructure::EnrollmentCoc
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions
    attr_accessor :source_id

    self.table_name = 'EnrollmentCoC'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :enrollment_cocs, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_enrollment_cocs, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :enrollment_cocs, optional: true
    belongs_to :data_source
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :enrollment_cocs, optional: true

    has_one :client, through: :enrollment, inverse_of: :enrollment_cocs
    has_one :project, through: :enrollment
    has_one :lookup_coc, class_name: '::GrdaWarehouse::Lookups::CocCode', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :enrollment_coc

    scope :viewable_by, ->(user) do
      if GrdaWarehouse::DataSource.can_see_all_data_sources?(user)
        current_scope
      elsif user.coc_codes.none?
        none
      else
        where(CoCCode: user.coc_codes)
      end
    end

    # hide previous declaration of :in_coc, we'll use this one
    replace_scope :in_coc, ->(coc_code:) do
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
