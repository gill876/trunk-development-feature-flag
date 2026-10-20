require "test_helper"

class Api::DocsControllerTest < ActionDispatch::IntegrationTest
  test "serves the spec and a page to read it" do
    get openapi_path
    assert_response :success
    assert_equal "Flagship Store API", YAML.safe_load(response.body).dig("info", "title")

    get api_docs_path
    assert_select "#swagger-ui"
  end
end
