require "test_helper"

class Api::PurchasesControllerTest < ActionDispatch::IntegrationTest
  include OpenApiContract

  test "buys a mug in the visitor's button color" do
    with_env("FEATURES__ORANGE_BUTTON_SEGMENTS" => "beta") do
      Rails.app.envs.reload
      post api_v1_purchases_path, params: { quantity: 2 }, headers: { "X-Demo-User" => "beta-02" }, as: :json
    end

    assert_schema_conform(201)
    assert_equal({ "visitor" => "beta-02", "quantity" => 2, "color" => "orange" }, response.parsed_body.slice("visitor", "quantity", "color"))
  ensure
    Rails.app.envs.reload
  end

  test "the body is optional" do
    post api_v1_purchases_path

    assert_schema_conform(201)
    assert_equal 1, response.parsed_body["quantity"]
  end

  test "refuses quantities the spec doesn't allow" do
    [ 0, 11, "2", 1.5 ].each do |quantity|
      post api_v1_purchases_path, params: { quantity: quantity }, as: :json

      assert_response :unprocessable_content
      assert_response_schema_confirm(422)
    end
  end

  # Schemathesis found this one: a JSON array or string used to buy a mug.
  test "refuses a body that isn't a JSON object" do
    [ "[]", "\"mug\"", "null", "3" ].each do |body|
      post api_v1_purchases_path, params: body.dup, headers: { "Content-Type" => "application/json" }

      assert_response :unprocessable_content
      assert_response_schema_confirm(422)
    end
  end

  test "a body that isn't JSON is a 400" do
    post api_v1_purchases_path, params: "{".dup, headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :bad_request
    assert_response_schema_confirm(400)
  end
end
