###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Youth
  class YouthFollowUp < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    # TODO: user agencies
    scope :visible_by?, -> (user) do
      if user.can_edit_anything_super_user?
        all
        # If you can see any, then show yours and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
            or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end

    def housing_status_details
      if housing_status != 'No' && zip_code.present?
        "#{housing_status} (#{zip_code})"
      else
        housing_status
      end
    end

    def self.youth_housing_status_options
      [
        'No',
        'Yes, in RRH',
        'Yes, in market-rate housing',
        'Yes, in transitional housing',
        'Yes, with family',
      ]
    end
  end
end
