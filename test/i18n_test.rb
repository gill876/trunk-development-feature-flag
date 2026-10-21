require "test_helper"

class I18nTest < ActiveSupport::TestCase
  test "ja.yml translates every key in en.yml" do
    assert_empty keys("en") - keys("ja")
  end

  private
    def keys(locale) = flatten(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale))

    def flatten(hash, prefix = nil)
      hash.flat_map do |key, value|
        path = [ prefix, key ].compact.join(".")
        value.is_a?(Hash) ? flatten(value, path) : [ path ]
      end
    end
end
