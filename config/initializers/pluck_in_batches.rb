Rails.logger.debug "Running initializer in #{__FILE__}"

# This assumes you are in Rails 4 and you can pluck multiple columns

class ActiveRecord::Relation
  # pluck_in_batches:  yields an array of *columns that is at least size
  #                    batch_size to a block.
  #
  #                    Special case: if there is only one column selected than each batch
  #                                  will yield an array of columns like [:column, :column, ...]
  #                                  rather than [[:column], [:column], ...]
  # Arguments
  #   columns      ->  an arbitrary selection of columns found on the table.
  #   batch_size   ->  How many items to pluck at a time
  #   &block       ->  A block that processes an array of returned columns.
  #                    Array is, at most, size batch_size
  #
  # Returns
  #   nothing is returned from the function
  def pluck_in_batches(columns, batch_size: 1_000)
    raise 'There must be at least one column to pluck' if columns.empty?

    page = 1

    loop do
      offset = (page - 1) * batch_size
      batch = self.limit(batch_size).offset(offset)
      items = batch.pluck(*columns)
      page += 1
      yield items

      break if items.size < batch_size
    end
  end
end
