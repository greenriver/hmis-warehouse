###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper

    # NOTE: rules live in a json blog of the following format
    # Each layer can only have a rule or a relation

    # { # Rule
    #   column: 'cohort_column_name',
    #   operator: '<, >, <>, ==', # pick one
    #   value: 'comparison value',
    # }

    # { # Relation
    #   operator: 'or',
    #   left: {
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   },
    #   right: {
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   }
    # }
    # { # Relation
    #   operator: 'and',
    #   left: { # Rule
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   },
    #   right: { # Relation
    #     operator: 'or',
    #     left: {
    #       column: 'cohort_column_name',
    #       operator: '<, >, <>, ==', # pick one
    #       value: 'comparison value',
    #     },
    #     right: {
    #       column: 'cohort_column_name',
    #       operator: '<, >, <>, ==', # pick one
    #       value: 'comparison value',
    #     }
    #   }
    # }
  end
end
