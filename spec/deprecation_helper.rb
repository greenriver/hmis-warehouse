# Based on work from:
# https://about.gitlab.com/blog/2021/02/03/how-we-automatically-fixed-hundreds-of-ruby-2-7-deprecation-warnings/
if ENV.key?('RECORD_DEPRECATIONS')
  require 'deprecation_toolkit'
  require 'deprecation_toolkit/rspec'
  DeprecationToolkit::Configuration.test_runner = :rspec
  DeprecationToolkit::Configuration.deprecation_path = 'var/deprecations'
  DeprecationToolkit::Configuration.behavior = DeprecationToolkit::Behaviors::Record

  Warning[:deprecated] = true

  kwargs_warnings = [
    # Taken from https://github.com/jeremyevans/ruby-warning/blob/1.1.0/lib/warning.rb#L18
    /warning: (?:Using the last argument (?:for `.+' )?as keyword parameters is deprecated; maybe \*\* should be added to the call|Passing the keyword argument (?:for `.+' )?as the last hash parameter is deprecated|Splitting the last argument (?:for `.+' )?into positional and keyword parameters is deprecated|The called method (?:`.+' )?is defined here)\n\z/,
  ]
  DeprecationToolkit::Configuration.warnings_treated_as_deprecation = kwargs_warnings
end
