module Glacier
  class Archive < ActiveRecord::Base
    belongs_to :vault, foreign_key: 'glacier_vault_id'
  end
end
