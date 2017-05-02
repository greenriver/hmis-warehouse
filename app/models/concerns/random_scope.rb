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
      order( nf fun )
    }
  end
end