# frozen_string_literal: true

# route the field to the appropriate resolver
module Hmis::Ce::Match
  class FieldMap
    def instance_value(client, field)
      resolver, resolved_field = resolver_for(field)
      resolver.instance_value(client, resolved_field)
    end

    def arel_field(field)
      resolver, resolved_field = resolver_for(field)
      resolver.arel_field(resolved_field)
    end

    protected

    # given a field of 'cde::custom_assessment:xyz', the appropriate resolver
    def resolver_for(field)
      # default to the client resolver if the field lacks fq namespaces
      return [registered_resolvers['client'], field] unless field =~ /\./

      resolver_name, resolved_field = field.split('.', 2)
      resolver = registered_resolvers[resolver_name]
      raise ArgumentError, "unknown resolver for \"#{field}\"" unless resolver

      [resolver, resolved_field]
    end

    def registered_resolvers
      @registered_resolvers ||= {
        'cde' => Hmis::Ce::Match::CdeFieldMap.new,
        'client' => Hmis::Ce::Match::ClientFieldMap.new,
      }
    end
  end
end
