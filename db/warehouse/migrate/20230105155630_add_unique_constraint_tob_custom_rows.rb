class AddUniqueConstraintTobCustomRows < ActiveRecord::Migration[6.1]
  def up
    # Remove duplicates (Done using the code at the bottom)
    # remove = []
    # CustomImportsBostonService::Row.order(import_file_id: :desc).
    #   pluck(:service_id, :import_file_id, :id).
    #   group_by(&:shift).each do |service_id, data|
    #     next unless data.count > 1

    #     # The first row will be part of the newest import file, data is [[import_file_id, id]]
    #     remove += data.drop(1).map(&:last)
    #   end
    # remove.each_slice(10_000) do |ids|
    #   CustomImportsBostonService::Row.where(id: ids).delete_all
    # end
    add_index :custom_imports_b_services_rows, :service_id, unique: true
  end
end

# counts = {}
# progress = 0
# total = CustomImportsBostonService::Row.count
# CustomImportsBostonService::Row.order(import_file_id: :desc).
#   pluck_in_batches([:service_id, :import_file_id, :id], batch_size: 50_000) do |batch|
#     remove = Set.new
#     batch.each do |service_id, import_file_id, id|
#       counts[service_id] ||= 0
#       remove << id if counts[service_id].positive?
#       counts[service_id] += 1
#     end
#     progress += batch.count
#     puts "Removing #{remove.count} rows processed #{progress} of #{total}"
#     CustomImportsBostonService::Row.where(id: remove.to_a).delete_all
#     remove = Set.new
#   end
