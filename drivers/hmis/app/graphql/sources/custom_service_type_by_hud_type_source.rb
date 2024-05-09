###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# load CSTs for given [[record_type, type_provided]...]
class Sources::CustomServiceTypeByHudTypeSource < ::GraphQL::Dataloader::Source
  def fetch(types)
    arel_t = Hmis::Hud::CustomServiceType.arel_table
    cond = types.map do |record_type, type_provided|
      arel_t[:hud_record_type].eq(record_type).and(arel_t[:hud_type_provided].eq(type_provided))
    end.reduce(&:or)

    data_source = GrdaWarehouse::DataSource.hmis.first!
    by_type = Hmis::Hud::CustomServiceType.
      where(data_source: data_source).
      where(cond).
      order(:id).
      to_a.
      index_by { |cst| [cst.hud_record_type, cst.hud_type_provided] }

    types.map { |type| by_type[type] }
  end
end
