require "test_helper"

class DailyReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get daily_reports_index_url
    assert_response :success
  end
end
