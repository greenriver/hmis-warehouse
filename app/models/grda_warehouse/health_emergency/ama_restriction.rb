###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class AmaRestriction < GrdaWarehouseBase
    include ::HealthEmergency

    def title
      'Medical Restriction'
    end

    def restriction_options
      {
        'Yes' => 'Yes',
        'No' => '',
      }
    end

    # Only show a status if one has been set
    def status
      note_text = " (#{note})" if note.present?
      return "Restricted" if restricted == 'Yes'
      # return "No Restriction#{note_text}" if restricted == 'No'

      # 'Unknown'
    end
  end
end