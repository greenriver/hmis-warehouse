###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientSearchUtil
  class NameSearch
    # Hmis::Hud::Client.matching_search_term(term).pluck(:id, :search_name_full, Arel.sql('ROUND(names.search_score * 100)')).take(20)
    def self.perform(...)
      new.perform(...)
    end

    def self.perform_as_joinable_query(...)
      new.perform_as_joinable_query(...)
    end

    # @param term [String]
    # @param clients [ClientScope]
    def perform_as_joinable_query(term:, clients:)
      term = normalize_search_term(term)
      return nil unless term

      results = filter_clients(term, clients)
      results.select(Arel.sql('"Client"."id" AS client_id, "search_score" AS score'))
    end

    # @param term [String]
    # @param clients [ClientScope]
    # @param sorted [Boolean]
    def perform(term:, clients:, sorted:)
      term = normalize_search_term(term)
      return clients.none unless term

      results = filter_clients(term, clients)
      results = results.order(Arel.sql('search_score DESC'), :id) if sorted
      results
    end

    protected

    def normalize_search_term(term)
      term = term&.strip
      return if term.blank?

      # skip unless term has at least three characters
      return if term.size < 3

      # safety limit
      @term = term.slice(0, 100)
    end

    def filter_clients(original_term, scope)
      # Remove diacritics after we expand variants. If a word has diacritic, the
      # nickname map probably wouldn't be helpful since it's only english names
      variants = expand_nicknames(original_term).map do |variant|
        ActiveSupport::Inflector.transliterate(variant)
      end
      original_term = ActiveSupport::Inflector.transliterate(original_term)

      # string similarity matches on all variants
      name_queries = ([original_term] + variants).map do |variant|
        # give the original term more weight than the variants
        term_weight = variant == original_term ? 1.0 : 0.75
        score_sql = term_score_sql(variant, term_weight: term_weight)

        search_term_scope(variant).
          group(:client_id).
          select(:client_id, Arel.sql("MAX(#{score_sql}) AS search_score"))
      end

      # include first/last prefix match
      prefix_query = prefix_search_term_scope(original_term)
      if prefix_query
        score_sql = term_score_sql(original_term, term_weight: 10.0)
        name_queries.push(
          prefix_query.group(:client_id).select(:client_id, Arel.sql("MAX(#{score_sql}) AS search_score")),
        )
      end

      # union of matches and scores for all term variants
      name_scope_sql = name_queries.compact.map do |query|
        "(#{query.to_sql})"
      end.join(' UNION ALL ')

      sql = <<~SQL
        JOIN (
          SELECT client_id, MAX(search_score) as search_score FROM (#{name_scope_sql}) names GROUP BY 1
        ) names ON "Client".id = names.client_id
      SQL
      scope.joins(sql)
    end

    def term_score_sql(term, term_weight:)
      quoted_term = search_class.connection.quote(term)

      # weight matches against the last name more heavily
      name_score_sql = <<~SQL
        (similarity(#{quoted_term}, #{csn_fn(:last_name)}) * 0.25 + similarity(#{quoted_term}, #{csn_fn(:full_name)})) / 2
      SQL

      # weight matches against the primary name more heavily
      <<~SQL
        (#{name_score_sql}) * (CASE WHEN #{csn_fn(:name_type)} = 'primary' THEN 1.0 ELSE 0.75 END) * #{term_weight}
      SQL
    end

    # if the query appears to be 'last, first' or 'first last'
    def detect_first_last(term)
      case term
      when /,/
        # try last, first prefix match
        last, first = term.split(',', 2).map(&:strip)
      when / /
        first, last = term.split(' ', 2).map(&:strip)
      else
        return []
      end
      [first, last]
    end

    def prefix_search_term_scope(term)
      q_fn_pfx, q_ln_pfx = detect_first_last(term).map do |str|
        search_class.connection.quote("#{str}%")
      end
      # q_fn_pfx = '"Jane%"'
      # q_ln_pfx = '"Smith%"'
      return unless q_fn_pfx && q_ln_pfx

      ClientSearchUtil::ClientSearchableName.
        where("#{csn_fn(:last_name)} ILIKE #{q_ln_pfx} AND #{csn_fn(:full_name)} ILIKE #{q_fn_pfx}")
    end

    def search_term_scope(term)
      quoted_term = search_class.connection.quote(term)

      # use the operator form of word similarity so pg uses its index
      ClientSearchUtil::ClientSearchableName.where("#{quoted_term} <% #{csn_fn(:full_name)}")
    end

    # expand variants
    def expand_nicknames(term)
      term = term.downcase
      parts = term.split(' ').map(&:downcase).filter { |str| str.length > 1 }
      # [name, nickname]
      nickname_map = Nickname.joins(:nicknames).
        where(name: parts).
        pluck(:name, Arel.sql('nicknames_nicknames.name'))

      nickname_map.map do |name, nickname|
        parts.map { |part| part == name ? nickname : part }.join(' ')
      end
    end

    def csn_fn(field)
      search_class.arel_table[field].to_sql
    end

    def search_class
      ClientSearchUtil::ClientSearchableName
    end
  end
end
