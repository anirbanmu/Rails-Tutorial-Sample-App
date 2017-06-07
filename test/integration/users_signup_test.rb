require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end

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

  test "valid signup info with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post signup_path, params: { user: {name: "Example User",
                                         email: "user@example.com",
                                         password: "password",
                                         password_confirmation: "password"}}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    follow_redirect!
    assert_select 'div.alert-info', count:1

    # Make sure we are redirected to root for unactivated user
    get user_path(user)
    assert_redirected_to root_url

    # Try logging in
    log_in_as(user)
    assert_not is_logged_in?

    # Invalid activation token
    get edit_account_activation_path('garbage', email: user.email)
    assert_not is_logged_in?

    # Invalid email
    get edit_account_activation_path(user.activation_token, email: 'garbage')
    assert_not is_logged_in?

    # Valid activation
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    assert is_logged_in?

    follow_redirect!
    assert_template 'users/show'
    assert_select 'div.alert-success', count:1
    assert_not flash.empty?
  end
end
