# frozen_string_literal: true

# Support legacy gemspecs (e.g., stupidedi) that still call the removed
# Gem::Specification#has_rdoc= writer. The method disappeared in RubyGems 4 /
# Ruby 3.4, so we provide a no-op shim until the upstream gem is updated.
unless Gem::Specification.method_defined?(:has_rdoc=)
  Gem::Specification.class_eval do
    attr_accessor :has_rdoc
  end
end
