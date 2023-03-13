###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::File < GrdaWarehouse::File
  include ClientFileBase

  SORT_OPTIONS = [
    :date_created,
    :date_updated,
  ].freeze

  self.table_name = :files
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_created
      order(arel_table[:created_at].asc.nulls_last)
    when :date_updated
      order(arel_table[:updated_at].asc.nulls_last)
    else
      raise NotImplementedError
    end
  end
end
