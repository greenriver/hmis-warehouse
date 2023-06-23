###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::FileAccessLoader < Hmis::BaseAccessLoader
  # permissions check for a collection of tuples of [entity, permission]
  # note the same entity could appear more than once in items with different permissions
  # @param items [Array<Array<Hmis::Hud::File, String>>]
  # @return [Array<Boolean>]
  def fetch(items)
    file_ids = items.map { |i| i.first.id }

    raise 'tbd'
  end
end
