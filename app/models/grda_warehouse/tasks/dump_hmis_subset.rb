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
    include FakingData

    def run!
      if remove_old && File.exists?(dir)
        logger.info "removing all data in #{dir}"
        FileUtils.rmtree dir
      end
      FileUtils.mkdir_p(dir) unless File.exists? dir
      Dir.chdir dir
      connect_to_staging # FIXME remove this line
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
      logger.info 'done'
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


    # somewhat elaborate SSN faking to make the fake data look more like the real data
    def fake_ssn(value)
      if SimilarityMetric::SocialSecurityNumber::FAKES_RX === value
        # make a different, but also fake, SSN
        v = value
        @randos ||= [
          *(1..10).map{ -> { rand(0..9).to_s * rand(3..9) } },  # mostly of this sort (why not)
          *(1..5).map{ -> { '123456789'[0...rand(4..9)] } },    # then a lot of these
          -> {'078051120'}                                      # and one of these
        ]
        while v == value
          v = @randos.sample.()
        end
        v
      else
        Faker::Number.number(9)
      end
    end

    def setup_for_fake
      @fake_it = true
      @fake_data = {
        FirstName: {
          routine: -> (value) { Faker::Name.first_name },
        },
        LastName: {
          routine: -> (value) { Faker::Name.last_name },
        },
        SSN: {
          routine: self.method(:fake_ssn),
        }, 
        DOB: {
          routine: -> (value) { Faker::Date.between(70.years.ago, 1.years.ago) },
        },
        PersonalID: {
          routine: -> (value) { SecureRandom.uuid.gsub('-', '') }
        }
        UserID: {
          routine: -> (value) { Faker::Internet.user_name(5..8) },
        },
        CoCCode: {
          routine: -> (value) { "#{Faker::Address.state_abbr}-#{Faker::Number.number(3)}" },
        },
        ProjectName: {
          routine: -> (value) { Faker::TwinPeaks.location },
        },
        OrganizationName: {
          routine: -> (value) { Faker::TwinPeaks.location },
        },
        OrganizationCommonName: {
          routine: -> (value) { Faker::TwinPeaks.location },
        },
        SourceContactEmail: {
          routine: -> (value) { Faker::Internet.safe_email},
        },
        SourceContactFirst: {
          routine: -> (value) { Faker::Name.first_name },
        },
        SourceContactLast: {
          routine: -> (value) { Faker::Name.last_name },
        },
        SourceContactPhone: {
          routine: -> (value) { Faker::PhoneNumber.cell_phone },
        },
        Address: {
          routine: -> (value) { Faker::Address.street_address },
        },
        City: {
          routine: -> (value) { Faker::Address.city },
        },
        State: {
          routine: -> (value) { Faker::Address.state_abbr },
        },
        ZIP: {
          routine: -> (value) { Faker::Address.zip },
        },
      }.each do |_,bits|
        # these will be defined and filled, respectively, later
        # to provide consistency in translation
        bits.merge!({
          index: nil,
          values: {} 
        }) 
      end
    end
  end
end
