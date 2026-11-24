###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# An abstraction around a kubernetes cronjob
# https://github.com/k8s-ruby/k8s-ruby
class Cronjob
  attr_accessor :args
  attr_accessor :capacity_type
  attr_accessor :description
  attr_accessor :jobname
  attr_accessor :schedule_expression
  attr_accessor :k8s_image
  attr_accessor :k8s_service_account_name

  MAX_NAME_LENGTH = 52

  def initialize(description:, schedule_expression:, command:, capacity_type: 'spot')
    self.description = description
    self.schedule_expression = schedule_expression
    self.args = command
    self.jobname = namify(description)
    self.capacity_type = capacity_type
    self.k8s_image = ENV.fetch('K8S_IMAGE', 'set_k8s_image_somehow_to_test:v1') # provided by kyverno
    self.k8s_service_account_name = ENV.fetch('K8S_SERVICE_ACCOUNT_NAME', 'default') # provided by kyverno
  end

  def self.existing_cron_names
    dummy.existing_cron_names
  end

  def self.existing_vpa_names
    dummy.existing_vpa_names
  end

  def self.clear_defunct!(keep_names)
    dummy.clear_defunct!(keep_names)
  end

  def self.clear_defunct_vpas!
    dummy.clear_defunct_vpas!
  end

  def self.dummy
    new(description: 'none', schedule_expression: '', command: 'none', capacity_type: 'spot')
  end

  def existing_cron_names
    names_of(cron_list)
  end

  def existing_vpa_names
    names_of(vpa_list)
  end

  # Deletes rails cronjobs that are no longer in the schedule. Cascades to their Jobs.
  def clear_defunct!(keep_names)
    keep = Set.new(keep_names)
    cron_list.each do |cron|
      next if keep.include?(cron.metadata.name)

      Rails.logger.warn "Deleting #{cron.metadata.namespace}/#{cron.metadata.name} which is no longer scheduled (#{cron.metadata.annotations&.description})"
      crons.delete_resource(cron)
    end
  end

  def clear_defunct_vpas!
    Rails.logger.info 'Looking for orphaned VPAs'
    existing_crons = existing_cron_names
    vpa_list.each do |vpa|
      next if existing_crons.include?(vpa.metadata.labels['cronjob-name'])

      Rails.logger.warn "Deleting #{vpa.metadata.name} which is orphaned"
      vpas.delete_resource(vpa) # was: vpas.delete(vpa.name) -> nil -> wiped every VPA
    end
  end

  # Callers pass the names already in the cluster, listed once per deploy rather than once per job
  def run!(existing_crons:, existing_vpas:)
    existing_crons.include?(jobname) ? update_cron! : create_cron!
    existing_vpas.include?(vpa_name) ? update_vpa! : create_vpa!
  end

  private

  def create_cron!
    Rails.logger.info "Creating #{jobname} with capacity #{capacity_type} on schedule of #{schedule_expression}"
    crons.create_resource(materialized_cronjob)
  end

  # Updating in place keeps the CronJob's UID, so its finished Jobs (owned via
  # ownerReferences) survive the deploy and the history limits keep applying.
  def update_cron!
    Rails.logger.info "Updating #{jobname} with capacity #{capacity_type} on schedule of #{schedule_expression}"
    desired = cronjob_definition
    # JSON Patch replace, not merge patch, so fields removed from the template are removed here too
    crons.json_patch(
      jobname,
      [
        { op: 'add', path: '/metadata/labels', value: desired.dig('metadata', 'labels') || {} },
        { op: 'add', path: '/metadata/annotations', value: desired.dig('metadata', 'annotations') || {} },
        { op: 'replace', path: '/spec', value: desired.fetch('spec') },
      ],
    )
  end

  # vpa is a vertical pod autoscaler
  def create_vpa!
    Rails.logger.info "Creating #{vpa_name} vertical pod autoscaler (VPA)"
    vpas.create_resource(materialized_vpa)
  end

  def update_vpa!
    Rails.logger.info "Updating #{vpa_name} vertical pod autoscaler (VPA)"
    existing = vpas.get(vpa_name)
    existing[:spec][:updatePolicy] = materialized_vpa[:spec][:updatePolicy]
    existing[:spec][:resourcePolicy] = materialized_vpa[:spec][:resourcePolicy]
    vpas.update_resource(existing)
  end

  def namify(string)
    string.
      gsub(/[^a-zA-Z0-9]/, '-').
      sub(/interruptable-(false|true)/, '').
      sub(/rake-/, '').
      squeeze('-')[0, MAX_NAME_LENGTH].sub(/-+$/, '')
  end

  def materialized_cronjob
    K8s::Resource.new(cronjob_definition)
  end

  def cronjob_definition
    @cronjob_definition ||= YAML.load(
      ERB.new(configmap.data['cronjob.yaml']).result(binding),
    )
  end

  # vertical pod autoscaler
  def materialized_vpa
    K8s::Resource.new(
      YAML.load(
        ERB.new(configmap.data['vpa.yaml']).result(binding),
      ),
    )
  end

  def vpa_name
    "cronjob-#{jobname}"
  end

  def names_of(resources)
    Set.new(resources.map { |r| r.metadata.name })
  end

  def cron_list
    crons.list(labelSelector: { 'cron-source' => 'rails' })
  end

  def vpa_list
    vpas.list(labelSelector: { 'cron-source' => 'rails' })
  end

  def namespace
    ENV.fetch('K8S_NAMESPACE', 'namespace-should-be-set-via-kyverno-policy')
  end

  def crons
    client.api('batch/v1').resource('cronjobs', namespace: namespace)
  end

  def vpas
    client.api('autoscaling.k8s.io/v1').resource('verticalpodautoscalers', namespace: namespace)
  end

  def configmap
    client.
      api('v1').
      resource('configmaps', namespace: namespace).
      list(labelSelector: { 'cron-source' => 'rails' }).
      first
  end

  def client
    @client ||=
      if ENV['KUBE_CONFIG_PATH'].present?
        kube_config = File.read(ENV['KUBE_CONFIG_PATH'])

        # We can't have host networking because that will mess up connecting to redis/db/etc. in development
        # We can't easily/portably forward to a kind cluster running on the host
        # So, we connect over a docker network...
        # - Kind running a cluster already on a network called "kind" likely
        # - docker compose override getting this container on the kind network
        # - Some .envrc scripting to populate this value from docker network inspect and docker container ls
        # - Doesn't distinguish between multiple kind clusters
        server_ip = ENV.fetch('K8S_API_HOST_AND_PORT')
        File.write('.kube_config', kube_config.gsub(/127\.0\.0\.1:\d+/, server_ip))

        K8s::Client.config(K8s::Config.load_file('.kube_config'))
      else
        K8s::Client.in_cluster_config
      end
  end
end
