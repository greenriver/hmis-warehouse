namespace :hmis do
  desc "delete all rows from every model in the GrdaWarehouse::HMIS module"
  task :clean => [:environment] do
    GrdaWarehouse::HMIS::Base.descendants.reject(&:abstract_class?).each do |table|
      table.delete_all
    end
  end

  namespace :assessments do
    
    desc "remove assessment forms which have no answers"
    task :remove_blanks => [:environment, "log:info_to_stdout"] do
      ass = GrdaWarehouse::HMIS::Assessment
      ans = GrdaWarehouse::HMIS::Answer
      blanks = ass.where(
        ans.where(
          ans.arel_table[:assessment_id].eq ass.arel_table[:id]
        ).exists.not
      )
      Rails.logger.info "#{blanks.count} empty assessments found"
      blanks.destroy_all
    end
  end
end