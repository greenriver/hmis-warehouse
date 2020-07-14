###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    RELEVANT_COC_STATE = ENV.fetch('RELEVANT_COC_STATE') do
      GrdaWarehouse::Shape::CoC.order('random()').limit(1).pluck(:st)
    rescue StandardError
      'UNKNOWN'
    end

    def index
      @cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      @shapes = GrdaWarehouse::Shape.geo_collection_hash(@cocs)
    end

    private def join_source_pair
      <<~SQL
        JOIN warehouse_clients wc1 ON c.id = wc1.destination_id
          AND wc1.deleted_at IS NULL
        JOIN "Client" s1 ON wc1.source_id = s1.id
          AND s1. "DateDeleted" IS NULL
        JOIN "Enrollment" e1 ON s1. "PersonalID" = e1. "PersonalID"
          AND s1.data_source_id = e1.data_source_id
          AND e1. "DateDeleted" IS NULL
        JOIN "Project" p1 ON p1. "ProjectID" = p1. "ProjectID"
          AND s1.data_source_id = p1.data_source_id
          AND p1. "DateDeleted" IS NULL
        JOIN "ProjectCoC" c1 ON c1. "ProjectID" = p1. "ProjectID"
          AND c1.data_source_id = p1.data_source_id
          AND c1. "DateDeleted" IS NULL
        JOIN "Funder" f1 ON p1. "ProjectID" = f1. "ProjectID"
          AND p1.data_source_id = f1.data_source_id
          AND f1. "DateDeleted" IS NULL
        JOIN bi_lookups_funding_sources ft1 ON f1. "Funder" = ft1. "value"::text
        JOIN bi_lookups_project_types pt1 ON p1. "ProjectType" = pt1. "value"
        JOIN warehouse_clients wc2 ON c.id = wc2.destination_id
          AND wc1.deleted_at IS NULL
        JOIN "Client" s2 ON wc2.source_id = s2.id
          AND s2. "DateDeleted" IS NULL
        JOIN "Enrollment" e2 ON s2. "PersonalID" = e2. "PersonalID"
          AND s2.data_source_id = e2.data_source_id
          AND e2. "DateDeleted" IS NULL
        JOIN "Project" p2 ON e2. "ProjectID" = p2. "ProjectID"
          AND s2.data_source_id = p2.data_source_id
          AND p2. "DateDeleted" IS NULL
        JOIN "ProjectCoC" c2 ON c2. "ProjectID" = p2. "ProjectID"
          AND c2.data_source_id = p2.data_source_id
          AND c2. "DateDeleted" IS NULL
        JOIN "Funder" f2 ON p2. "ProjectID" = f2. "ProjectID"
          AND p2.data_source_id = f2.data_source_id
          AND f2. "DateDeleted" IS NULL
      SQL
    end

    private def c
      GrdaWarehouse::Hud::Client.connection
    end

    private def all_clients(coc1, coc2)
      <<~SQL
        SELECT
          count(DISTINCT c.id) as "Shared Clients"
        FROM
          "Client" c
          #{join_source_pair}
        WHERE
          c1. "CoCCode" = #{c.quote coc1}
          AND c2. "CoCCode" = #{c.quote coc2}
        ORDER BY count(DISTINCT c.id) DESC
      SQL
    end

    private def by_project_type(coc1, coc2)
      <<~SQL
        SELECT
          pt1.text AS "Project Type",
          count(DISTINCT c.id) as "Shared Clients"
        FROM
          "Client" c
          #{join_source_pair}
        WHERE
          c1. "CoCCode" = #{c.quote coc1}
          AND c2. "CoCCode" = #{c.quote coc2}
          AND p1."ProjectType" = p2."ProjectType"
        GROUP BY 1
        ORDER BY count(DISTINCT c.id) DESC
      SQL
    end

    private def by_funding_source(coc1, coc2)
      <<~SQL
        SELECT
          ft1.text AS "Funding Source",
          count(DISTINCT c.id) as "Shared Clients"
        FROM
          "Client" c
          #{join_source_pair}
        WHERE
          c1. "CoCCode" = #{c.quote coc1}
          AND c2. "CoCCode" = #{c.quote coc2}
          AND f1."Funder" = f2."Funder"
        GROUP BY 1
        ORDER BY count(DISTINCT c.id) DESC
      SQL
    end

    def overlap
      ###
      # fake data for testing
      project_types = ([
        'All (Unique Clients)',
        'CA (Coordinated Assessment)',
      ] + GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.values).map do |type|
        [type, [rand(100), rand(100)]]
      end
      funding_sources = [
        'All (Unique Clients)',
        'State',
        'ESG (Emergency Solutions Grants)',
      ].map do |source|
        [source, [rand(100), rand(100)]]
      end
      cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      map_data = {}
      GrdaWarehouse::Shape.geo_collection_hash(cocs)[:features].each do |feature|
        map_data[feature.dig(:properties, :id).to_s] = rand(225)
      end
      ###
      locals = {
        start_date: params.dig(:compare, :start_date),
        end_date: params.dig(:compare, :end_date),
        project_types: project_types,
        funding_sources: funding_sources,
      }
      html = render_to_string partial: 'overlap', locals: locals
      render json: { map: map_data, html: html }
    end
  end
end
