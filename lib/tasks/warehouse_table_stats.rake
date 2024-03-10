require 'csv'

namespace :warehouse_table_stats do
  desc 'Row count and timestamps from warehouse tables as csv. Requires eager load'
  task :to_csv, [] => :environment do
    Rails.application.eager_load!
    seen = Set.new
    results = []
    [
      GrdaWarehouse::Hud::Base,
      Hmis::Hud::Base,
    ].each do |base_class|
      base_class.descendants.each do |klass|
        table_name = klass.table_name
        next if table_name.blank?
        next if table_name.in?(seen)

        seen.add(table_name)
        connection = klass.connection
        q_table_name = connection.quote_table_name(table_name)
        count = connection.exec_query("select count(*) from #{q_table_name}")[0]

        date_col = 'DateUpdated'
        last_update = { 'last_updated' => nil }
        if date_col.in?(klass.column_names)
          q_date_col = connection.quote_table_name(date_col)
          last_update = connection.exec_query("select max(#{q_date_col}) as last_updated from #{q_table_name}")[0]&.transform_values do |d|
            case d
            when Date, DateTime, Time
              d&.to_s(:db)
            else
              d
            end
          end
        end

        row = { 'table' => table_name }.merge(count).merge(last_update)
        results.push(row)
      end
    end

    result = CSV.generate do |csv|
      headers = results.first.keys
      # Use the keys of the first hash as headers
      csv << headers
      # Iterate over each hash and insert its values into the CSV
      results.sort_by { |h| h['table'] }.each do |hash|
        csv << hash.values_at(*headers)
      end
    end
    puts result
  end
end
