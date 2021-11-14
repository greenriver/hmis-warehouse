class RebuildCeData < ActiveRecord::Migration[5.2]

  def up
    GrdaWarehouse::Synthetic::Assessment.joins(enrollment: :project).preload(enrollment: :project).find_each do |synthetic|
      next if synthetic.enrollment.project.coc_funded?

      synthetic.destroy
    end

    GrdaWarehouse::Synthetic::Event.joins(enrollment: :project).preload(enrollment: :project).find_each do |synthetic|
      next if synthetic.enrollment.project.coc_funded?

      synthetic.destroy
    end
  end
end
