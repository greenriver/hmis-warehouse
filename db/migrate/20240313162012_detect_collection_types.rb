class DetectCollectionTypes < ActiveRecord::Migration[6.1]
  def up
    Collection.where(collection_type: nil).find_each do |collection|
      affects = {
        'Projects' => false,
        'Cohorts' => false,
        'Project Groups' => false,
        'Reports' => false,
      }
      affects['Projects'] = true if collection.data_sources.exists?
      affects['Projects'] = true if collection.organizations.exists?
      affects['Projects'] = true if collection.project_access_groups.exists?
      affects['Projects'] = true if collection.coc_codes.reject(&:blank?).any?
      affects['Projects'] = true if collection.projects.exists?
      affects['Cohorts'] = true if collection.cohorts.exists?
      affects['Project Groups'] = true if collection.project_groups.exists?
      affects['Reports'] = true if collection.reports.exists?

      sections_affected = affects.values.count(true)
      # If we haven't chosen any entities, assume project
      collection.update(collection_type: 'Projects') if sections_affected.zero?
      next unless sections_affected == 1

      collection_type = affects.detect { |_, v| v }.first
      collection.update(collection_type: collection_type)
    end
    # HMIS collections only influence project access at this time
    Hmis::AccessGroup.update_all(collection_type: 'Projects')
  end
end
