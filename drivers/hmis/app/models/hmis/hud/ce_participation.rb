###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::CeParticipation < Hmis::Hud::Base
  self.table_name = :CEParticipation
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::CeParticipation
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  include ::Hmis::Hud::Concerns::FormSubmittable

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :projects, optional: true

  # CE Participation Status is active on the given date
  scope :active_on_date, ->(date = Date.current) do
    ce_t = arel_table
    on_or_after_start = ce_t[:CEParticipationStatusStartDate].lteq(date)
    on_or_before_end = ce_t[:CEParticipationStatusEndDate].eq(nil).or(ce_t[:CEParticipationStatusEndDate].gteq(date))
    where(on_or_after_start.and(on_or_before_end))
  end

  # "Project is a Coordinated Entry Access Point" = Yes (HUD)
  scope :access_point, -> do
    where(arel_table[:AccessPoint].eq(1))
  end

  def ce_participation_services
    HudHelper.util.ce_participation_services_fields.select { |k| send(k) == 1 }.values
  end
end
