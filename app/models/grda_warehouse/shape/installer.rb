###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class Installer
      def self.any_needed?
        State.none? || ZipCode.none? || County.none? || CoC.none? || BlockGroup.none? || Place.none? || Town.none?
      end

      def run!
        Rails.logger.info 'Downloading shapes of geometries (you need to set up your AWS environment to download)'
        FileUtils.chdir(Rails.root.join('shape_files'))
        system('./sync.from.s3')

        shapes_processed = Set.new

        num_zips = `find . -name '*zip'`.split(/\n/).length
        if num_zips.zero?
          # If you don't care about CoC/ZipCode shapes and want to just get through
          # the migration, just comment out this whole rake task. You can run it
          # later
          raise 'You didn\'t sync shape files correctly yet. Aborting'
        end

        FileUtils.chdir(Rails.root)

        [
          OpenStruct.new(klass: GrdaWarehouse::Shape::BlockGroup, dir: 'block_groups'), # First because needed for water pruning
          OpenStruct.new(klass: GrdaWarehouse::Shape::State, dir: 'states'), # Second because needed for pruning
          OpenStruct.new(klass: GrdaWarehouse::Shape::ZipCode, dir: 'zip_codes.census.2018'),
          OpenStruct.new(klass: GrdaWarehouse::Shape::CoC, dir: 'CoC'),
          OpenStruct.new(klass: GrdaWarehouse::Shape::County, dir: 'counties'),
          OpenStruct.new(klass: GrdaWarehouse::Shape::Place, dir: 'places'),
          OpenStruct.new(klass: GrdaWarehouse::Shape::Town, dir: 'towns'),
        ].each do |conf|
          if conf.klass.any?
            Rails.logger.info "Skipping #{conf.klass} since you already have it."
            next
          end

          Rails.logger.info "Preparing #{conf.klass} shapes of geometries for insertion into database"

          # command-line arg is only important for block groups and CoC, but
          # easier to just pass it along for all
          system("./shape_files/#{conf.dir}/make.inserts #{ENV['RELEVANT_COC_STATE']}")

          if File.exists?("shape_files/#{conf.dir}/inserts.sql") # rubocop:disable Lint/DeprecatedClassMethods
            Rails.logger.info "Inserting #{conf.klass} into the database, conserving RAM"
          elsif conf.klass == GrdaWarehouse::Shape::Town
            Rails.logger.warn 'Shape-loading logic relies on precense of records, so adding a fake town record'
            GrdaWarehouse::Shape::Town.create!
          else
            Rails.logger.warn "Skipping #{conf.klass}: cannot find inserts.sql file"
            next
          end

          conf.klass.delete_all

          ActiveRecord::Base.logger.silence do
            File.open("shape_files/#{conf.dir}/inserts.sql", 'r') do |fin|
              fin.each_line.with_index do |line, i|
                begin
                  GrdaWarehouseBase.connection.exec_query(line)
                rescue PG::InternalError => e
                  Rails.logger.error e.message
                end

                Rails.logger.info "Inserted another 100 #{conf.klass} into the database" if (i % 100).zero? && i.positive?
              end
            end
          end

          # I don't think we're displaying block groups on the front-end, so we don't need those
          if conf.klass != GrdaWarehouse::Shape::BlockGroup
            Rails.logger.info "Simplifying #{conf.klass} shapes for much faster UI"
            conf.klass.simplify!
          end

          prune!([conf.klass])

          Rails.logger.info "Setting full geoid for #{conf.klass} to allow joins with census data"
          conf.klass.set_full_geoid!

          shapes_processed << conf.klass
        end

        remove_all_water! if shapes_processed.intersect?([CoC, County].to_set)

        Rails.logger.info 'Done with shape importing'
      end

      def prune!(klasses = [ZipCode, CoC, County, State])
        return unless State.any?

        if Rails.env.development?
          Rails.logger.warn "Not pruning #{klasses} since env is development"
          return
        end

        Rails.logger.info 'Pruning out-of-state geometries'

        # Don't need to prune places or towns. They come in on a per-state basis
        klasses.each do |klass|
          next unless klass.not_my_state.count.positive? && (klass.not_my_state.count + klass.my_state.count == klass.count)

          Rails.logger.warn "Deleting #{klass} that are out of state"
          klass.not_my_state.delete_all
          klass.connection.exec_query("VACUUM ANALYZE #{klass.table_name}")
        end
      end

      # Prune first
      # If we want better than block group "resolution" we can find proper
      # water shapes for the country, but it will need cleaning to avoid
      # subtracting small lakes, rivers, etc.
      def remove_all_water!
        if BlockGroup.none?
          Rails.logger.warn "Cannot clip geometries to land because we don't have block groups"
          return
        end

        Rails.logger.info 'Removing water-only block groups'
        BlockGroup.where(aland: 0).delete_all

        Rails.logger.info 'Clipping geometries to land only using block groups. Be patient'

        [CoC, County].each do |klass|
          Rails.logger.warn "Handling no-land (all water) parts of #{klass}"

          klass.connection.exec_query(<<~SQL)
            -- joins the other geography in case you're in development and have
            -- multiple states' block groups. It's not strictly required.
            -- This makes a single row with a single shape that represents the
            -- land as a union of all the land block groups
            WITH land AS (
              SELECT ST_BUFFER(ST_UNION(bg.geom), 0.00001) AS geom
              FROM shape_block_groups bg
              JOIN #{klass.table_name} other ON (bg.geom && other.geom)
            )

            -- Update the geography in question to only be the land part
            UPDATE #{klass.table_name} AS shape
            SET geom = ST_MULTI(ST_INTERSECTION(shape.geom, land.geom))
            FROM land
          SQL

          klass.connection.exec_query("VACUUM ANALYZE #{klass.table_name}")
        end
      end
    end
  end
end
