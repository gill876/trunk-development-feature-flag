# Per-request state. feature_overrides holds flags flipped for this request only
# (FeatureFlags.enable!, .disable!, .with), and is cleared when the request ends.
class Current < ActiveSupport::CurrentAttributes
  attribute :feature_overrides
end
