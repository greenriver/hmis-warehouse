module HmisUtil
  # This utility class can be used for migrating HMIS Configuration between environments. (Staging=>Production, for example.)
  #
  # !!! Use with caution !!!! The import process can generate messiness, use with care and review the config file before importing.
  # The import process does not clear out existing Form Instances, it just adds new rules on top of what's there.
  #
  # Usage:
  #   1. Download file:   HmisUtil::MigrateConfig.new.write_config(filename)
  #   2. (Move file to other environment)
  #   3. Import file:     HmisUtil::MigrateConfig.new.load_config(filename)
  class MigrateConfig
    # Defaults to only export service and custom assessment since that's all we need currently, but could
    # be expended to include client form and other customizable forms.
    FORM_ROLES_TO_EXPORT = [:SERVICE, :CUSTOM_ASSESSMENT].freeze

    def default_filename
      "var/hmis_config_#{Date.current.strftime('%Y-%m-%d')}.json"
    end

    def write_config(filename = default_filename)
      config_object = {}

      # ======== Export Service Types and Service Categories ========
      config_object[:services] = Hmis::Hud::CustomServiceCategory.all.map do |csc|
        next unless csc.service_types.where(hud_record_type: nil).exists? # skip unless custom

        {
          name: csc.name,
          types: csc.service_types.map do |cst|
            {
              name: cst.name,
              supports_bulk_assignment: cst.supports_bulk_assignment,
            }
          end,
        }
      end.compact

      # ======== Export Form Definitions ========
      config_object[:definitions] = Hmis::Form::Definition.where(role: FORM_ROLES_TO_EXPORT).map do |fd|
        fd.slice(:title, :identifier, :role, :version, :status, :definition)
      end

      # ======== Export Form Instances ========
      # Export all non-system instances, even ones for definitions that we didn't export. That lets us get
      # configuration for things like which projects collect CLS or Move-in Date.
      config_object[:instances] = Hmis::Form::Instance.active.not_system.map do |inst|
        next if inst.definition_identifier == 'service' # skip hud default rules

        project = inst.entity if inst.entity_type == 'Hmis::Hud::Project'
        org = inst.entity if inst.entity_type == 'Hmis::Hud::Organization'
        {
          **inst.slice(:definition_identifier, :funder, :project_type, :other_funder, :data_collected_about),
          project_hud_id: project&.project_id,
          org_hud_id: org&.organization_id,
          service_type_name: inst.custom_service_type&.name,
          service_category_name: inst.custom_service_category&.name,
        }
      end.compact

      File.open(filename, 'w') do |f|
        f.write(JSON.pretty_generate(config_object))
      end
    end

    def load_config(filename = default_filename)
      config = JSON.parse(File.read(filename))

      Hmis::Hud::Base.transaction do
        # ======== Import Service Types and Service Categories ========
        csc_name_to_id = {}
        cst_name_to_id = {}
        data_source_id = GrdaWarehouse::DataSource.hmis.first.id
        default_attrs = {
          data_source_id: data_source_id,
          UserID: Hmis::Hud::User.system_user(data_source_id: data_source_id).UserID,
        }
        config['services'].each do |csc|
          category = Hmis::Hud::CustomServiceCategory.where(name: csc['name']).first_or_create!(default_attrs)
          csc_name_to_id[category.name] = category.id

          csc['types'].each do |cst|
            service_type = Hmis::Hud::CustomServiceType.where(name: cst['name'], custom_service_category_id: category.id).first_or_create!(default_attrs)
            service_type.supports_bulk_assignment = cst['supports_bulk_assignment']
            service_type.save!
            cst_name_to_id[service_type.name] = service_type.id
          end
        end

        # ======== Import Form Definitions ========
        config['definitions'].each do |definition|
          next if definition['identifier'] == 'service'

          metadata = definition.excluding('definition')
          fd = Hmis::Form::Definition.where(**metadata).first_or_create!
          fd.definition = definition['definition']
          fd.save!
        end

        # ======== Import Form Instances ========
        config['instances'].each do |inst|
          unless Hmis::Form::Definition.where(identifier: inst['definition_identifier']).exists?
            puts "SKIPPING, failed to find form: #{inst}"
            next
          end

          entity = project_id_to_entity(inst['project_hud_id']) || org_id_to_entity(inst['org_hud_id'])
          if (inst['project_hud_id'] || inst['org_hud_id']) && !entity
            puts "SKIPPING, failed to find entity: #{inst}"
            next
          end

          custom_service_type_id = cst_name_to_id[inst['service_type_name']]
          if inst['service_type_name'] && !custom_service_type_id
            puts "SKIPPING, failed to find service type: #{inst}"
            next
          end

          custom_service_category_id = csc_name_to_id[inst['service_category_name']]
          if inst['service_category_name'] && !custom_service_category_id
            puts "SKIPPING, failed to find service category: #{inst}"
            next
          end

          Hmis::Form::Instance.where(
            **inst.excluding('project_hud_id', 'org_hud_id', 'service_type_name', 'service_category_name'),
            entity: entity,
            custom_service_type_id: custom_service_type_id,
            custom_service_category_id: custom_service_category_id,
          ).first_or_create!
        end
      end
    end

    def project_id_to_entity(project_hud_id)
      Hmis::Hud::Project.hmis.find_by(ProjectID: project_hud_id)
    end

    def org_id_to_entity(org_hud_id)
      Hmis::Hud::Organization.hmis.find_by(OrganizationID: org_hud_id)
    end
  end
end
