###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# Currently for debugging.
# Allows easier reviewing of census values

module GrdaWarehouse
  module UsCensusApi
    class CensusReview < GrdaWarehouseBase
      include IsADatabaseView

      self.primary_key = :id

      def self.view_definition
        <<~SQL
          WITH locs as (
            select
              cocname AS name,
              full_geoid
            from shape_cocs

            UNION ALL

            select
              zcta5ce10 AS name,
              full_geoid
            from shape_zip_codes

            UNION ALL

            select
              name,
              full_geoid
            from shape_counties

            UNION ALL

            select
              name,
              full_geoid
            from shape_states
          )

          SELECT
            locs.name AS geometry_name,
            vals.census_level,
            vars.internal_name,
            vals.value,
            vars.year,
            vars.dataset,

            vars.name AS "variable",
            vars.census_group,
            g.description AS "group_description",
            vals.id AS id,
            locs.full_geoid
          FROM
          locs
          LEFT JOIN census_values vals ON (locs.full_geoid = vals.full_geoid)
          LEFT JOIN census_variables vars ON (vals.census_variable_id = vars.id AND vars.internal_name IS NOT NULL)
          LEFT JOIN census_groups g ON (vars.census_group = g.name and vars.year = g.year and vars.dataset = g.dataset )
        SQL
      end
    end
  end
end
