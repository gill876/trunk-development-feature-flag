# POST /api/v1/purchases: what the Buy now button calls. Nothing is sold or stored; the answer
# echoes the order back, so the page has something to show.
class Api::V1::PurchasesController < Api::BaseController
  QUANTITIES = 1..10

  def create
    # Rails puts a JSON body that isn't an object (an array, a string, null) in params[:_json].
    return refuse "The body must be a JSON object." if params.key?(:_json)

    quantity = params.fetch(:quantity, 1)
    return refuse "quantity must be a whole number from 1 to 10." unless quantity.is_a?(Integer) && QUANTITIES.cover?(quantity)

    render status: :created, json: {
      id: "order-#{SecureRandom.hex(4)}",
      visitor: visitor.id,
      quantity: quantity,
      color: FeatureFlags.enabled_for?(:orange_button, visitor) ? "orange" : "blue",
      revision: AppInfo.revision,
      version: AppInfo.version
    }
  end

  private
    def refuse(message) = render(json: { error: message }, status: :unprocessable_content)
end
