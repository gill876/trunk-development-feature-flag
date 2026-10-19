# Where FeatureFlags looks a flag up, first match wins:
#
#   1. this request's override   FeatureFlags.with(:orange_button, true) { ... }
#   2. ENV                       FEATURES__ORANGE_BUTTON_SEGMENTS=dev,alpha   (set by `make flag`)
#   3. .env, in development only  same names, in a file you don't commit
#   4. encrypted credentials     features: { orange_button: false }   (the default, reviewed in a PR)
#
# 2-4 are exactly Rails 8.2's default Rails.app.creds; this adds 1 in front.
# to_prepare, because FeatureOverrideConfiguration is reloadable code.
Rails.application.config.to_prepare do
  Rails.app.creds = ActiveSupport::CombinedConfiguration.new(
    FeatureOverrideConfiguration.new,
    Rails.app.envs,
    *([ Rails.app.dotenvs ] if Rails.env.development?),
    Rails.app.credentials
  )
end
