# The store's JSON API. openapi/openapi.yaml describes it: the tests check every response
# against that file, and CI checks each new canary against it before it gets any traffic.
class Api::BaseController < ActionController::API
  include ActionController::Cookies
  include BuildHeaders

  rescue_from(ActionDispatch::Http::Parameters::ParseError) { render json: { error: "The body isn't valid JSON." }, status: :bad_request }
  rescue_from(StoreController::SimulatedBug) { |error| render json: { error: error.message }, status: :internal_server_error }
  before_action { raise StoreController::SimulatedBug, StoreController::BROKEN_MESSAGE if ENV["BREAK_STORE"] == "1" }

  private
    def visitor = @visitor ||= Visitor.from(request, cookies)
end
