Rails.logger.debug "Running initializer in #{__FILE__}"
# From https://veerasundaravel.wordpress.com/2014/11/26/rails-find_each-method-with-order-option/
class ActiveRecord::Relation
  # normal find_each does not use given order but uses id asc
  def find_each_with_order(batch_size: 1_000)
    page = 1

    loop do
      offset = (page - 1) * batch_size
      batch = self.limit(batch_size).offset(offset)
      page += 1

      batch.each { |x| yield x }

      break if batch.size < batch_size
    end
  end
end
