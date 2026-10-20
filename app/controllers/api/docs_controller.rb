# Every revision serves its own copy of the spec, so a canary's tag URL shows the canary's API.
class Api::DocsController < ActionController::Base
  def show
    render layout: false
  end

  def spec
    send_file Rails.root.join("openapi/openapi.yaml"), type: "application/yaml", disposition: "inline"
  end
end
