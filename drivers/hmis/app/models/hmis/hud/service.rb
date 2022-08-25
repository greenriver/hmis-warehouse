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

  use_enum :record_type_enum_map, (::HUD.record_types.reject { |_k, v| v == 'Contact' })
  use_enum :p_a_t_h_referral_outcome_enum_map, ::HUD.p_a_t_h_referral_outcome_map
end
