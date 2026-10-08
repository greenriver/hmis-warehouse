###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shapes, names, SVG paths and census populations for one map type
# (zip, place, county, or CoC), limited to the installation's states.
class PublicReports::StateDashboard::Geography
  include GrdaWarehouse::UsCensusApi::Aggregates

  def initialize(map_type)
    @map_type = map_type
  end

  def by_zip?
    @map_type == 'zip'
  end

  def by_place?
    @map_type == 'place'
  end

  def by_county?
    @map_type == 'county'
  end

  def type_human
    return 'ZIP code' if by_zip?
    return 'town' if by_place?
    return 'county' if by_county?

    'Continuum of Care'
  end

  # Geography codes, ordered by display name. Code and display name are
  # the same value for zip/place/county; only CoC differs (code is cocnum,
  # display name is "name (cocnum)").
  def codes
    @codes ||= if by_zip?
      state_zip_shapes.map(&:zcta5ce10).sort
    elsif by_place?
      state_place_shapes.map(&:name).sort
    elsif by_county?
      state_county_shapes.map(&:name).sort
    else
      state_coc_shapes.sort_by(&:number_and_name).map(&:cocnum)
    end
  end

  def display_name(code)
    return code if by_zip? || by_place? || by_county?

    coc_display_names[code] || code
  end

  # Pre-projected SVG paths, one per code (same order). No per-vertex Ruby:
  # the projection, translation and scaling happen in PostGIS.
  def svg
    cache_key = "map-svg-#{@map_type}-#{GrdaWarehouse::Config.relevant_state_codes.join('_')}"
    Rails.cache.fetch(cache_key, expires_in: 4.hours) do
      calculate_svg
    end
  end

  def population(year, code)
    population_by_year(year)[code]
  end

  # Statewide census population, summed across the state's CoCs.
  def population_by_race(year:, race_code: 'All')
    race_var = \
      case race_code
      when 'AmIndAKNative' then NATIVE_AMERICAN
      when 'Asian' then ASIAN
      when 'BlackAfAmerican' then BLACK
      when 'NativeHIPacific' then PACIFIC_ISLANDER
      when 'White' then WHITE
      when 'RaceNone' then OTHER_RACE
      when 'MultiRacial' then TWO_OR_MORE_RACES
      when 'All' then ALL_PEOPLE
      else
        raise "Invalid race code: #{race_code}"
      end

    results = coc_geometries.map do |geo|
      geo.population(internal_names: race_var, year: year)
    rescue GrdaWarehouse::UsCensusApi::Finder::CannotFindData => e
      Rails.logger.error "population error: #{e.message}. Sum won't be right!"
      return nil
    end

    results.each do |result|
      Rails.logger.warn "Using #{result.year} instead of #{year}" if result.year != year
    end

    results.map(&:val).sum
  end

  private def population_by_year(year)
    @population_by_year ||= {}
    @population_by_year[year] ||= {}.tap do |populations|
      population_geometries.each do |geo|
        populations[population_code(geo)] ||= geo.population(internal_names: ALL_PEOPLE, year: year).val
      end
    end
  end

  private def population_geometries
    return GrdaWarehouse::Shape::ZipCode.where(zcta5ce10: state_zip_shapes.map(&:zcta5ce10)) if by_zip?
    return GrdaWarehouse::Shape::Town.where(town: state_place_shapes.map(&:name)) if by_place?
    return GrdaWarehouse::Shape::County.where(namelsad: state_county_shapes.map(&:namelsad)) if by_county?

    coc_geometries
  end

  private def population_code(geo)
    return geo.zcta5ce10 if by_zip?
    return geo.name if by_place? || by_county?

    geo.cocnum
  end

  private def shape_class
    return GrdaWarehouse::Shape::ZipCode if by_zip?
    return GrdaWarehouse::Shape::Town if by_place?
    return GrdaWarehouse::Shape::County if by_county?

    GrdaWarehouse::Shape::Coc
  end

  private def code_column
    return 'zcta5ce10' if by_zip?
    return 'town' if by_place?
    return 'namelsad' if by_county?

    'cocnum'
  end

  private def calculate_svg
    scope = shape_class.my_states
    geom = "COALESCE(#{shape_class.table_name}.simplified_geom, #{shape_class.table_name}.geom)"

    # Cast to text: ST_Extent returns Postgres's `box` type, which the PG
    # adapter has no OID mapping for. Left uncast, the adapter's fallback
    # to treating it as a string emits a Ruby warning -- harmless on its
    # own, but this app's Warning.process (custom_deprecation_handler.rb)
    # turns every warning into a hard raise in development.
    extent = scope.pick(Arel.sql("ST_Extent(ST_Transform(#{geom}, 3857))::text"))
    return { view_box: '0 0 720 0', paths: [] } if extent.nil?

    xmin, ymin, xmax, ymax = extent.scan(/[-\d.]+/).map(&:to_f)
    scale = 720.0 / (xmax - xmin)
    height = ((ymax - ymin) * scale).round(2)

    d_by_code = scope.pluck(
      Arel.sql(code_column),
      Arel.sql("ST_AsSVG(ST_TransScale(ST_Transform(#{geom}, 3857), #{-xmin}, #{-ymax}, #{scale}, #{scale}), 0, 1)"),
    ).to_h

    paths = codes.each_with_index.map do |code, index|
      [index, code.to_s.parameterize, d_by_code[code]]
    end

    { view_box: "0 0 720 #{height}", paths: paths }
  end

  private def coc_display_names
    @coc_display_names ||= state_coc_shapes.index_by(&:cocnum).transform_values(&:number_and_name)
  end

  private def coc_geometries
    @coc_geometries ||= GrdaWarehouse::Shape::Coc.where(cocnum: state_coc_shapes.map(&:cocnum))
  end

  private def state_coc_shapes
    @state_coc_shapes ||= GrdaWarehouse::Shape::Coc.my_states
  end

  private def state_zip_shapes
    @state_zip_shapes ||= GrdaWarehouse::Shape::ZipCode.my_states
  end

  private def state_county_shapes
    @state_county_shapes ||= GrdaWarehouse::Shape::County.my_states
  end

  private def state_place_shapes
    @state_place_shapes ||= GrdaWarehouse::Shape::Town.my_states
  end
end
