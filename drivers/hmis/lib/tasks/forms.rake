# frozen_string_literal: true

namespace :forms do
  desc 'backfill the direct association between CDEDs and form definitions'
  # rails driver:hmis:forms:backfill_custom_data_element_form_definitions[form_definition_identifier]
  task :backfill_custom_data_element_form_definitions, [:form_definition_identifier] => :environment do |_task, args|
    raise ArgumentError, 'form_definition_identifier requires' unless args.form_definition_identifier.present?
    next unless HmisEnforcement.hmis_enabled?

    fd = Hmis::Form::Definition.find_by!(identifier: args.form_definition_identifier)

    Hmis::Hud::CustomDataElementDefinition.transaction do
      items = fd.link_id_item_hash.values

      key_owner_pairs = items.filter_map do |item|
        key = item.dig('mapping', 'custom_field_key')
        next unless key

        rt = item.dig('mapping', 'record_type')
        owner_type = rt ? Hmis::Form::RecordType.find(rt).owner_type : fd.owner_class.sti_name

        # Mirror generator special-case
        if owner_type == 'Hmis::Hud::HmisService'
          owner_type = fd.identifier == 'service' ? 'Hmis::Hud::Service' : 'Hmis::Hud::CustomService'
        end

        [key, owner_type]
      end.uniq

      # no form items
      if key_owner_pairs.empty?
        puts "forms:backfill_custom_data_element_form_definitions: no custom_field_key mappings found for form '#{fd.identifier}'"
        next
      end

      # Build an OR scope for key+owner_type pairs
      scope = key_owner_pairs.
        map { |key, owner_type| Hmis::Hud::CustomDataElementDefinition.where(key: key, owner_type: owner_type) }.
        reduce(:or)

      # restrict by data_source_id(s)
      ds_ids = GrdaWarehouse::DataSource.hmis.pluck(:id)
      scope = scope.where(data_source_id: ds_ids)

      updated_keys = []

      scope.find_each do |cded|
        raise "Hmis::Hud::CustomDataElementDefinition##{cded.id} belongs to an unexpected form: \"#{cded.form_definition_identifier}\"" if cded.form_definition_identifier.present? && cded.form_definition_identifier != fd.identifier

        cded.update!(form_definition_identifier: fd.identifier) # creates PaperTrail version
        updated_keys << cded.key unless updated_keys.include?(cded.key)
      end

      if updated_keys.any?
        puts "forms:backfill_custom_data_element_form_definitions: updated #{updated_keys.size} CDED key(s) for form '#{fd.identifier}': #{updated_keys.sort.join(', ')}"
      else
        puts "forms:backfill_custom_data_element_form_definitions: no matching CDEDs to update for form '#{fd.identifier}'"
      end
    end
  end
end
