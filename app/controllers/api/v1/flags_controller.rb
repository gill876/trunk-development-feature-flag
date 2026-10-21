# GET /api/v1/flags: which flags are on for this visitor, and which rule decided. The store's footer, as JSON.
class Api::V1::FlagsController < Api::BaseController
  def index
    render json: {
      visitor: { id: visitor.id, cohort: visitor.cohort },
      flags: FeatureFlags::KNOWN.map { |flag| { name: flag, enabled: FeatureFlags.enabled_for?(flag, visitor), reason: FeatureFlags.reason_for(flag, visitor) } },
      revision: AppInfo.revision,
      version: AppInfo.version
    }
  end
end
