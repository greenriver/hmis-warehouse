###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::WarehouseClient < GrdaWarehouseBase
  include ArelHelper
  has_paper_trail
  # acts_as_paranoid

  belongs_to :destination, class_name: 'GrdaWarehouse::Hud::Client',
                           inverse_of: :warehouse_client_destination, optional: true
  belongs_to :source, class_name: 'GrdaWarehouse::Hud::Client',
                      inverse_of: :warehouse_client_source, optional: true

  belongs_to :data_source, optional: true
  belongs_to :client_match, optional: true

  scope :destination_needs_cleanup, -> do
    joins(:source).where(
      c_t[:source_hash].not_eq(nil).and(
        arel_table[:source_hash].not_eq(c_t[:source_hash]).
        or(arel_table[:source_hash].eq(nil)),
      ),
    )
  end

  def self.reset_source_hashes!
    update_all(source_hash: nil)
  end
end
