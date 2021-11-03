require 'aws-sdk-route53'
require 'amazing_print'

class Domains
  def list!
    results = route53.list_resource_record_sets(hosted_zone_id: hosted_zone).flat_map do |r|
      r.resource_record_sets
    end

    results.each do |r|
      next if r.name.match?(/domainkey/)

      if ['A', 'CNAME'].include?(r.type)
        value = r&.alias_target&.dns_name || r.resource_records.first&.value
        puts format('%50s -> %s', r.name, value)
      end
    end
  end

  def hosted_zone
    return @hosted_zone unless @hosted_zone.nil?

    found = route53.list_hosted_zones_by_name.to_h[:hosted_zones].find do |zone|
      zone[:name] == 'openpath.host.'
    end

    @hosted_zone = found[:id]
  end

  define_method(:route53) { Aws::Route53::Client.new }
end
