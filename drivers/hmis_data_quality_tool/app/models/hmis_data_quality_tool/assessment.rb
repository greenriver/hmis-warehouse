###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisDataQualityTool
  class Assessment < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_assessments'
    include ArelHelper
    include DqConcern
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :assessment, class_name: 'GrdaWarehouse::Hud::Assessment', optional: true
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
  end
end
