# 1. Generate a consistently annonimized data set from production
# 2. Store the map in production so that you can re-create a consistent export but not 
#     reverse engineer the algorithm to get back to the real dataset
# 3. Store one version per ruby-env type (development, staging, demo)
# 4. Each time you run the export it should gather the entire history for everyone chosen
#     this is subtly different from a real data export that should care about the date range
# 

require 'csv'
require 'faker'
require 'securerandom'

module GrdaWarehouse::Tasks

  # fetches a sample of destination clients, all their sources, the complete graph of entities
  # connected to these clients via belongs-to associations, plus all connected entities for models
  # referred to in GrdaWarehouse::Hud#models_by_hud_filename
  # it then creates a source subdirectory for each data source referred to by these objects and
  # dumps into that subdirectory csv files for all such objects
  class DumpHmisSubset < TestData

    def run!
      if remove_old && File.exists?(dir)
        logger.info "removing all data in #{dir}"
        FileUtils.rmtree dir
      end
      FileUtils.mkdir_p(@dir) unless File.exists? dir
      FileUtils.chdir(@dir) do 
        all_objects = {}
        data_source_ids = Set.new
        @fake_data = GrdaWarehouse::FakeData.where(environment: @env).first_or_create

        source_clients.each do |client|
          walk_associations client, client_associations do |entity|
            output_count
            if entity.present?
              unseen = true
              if entity.respond_to? :data_source_id
                data_source_ids << entity.data_source_id
                objects_of_type = ( all_objects[entity.class] ||= {} )
                if unseen = !objects_of_type.key?(entity.id)
                  objects_of_type[entity.id] = entity
                end
              end
              unseen
            end
          end
        end
        if @count.to_i % 100 > 0
          puts " #{@count}"
        end
        sources = GrdaWarehouse::DataSource.where id: data_source_ids.to_a
        logger.info "dumping data sources into #{dir}..."
        dump_sources sources
        sources.each do |source|
          dump_data source, all_objects
        end
        @fake_data.client_ids = destination_client_ids
        @fake_data.save
      end
      logger.info 'done'
    end

    def dump_data(source, all_objects)
      all_objects[GrdaWarehouse::Hud::Export].each do |_, export|
        FileUtils.chdir(@export_root_path) do 
          next unless export.data_source_id == source.id
          export_id = export.ExportID
          new_dir = "source-#{source.id}/#{export.ExportID}"
          logger.info "source #{source.name}"
          logger.info "files will be created in #{new_dir}"
          FileUtils.mkdir_p(new_dir) unless File.directory?(new_dir)
          FileUtils.chdir("#{@export_root_path}/#{new_dir}") do
            all_objects.each do |model, hash|
              items = hash.values.select do |e|
                e.data_source_id == source.id && e.ExportID == export_id
              end.sort_by(&:id)
              dump_table(model, items)
            end
          end
        end
      end
    end

    def dump_table(model, rows)
      file = file_map[model]
      unless file
        warn "could not find file for #{model.name}"
        return
      end
      CSV.open file, 'wb' do |csv|
        csv << cols = model.hud_csv_headers
        rows.each do |row|
          csv << cols.map do |field_name|
            value = row.send(field_name)
            @fake_data.fetch(field_name: field_name, real_value: value)
          end
        end
      end
    end

    # Fetch a random set of destination client ids, unless we already have some,
    # then expand or contract as necessary
    def destination_client_ids
      @client_ids ||= begin
        if @fake_data.client_ids.present? && @fake_data.client_ids.count >= n_clients
          @fake_data.client_ids.first(n_clients)
        else
          clients = GrdaWarehouse::Hud::Client
          histories = GrdaWarehouse::ServiceHistory
          ct = clients.arel_table
          ht = histories.arel_table
          ids = Array.wrap(@fake_data.client_ids)
          fetch_n_clients = n_clients - ids.count
          ids += clients.destination.random.where(
            histories.where( ht[:client_id].eq ct[:id] ).exists
          ).limit(fetch_n_clients).pluck(:id).sort
        end
      end
    end
  end
end
