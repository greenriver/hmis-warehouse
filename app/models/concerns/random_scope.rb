###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module RandomScope
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    scope :random, -> {
      raise "need to know whether I'm in a postgres database" unless respond_to?(:sql_server?)

      fun = if sql_server?
        'NEWID'
      else
        'RANDOM'
      end
      order(nf(fun))
    }
  end
end
