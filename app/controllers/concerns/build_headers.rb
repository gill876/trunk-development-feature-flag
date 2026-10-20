# Every store response says which Cloud Run revision and which build answered. The bots read these.
module BuildHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_build_headers
  end

  private
    def set_build_headers
      response.set_header "X-Revision", AppInfo.revision
      response.set_header "X-App-Version", AppInfo.version
    end
end
