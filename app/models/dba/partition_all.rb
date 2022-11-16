class DBA::PartitionAll
  def tables
    t = HmisCsvImporter::Loader::Loader.loadable_files.values.map(&:table_name)
    t += HmisCsvImporter::Importer::Importer.importable_files.values.map(&:table_name)
    t.reject! do |x|
      x.match?(/exports|organizations|projects|funders|inventories|project_cocs|affiliations|users/)
    end
    t.sort
  end

  def add_explicit_primary_key!
    tables.each do |t|
      # Find the file behind the table (couldn't get source_location to work)
      cmd = "egrep -R 'table_name..*#{t}' drivers/hmis_csv_twenty_twenty_two/app/models/hmis_csv_twenty_twenty_two | cut -d: -f1"
      path = `#{cmd}`

      # Add the primary_key line below the table_name line
      cmd = %(sed -i -e "/self.table_name/a\\    self.primary_key = 'id'" #{path})
      puts cmd
      system(cmd)
    end
  end

  # 6716 partitions.
  def run!
    Rails.logger.warn "Making #{71 * tables.length} partitions"

    tables.each do |table|
      Rails.logger.info "==== Partitioning #{table} ===="
      pm = DBA::PartitionMaker.new(table_name: table)
      if pm.no_table?
        Rails.logger.error "Skipping #{table} which couldn't be found"
      elsif pm.done?
        Rails.logger.info "Skipping #{table} which is done"
        next
      else
        pm.run!
      end
    end
  end

  # Use this with great care
  def remove_saved_tables!
    raise 'Aborting. You must set DELETE_THEM=true in your environment' unless ENV['DELETE_THEM'] == 'true'

    tables.each do |table|
      GrdaWarehouseBase.connection.execute(<<~SQL)
        DROP TABLE "#{table}_saved"
      SQL
    end
  end
end
