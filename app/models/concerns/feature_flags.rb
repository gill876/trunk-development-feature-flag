# Feature flags without a gem, from "Rails Feature Flags Without a Gem" (codewithrails.com).
# Flags are read through Rails.app.creds (see config/initializers/credentials.rb).
#
# Two changes from the article, both marked "Changed":
#   - lists can come from ENV as "dev,alpha,beta" strings
#   - percentage buckets are a method, so the store's footer can show a visitor's bucket
# reason_for and KNOWN are new, for the footer, the API and Sentry.
module FeatureFlags
  extend self

  # Every flag the app checks. The API lists them and Sentry tags errors with them.
  KNOWN = %i[orange_button].freeze

  def enabled?(flag_name)
    cast_boolean(Rails.app.creds.option(:features, flag_name, default: false))
  end

  def disabled?(flag_name) = !enabled?(flag_name)

  # Targeting order: allowlist, then segments, then percentage, then the on/off switch.
  # Once a percentage is set, the on/off switch is never reached: "everyone" is 100.
  def enabled_for?(flag_name, user)
    return true if allowlisted?(flag_name, user)
    return true if segment_match?(flag_name, user)
    return percentage_match?(flag_name, user) if rollout_percentage(flag_name)
    enabled?(flag_name)
  end

  def enable!(flag_name)
    (Current.feature_overrides ||= {})[flag_name] = true
  end

  def disable!(flag_name)
    (Current.feature_overrides ||= {})[flag_name] = false
  end

  def with(flag_name, value)
    old = Current.feature_overrides&.dig(flag_name)
    value ? enable!(flag_name) : disable!(flag_name)
    yield
  ensure
    old.nil? ? Current.feature_overrides&.delete(flag_name) : Current.feature_overrides[flag_name] = old
  end

  # Which rule decided, checked in the same order as enabled_for?.
  def reason_for(flag_name, user)
    return "allowlisted" if allowlisted?(flag_name, user)
    segment = segments(flag_name).find { |s| user.try(:"#{s}?") }
    return "segment #{segment}" if segment

    if (percentage = rollout_percentage(flag_name))
      inside = percentage_match?(flag_name, user)
      return "bucket #{bucket(flag_name, user)} is #{inside ? 'inside' : 'outside'} the #{percentage}% rollout"
    end

    enabled?(flag_name) ? "on for everyone" : "no rule matched"
  end

  # 0-99, from the flag and the user: the same user always lands in the same bucket.
  def bucket(flag_name, user)
    Digest::MD5.hexdigest("#{flag_name}-#{user.id}").first(8).to_i(16) % 100
  end

  private

  def cast_boolean(value) = ActiveModel::Type::Boolean.new.cast(value)
  def creds_option(flag, suffix) = Rails.app.creds.option(:features, :"#{flag}#{suffix}", default: nil)
  def rollout_percentage(flag) = creds_option(flag, :_percentage)&.to_i
  def allowlist(flag) = to_list(creds_option(flag, :_users))
  def segments(flag) = to_list(creds_option(flag, :_segments))

  # Changed: ENV values are always strings, so FEATURES__ORANGE_BUTTON_SEGMENTS=dev,alpha
  # arrives as "dev,alpha". The article's code expects an array and would call .any? on a String.
  def to_list(value) = value.is_a?(String) ? value.split(",").map(&:strip).compact_blank : Array(value)

  def allowlisted?(flag, user)
    list = allowlist(flag)
    list.include?(user.id) || list.include?(user.email)
  end

  def segment_match?(flag, user)
    segments(flag).any? { |s| user.try(:"#{s}?") }
  end

  # Changed: the hash moved into #bucket; the rule is the article's.
  def percentage_match?(flag, user)
    bucket(flag, user) < rollout_percentage(flag)
  end
end
