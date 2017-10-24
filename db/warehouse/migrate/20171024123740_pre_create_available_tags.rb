class PreCreateAvailableTags < ActiveRecord::Migration
  def change
    GrdaWarehouse::ClientFile.available_tags.each do |name|
      ActsAsTaggableOn::Tag.where(name: name).first_or_create
    end
  end
end
