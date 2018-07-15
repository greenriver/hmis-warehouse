class WarehouseAlert < ActiveRecord::Base
  belongs_to :user
  acts_as_paranoid

  scope :ordered, -> do
    order(created_at: :desc)
  end
end
