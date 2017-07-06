namespace :hmis do
  desc "delete all rows from every model in the GrdaWarehouse::HMIS module"
  task :clean => [:environment] do
    GrdaWarehouse::HMIS::Base.descendants.reject(&:abstract_class?).each do |table|
      table.delete_all
    end
  end

end