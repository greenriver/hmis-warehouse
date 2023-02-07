###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EtlViewMaintainer::GrdaWarehouse::Hud
  module IncomeBenefitExtension
    extend ActiveSupport::Concern

    included do
      def self.columns_for_etl_view
        EtlViewMaintainer::Generator.basic_columns_for_etl_view(column_names, self)
      end
    end
  end
end
