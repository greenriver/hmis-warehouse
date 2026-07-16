###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouseBase < ActiveRecord::Base
  include CustomApplicationRecord

  self.abstract_class = true
  connects_to database: { writing: :warehouse, reading: :warehouse }

  def self.sql_server?
    connection.adapter_name == 'SQLServer'
  end

  def self.postgres?
    connection.adapter_name.in?(['PostgreSQL', 'PostGIS'])
  end

  def self.partitioned?(table_name)
    Dba::PartitionMaker.new(table_name: table_name).done?
  end

  # Warehouse records colocate their versions in the warehouse database via
  # GrdaWarehouse::Version. paper_trail 16+ forbids calling has_paper_trail more
  # than once (the inclusion it checks is inherited), so a subclass that
  # re-declares it -- e.g. an abstract base plus a concrete subclass -- would
  # raise. We override the class method to force the correct version class and,
  # on a second call, merge the new options into the already-configured options
  # instead of re-running setup (which would stack callbacks and write duplicate
  # version records).
  FORCED_VERSIONS = { class_name: 'GrdaWarehouse::Version' }.freeze

  def self.has_paper_trail(options = {}) # rubocop:disable Naming/PredicatePrefix
    if respond_to?(:paper_trail_options) && paper_trail_options.present?
      self.paper_trail_options = merge_paper_trail_options(options)
      return
    end

    versions = options.fetch(:versions, {}).merge(FORCED_VERSIONS)
    skip = options.fetch(:skip, [:lock_version])
    super(options.merge(versions: versions, skip: skip))
  end

  # Merge a subclass's paper_trail options into the already-configured options,
  # normalizing ignore/skip/only to the stringified form paper_trail expects at
  # event time (see PaperTrail::ModelConfig#event_attribute_option). Does not
  # re-run setup, so no duplicate callbacks/versions, and leaves version_class_name
  # untouched so every warehouse model keeps versioning into GrdaWarehouse::Version.
  def self.merge_paper_trail_options(options)
    merged = paper_trail_options.dup
    [:ignore, :skip, :only].each do |key|
      next unless options.key?(key)

      merged[key] = Array(options[key]).flatten.compact.map do |attr|
        attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s
      end
    end
    merged[:meta] = merged[:meta].to_h.merge(options[:meta]) if options[:meta]
    merged
  end

  # allows delegation of paper trail metadata
  # replicate paper_trail model_metadatum (mostly)
  # @param key [Symbol]
  def paper_trail_meta_value(key)
    meta = self.class.paper_trail_options&.fetch(:meta)
    value = meta ? meta[key] : nil
    return unless value

    if value.respond_to?(:call)
      value.call(self)
    elsif value.is_a?(Symbol) && respond_to?(value, true)
      send(value)
    else
      value
    end
  end

  def self.references_hud_client?
    columns_hash.key?('PersonalID') && !!reflect_on_association(:client)
  end

  def self.references_hud_enrollment?
    columns_hash.key?('EnrollmentID') && !!reflect_on_association(:enrollment)
  end

  def self.references_hud_project?
    columns_hash.key?('ProjectID') && !!reflect_on_association(:project)
  end

  # force the query planner to use hash joins
  def self.disable_nestloop
    # Get the current value of enable_nestloop
    current_value = connection.select_value('SHOW enable_nestloop').downcase
    raise unless current_value.in?(['on', 'off'])

    connection.execute('SET enable_nestloop = off')

    begin
      yield
    ensure
      # Restore the previous value
      connection.execute("SET enable_nestloop = #{current_value}")
    end
  end

  MAX_PK = 2_147_483_648 # PK is a 4 byte signed INT (2 ** ((4 * 8) - 1))

  # Determine whether the given search term is possibly a Primary Key (it's numeric and less than 4 bytes)
  def self.possibly_pk?(search_term) # could add optional arg for 4 byte vs 8 byte, if needed later
    search_term =~ /\A\d+\z/ && search_term.to_i < MAX_PK
  end
end
