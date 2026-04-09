###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# load CSTs for given [[record_type, type_provided, data_source_id]...]
class Sources::CustomServiceTypeByHudTypeSource < ::GraphQL::Dataloader::Source
  def fetch(types)
    arel_t = Hmis::Hud::CustomServiceType.arel_table
    cond = types.map do |record_type, type_provided, data_source_id|
      arel_t[:hud_record_type].eq(record_type).
        and(arel_t[:hud_type_provided].eq(type_provided)).
        and(GrdaWarehouse::DataSource.arel_table[:id].eq(data_source_id))
    end.reduce(&:or)

    by_type = Hmis::Hud::CustomServiceType.joins(:data_source).
      where(cond).
      order(:id).
      to_a.
      index_by { |cst| [cst.hud_record_type, cst.hud_type_provided, cst.data_source_id] }

    types.map { |type| by_type[type] }
  end
end
