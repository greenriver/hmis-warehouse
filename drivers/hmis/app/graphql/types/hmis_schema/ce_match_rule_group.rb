# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleGroup < Types::BaseObject
    # Group of CeMatchRules owned by a single owner.
    # Used to display the hierarchy of rules that apply to a given entity,
    # either because they are owned by that entity ("local")
    # or because they are inherited from an ancestor.
    #
    # Underlying object is an OpenStruct shaped like:
    # {
    #   owner: <owner object>,
    #   rules: [<rule objects>],
    #   local: <boolean>,
    # }
    field :owner_id, ID, null: false
    field :owner_name, String, null: false
    field :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwnerType, null: false
    field :local, Boolean, null: false, description: 'True if rules are owned at the current hierarchy level; false if inherited.'
    field :rules, [HmisSchema::CeMatchRule], null: false # Not paginated, since the expected number of rules per owner is small and already loaded into memory.

    def owner_id
      object.owner.id
    end

    def owner_name
      return 'Global' if object.owner.is_a?(GrdaWarehouse::DataSource)

      object.owner.name
    end

    def owner_type
      object.owner.class.sti_name
    end

    def rules
      object.rules.sort_by(&:id)
    end
  end
end
