# The first link in Rails.app.creds: flags overridden for the current request only.
# It answers with the same interface as Rails.app.envs and Rails.app.credentials
# (option / require / keys / reload), so ActiveSupport::CombinedConfiguration can ask it first.
class FeatureOverrideConfiguration
  def require(*keys)
    option(*keys)
  end

  def option(*keys, default: nil)
    return default unless keys.first == :features && keys.length == 2
    Current.feature_overrides&.dig(keys.last)
  end

  def keys = []
  def reload = nil
end
