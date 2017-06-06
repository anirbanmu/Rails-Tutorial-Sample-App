require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test "invalid signup info"  do
    get signup_path
    assert_select 'form[action="/signup"]', count: 1
    assert_no_difference 'User.count' do
      post users_path, params: {user: {name: "",
                                       email: "user@invalid",
                                       password: "foo",
                                       password_confirmation: "bar"}}
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation', count:1
    assert_select 'div.alert-danger', count:1
    assert_select 'div.field_with_errors input.form-control', count:4
  end

  test "valid signup info" do
    get signup_path
    assert_difference 'User.count', 1 do
      post signup_path, params: { user: {name: "Example User",
                                         email: "user@example.com",
                                         password: "password",
                                         password_confirmation: "password"}}
    end
    follow_redirect!
    assert_template 'users/show'
    assert_select 'div.alert-success', count:1
    assert_not flash.empty?
    assert is_logged_in?
  end
end
