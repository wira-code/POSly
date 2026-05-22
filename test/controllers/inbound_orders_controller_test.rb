require "test_helper"

class InboundOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get inbound_orders_index_url
    assert_response :success
  end

  test "should get show" do
    get inbound_orders_show_url
    assert_response :success
  end

  test "should get new" do
    get inbound_orders_new_url
    assert_response :success
  end

  test "should get create" do
    get inbound_orders_create_url
    assert_response :success
  end
end
