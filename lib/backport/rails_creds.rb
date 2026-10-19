# Rails.app.creds, Rails.app.envs and Rails.app.dotenvs, backported from Rails main (unreleased 8.2)
# at rails/rails@1d11045254. config/application.rb loads this only when Rails doesn't have them yet.
#
# The three classes in active_support/ are upstream files copied verbatim. The two modules below
# hold upstream methods, copied verbatim too, that Rails 8.2 adds to classes Rails 8.1 already has.
#
# When you upgrade to Rails 8.2: delete lib/backport/ and its line in config/application.rb.
# test/lib/backport_test.rb fails on 8.2 to remind you.
#
# MIT License: see lib/backport/MIT-LICENSE.

# Lets `require "active_support/env_configuration"` (used by dot_env_configuration.rb) find the copy.
$LOAD_PATH << File.expand_path(__dir__)

require "active_support/encrypted_configuration"
require "active_support/env_configuration"
require "active_support/dot_env_configuration"
require "active_support/combined_configuration"

module Backport
  # From activesupport/lib/active_support/encrypted_configuration.rb on Rails main.
  module EncryptedConfigurationLookup
    # Find singular or nested keys.
    # Raises `KeyError` if not found or nil.
    def require(*key)
      value = dig(*key)

      if !value.nil?
        value
      else
        raise KeyError, "Missing key: #{key.inspect}"
      end
    end

    # Find singular or nested keys.
    # Returns `nil` if the key isn't found.
    # If a `default` value is defined, it (or its callable value) will be returned on a missing key or nil value.
    def option(*key, default: nil)
      value = dig(*key)

      if !value.nil?
        value
      elsif default.respond_to?(:call)
        default.call
      else
        default
      end
    end

    # Reload the cached values in case any of them changed or new ones were added during runtime.
    def reload
      @config = @options = nil
    end
  end

  # From railties/lib/rails/application.rb on Rails main.
  module ApplicationCreds
    # Returns an ActiveSupport::CombinedConfiguration instance that combines
    # access to the encrypted credentials available via #credentials and keys
    # used for the same purpose in ENV.
    #
    # In the development environment, .env variables are also included, and looked up
    # after ENV and before the encrypted credentials.
    def creds
      if Rails.env.development?
        @creds ||= ActiveSupport::CombinedConfiguration.new(envs, dotenvs, credentials)
      else
        @creds ||= ActiveSupport::CombinedConfiguration.new(envs, credentials)
      end
    end

    # Allows for a custom combined configuration to be used for creds.
    attr_writer :creds

    # Returns an ActiveSupport::EnvConfiguration instance that provides
    # access to the ENV variables through symbol-based lookup.
    def envs
      @envs ||= ActiveSupport::EnvConfiguration.new
    end

    # Returns an ActiveSupport::DotEnvConfiguration instance that provides
    # access to the variables in +.env+ through symbol-based lookup.
    def dotenvs(path = Rails.root.join(".env"))
      @dotenvs ||= {}
      @dotenvs[path] ||= ActiveSupport::DotEnvConfiguration.new(path)
    end
  end
end

ActiveSupport::EncryptedConfiguration.include(Backport::EncryptedConfigurationLookup)
Rails::Application.include(Backport::ApplicationCreds)

# Rails main: `alias :app :application` in railties/lib/rails.rb.
Rails.singleton_class.alias_method(:app, :application) unless Rails.respond_to?(:app)
