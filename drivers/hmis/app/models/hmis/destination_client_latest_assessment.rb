# frozen_string_literal: true

# View that provides latest custom assessments for destination clients
# This enables easy joining to get CDE values from the most recent assessments per form type
class Hmis::DestinationClientLatestAssessment < GrdaWarehouseBase
  # database view
  self.table_name = 'hmis_destination_client_latest_assessments'

  belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'
  belongs_to :custom_assessment, class_name: 'Hmis::Hud::CustomAssessment'
end
