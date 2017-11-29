class GrdaWarehouse::Vispdat::Child < ActiveRecord::Base
  belongs_to :family, class_name: 'GrdaWarehouse::Vispdat::Family'
end
