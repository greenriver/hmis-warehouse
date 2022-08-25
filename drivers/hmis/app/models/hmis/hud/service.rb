###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Service < Hmis::Hud::Base
  include ::HmisStructure::Service
  include ::Hmis::Hud::Shared
  self.table_name = :Services
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')

  def self.record_type_enum_map
    Hmis::FieldMap.new(
      ::HUD.record_types.map do |field, desc|
        next if desc == 'Contact' # ::HUD indicates that these were removed

        {
          key: desc,
          value: field,
          desc: desc,
        }
      end.compact,
      include_base_null: false,
    )
  end

  def self.p_a_t_h_referral_outcome_enum_map
    Hmis::FieldMap.new(
      ::HUD.p_a_t_h_referral_outcome_map.map do |field, desc|
        {
          key: desc,
          value: field,
          desc: desc,
        }
      end,
      include_base_null: false,
    )
  end
end
