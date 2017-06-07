require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test 'unsuccessful edit' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: {user: {name: '', email: 'foo@invalid', password: 'boo', password_confirmation: 'bar'}}
    assert_template 'users/edit'
    assert_select 'div#error_explanation', count:1
    assert_select 'div.alert-danger', count:1
    assert_select 'div.field_with_errors input.form-control', count:4
  end

  test 'successful edit' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    name = 'Foo Bar'
    email = 'foo@bar.com'
    patch user_path(@user), params: {user: {name: name, email: email, password: '', password_confirmation: ''}}
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    assert_not flash.empty?
    assert_select 'div.alert-success', count:1
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end

  test 'successful edit with a forward' do
    get edit_user_path(@user)
    assert_equal edit_user_url(@user), session['forwarding_url']
    log_in_as(@user)
    assert_nil session['forwarding_url']
    assert_redirected_to edit_user_url(@user)
    follow_redirect!
    assert_template 'users/edit'
    name = 'Foo Bar'
    email = 'foo@bar.com'
    patch user_path(@user), params: {user: {name: name, email: email, password: '', password_confirmation: ''}}
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    assert_not flash.empty?
    assert_select 'div.alert-success', count:1
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end
end
