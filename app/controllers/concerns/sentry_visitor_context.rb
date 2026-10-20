# Tells Sentry who is asking and what their flags say, so an error reads like
# "beta-02 (beta) · flag.orange_button: on (segment beta) · revision flagship-00025-abc".
# Sentry can then show that every event of an issue had a flag on: a job for the kill switch.
module SentryVisitorContext
  private
    def tell_sentry_about(visitor)
      flags = FeatureFlags::KNOWN.index_with do |flag|
        { enabled: FeatureFlags.enabled_for?(flag, visitor), reason: FeatureFlags.reason_for(flag, visitor) }
      end

      Sentry.set_user(id: visitor.id, segment: visitor.cohort)
      Sentry.set_tags(cohort: visitor.cohort, **flags.to_h { |flag, state| [ :"flag.#{flag}", state[:enabled] ? "on" : "off" ] })
      Sentry.set_context("feature_flags", flags)
    end
end
