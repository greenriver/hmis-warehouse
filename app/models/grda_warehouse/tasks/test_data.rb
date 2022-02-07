###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

module GrdaWarehouse::Tasks

  # fetches a sample of destination clients, all their sources, the complete graph of entities
  # connected to these clients via belongs-to associations, plus all connected entities for models
  # referred to in GrdaWarehouse::Hud#models_by_hud_filename
  # it then creates a source subdirectory for each data source referred to by these objects and
  # dumps into that subdirectory csv files for all such objects
  class TestData

    attr_reader :n_clients, :dir, :logger, :remove_old

    DATA_SOURCES = 'data_sources.csv'

    class BogusLogger
      def info(msg)
        puts msg
      end
    end

    def initialize( n: 100, dir: 'tmp/test_data', logger: BogusLogger.new, remove_old: true, env: :development)
      @n_clients = n.to_i
      @dir = dir
      @logger = logger
      @remove_old = remove_old
      @export_root_path = Rails.root.join.to_s << "/#{@dir}/"
      @env = env.to_sym
    end

    def run!
      if remove_old && File.exists?(@export_root_path)
        logger.info "removing all data in #{@export_root_path}"
        FileUtils.rmtree dir
      end
      FileUtils.mkdir_p(@export_root_path) unless File.exists?(@export_root_path)
      Dir.chdir(@export_root_path)
      connect_to_staging
      all_objects = {}
      data_source_ids = Set.new
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
      FileUtils.chdir(Rails.root.join.to_s)
      logger.info 'done'
    end

    def dump_sources(sources)
      raise 'no sources found' if sources.empty?
      FileUtils.chdir(@export_root_path)
      sources << GrdaWarehouse::DataSource.destination.first
      CSV.open DATA_SOURCES, 'wb' do |csv|
        csv << cols = sources.all.first.class.column_names
        sources.each do |source|
          csv << cols.map{ |f| source.send f }
        end
      end
    end

    def dump_data(source, all_objects)
      FileUtils.chdir(@export_root_path)
      new_dir = "source-#{source.id}"
      logger.info "source #{source.name}"
      logger.info "files will be created in #{new_dir}"
      FileUtils.mkdir_p(new_dir) unless File.directory?(new_dir)
      FileUtils.chdir("#{@export_root_path}/#{new_dir}")
      all_objects.each do |model, hash|
        dump_table model, hash.values.select{ |e| e.data_source_id == source.id }.sort_by(&:id)
      end
      FileUtils.chdir(@export_root_path)
    end

    def file_map
      @file_map ||= GrdaWarehouse::Hud.models_by_hud_filename.to_a.map(&:reverse).to_h
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
          csv << cols.map{ |f| row.send f }
        end
      end
    end

    def source_clients(ids=source_client_ids)
      @source_clients ||= begin
        logger.info "collecting #{n_clients} destination clients and their associated objects..."
        GrdaWarehouse::Hud::Client.
          where( id: ids ).
          includes(client_associations)
      end
    end

    def output_count
      if @count.nil?
        print "\n"
        @count = 0
      end
      print '.'
      @count += 1
      if @count % 100 == 0
        puts " #{@count}"
      end
    end

    def destination_client_ids
      @client_ids ||= begin
        clients = GrdaWarehouse::Hud::Client
        histories = GrdaWarehouse::ServiceHistory
        ct = clients.arel_table
        ht = histories.arel_table
        clients.destination.random.where(
          histories.where( ht[:client_id].eq ct[:id] ).exists
        ).limit(n_clients).pluck(:id).sort
      end
    end

    def source_client_ids
      ct = GrdaWarehouse::Hud::Client.arel_table
      wt = GrdaWarehouse::WarehouseClient.arel_table
      GrdaWarehouse::Hud::Client.joins(:warehouse_client_source).where( wt[:destination_id].in destination_client_ids )
    end

    # in order to minimize the object graph only belongs-to associations are followed
    # EXCEPT as necessary to obtain all the tables listed in GrdaWarehouse::Hud
    # the exceptions are noted below

    def client_associations
      [
        :export,
        {
          disabilities: [ :export, { enrollment: enrollment_associations } ],
          employment_educations: [ :export, { enrollment: enrollment_associations } ],
          enrollment_cocs: [ :export, { project: project_associations, enrollment: enrollment_associations }],
          enrollments: enrollment_associations,
          exits: [ :export, { enrollment: enrollment_associations } ],
          health_and_dvs: [ :export, { enrollment: enrollment_associations } ],
          income_benefits: [ :export, {
            enrollment: enrollment_associations,
            project: project_associations
          } ],
          services: [ :export, { enrollment: enrollment_associations } ],
        }
      ]
    end

    def project_associations
      [
        :export,
        {
          affiliations: :export,      # has-many
          funders: :export,           # has-many
          organization: :export,
          project_cocs: [ :export, {  # has-many
            inventories: :export,     # has-many
            sites: :export,           # has-many
          } ]
        }
      ]
    end

    def enrollment_associations
      [ :export, { project: project_associations } ]
    end

    def walk_associations(entity, associations, &block)
      if yield entity
        case associations
        when Symbol
          handle_symbol entity, associations, block
        when Hash
          handle_hash entity, associations, block
        when Array
          associations.each do |a|
            case a
            when Symbol
              handle_symbol entity, a, block
            when Hash
              handle_hash entity, a, block
            else
              raise "huh!?"
            end
          end
        end
      end
    end

    def handle_symbol(entity, sym, block, next_association=nil)
      r = entity.send(sym)
      if r.respond_to?(:any?)
        r.each do |i|
          handle_individual i, next_association, block
        end
      elsif r.present?
        handle_individual r, next_association, block
      end
    end

    def handle_hash(entity, hash, block)
      hash.each do |key, value|
        handle_symbol entity, key, block, value
      end
    end

    def handle_individual(entity, association, block)
      walk_associations entity, association do |e|
        block.call e
      end
    end

    def connect_to_staging
      logger.info "connecting to staging database..."
      GrdaWarehouseBase.establish_connection(:staging_grda_warehouse)
    end
  end
end
