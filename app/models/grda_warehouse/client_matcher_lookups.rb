
class GrdaWarehouse::ClientMatcherLookups
  def register(name)
    @lookups ||= {}
    lookup = case name
    when :ssn
      SsnLookup.new
    when :ssn_last_four
      SsnLookup.new
    when :proper_name
      ProperNameLookup.new
    when :dob
      DobLookup.new
    when :client_stub
      ClientStubLookup.new
    else
      raise "unknown lookup #{name}"
    end
    @lookups[:name] = lookup
  end

  def perform(clients)
    clients.in_batches(of: 5_000) do |batch|
      batch.pluck(:id, :FirstName, :LastName, :SSN, :DOB).each do |attrs|
        client = ClientStub.new(*attrs)
        @lookups.each_value do |lookup|
          lookup.add(client)
        end
      end
    end
  end

  protected

  # helper classes

  ClientStub = Struct.new(:id, :first_name, :last_name, :ssn, :dob)

  BaseLookup = Class.new do
    def initialize
      @lookup = {}
    end
  end

  DobLookup = Class.new(BaseLookup) do
    def get_ids(dob)
      return [] unless dob
      @lookup[dob]&.uniq || []
    end

    def add(client)
      return unless client.dob

      @lookup[dob] ||= []
      @lookup[dob].push(client.id)
    end
  end

  ProperNameLookup = Class.new(BaseLookup) do
    def get_ids(first_name:, last_name:)
      first_name = normalize(first_name)
      last_name = normalize(last_name)
      return [] unless first_name && last_name

      @lookup[[first_name, last_name]]&.uniq || []
    end

    def add(client)
      first_name = normalize(first_name)
      last_name = normalize(last_name)
      return unless first_name && last_name

      key = [first_name, last_name]
      @lookup[key] ||= []
      @lookup[key].push(id)
    end

    protected

    def normalize(str)
      str ? str.downcase.strip.gsub(/[^a-z0-9]/i, '').presence : nil
    end
  end

  SsnLookup = Class.new(BaseLookup) do
    def get_ids(ssn)
      return [] unless ::HudUtility2024.valid_social?(ssn)
      @lookup[ssn]&.uniq || []
    end

    def add(client)
      key = client.ssn
      return unless key

      @lookup[key] ||= []
      @lookup[key].push(client.id)
    end
  end

  SsnLastFourLookup = Class.new(BaseLookup) do
    def get_ids(ssn)
      return [] unless ::HudUtility2024.valid_last_four_social?(ssn)
      @lookup[ssn]&.uniq || []
    end

    def add(client)
      key = client.ssn&[-4..-1]
      return unless key

      @lookup[key] ||= []
      @lookup[key].push(client.id)
    end
  end

  ClientStubLookup = Class.new(BaseLookup) do
    def get_client(id)
      @lookup[id]
    end

    def add(client)
      found = @lookup[client.id]
      return unless found
      # reshape for upsert
      {SSN: found.ssn, DOB: found.dob, id: found.id}
    end
  end
end
