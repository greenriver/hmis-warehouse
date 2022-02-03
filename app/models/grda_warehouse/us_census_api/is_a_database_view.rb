###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# This code is pretty generic. It could be moved to a higher namespace and used elsewhere
module GrdaWarehouse
  module UsCensusApi
    module IsADatabaseView
      extend ActiveSupport::Concern

      module ClassMethods
        def index!
          index_definition.split(/;/).each do |query|
            connection.exec_query(query)
          end
        end

        def rebuild!
          around_rebuild do
            drop!
            connection.exec_query(<<~SQL)
              CREATE #{materialized} VIEW #{@view_name} AS
              #{view_definition}
            SQL
            index! if @materialized
          end
        end

        def around_rebuild
          yield
        end

        def drop!
          connection.transaction do
            connection.exec_query(<<~SQL)
              DROP #{materialized} VIEW IF EXISTS #{@view_name};
            SQL
          end
        end

        def refresh!
          raise "Cannot refresh a non-materialized view" unless @materialized

          connection.exec_query(<<~SQL)
            REFRESH MATERIALIZED VIEW #{@view_name}
          SQL
        end

        def materialized
          if @materialized
            'MATERIALIZED'
          else
            ''
          end
        end

        def view_is_materialized!
          @materialized = true
        end

        def view_name= name
          @view_name = name
        end

        def view_definition
          raise "You must specify definition in your view model"
        end

        def index_definition
          raise "You must specify an index definition in your view model"
        end
      end

      included do |klass|
        klass.view_name = klass.name.tableize.split(%r{/}).last
      end
    end
  end
end
