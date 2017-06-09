require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test 'micropost interface' do
    log_in_as(@user)
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type=file]'

    # Invalid submission
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: {micropost: {content: ''}}
    end
    assert_select 'div#error_explanation'
    assert_template 'static_pages/home'

    # Valid
    content = 'Content is real'
    picture = fixture_file_upload('test/fixtures/abstract-q-c-640-480-3.jpg', 'image/jpg')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: {micropost: {content: content, picture: picture}}
    end
    assert assigns['micropost'].picture?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-success', count:1
    assert_match content, response.body

    # Delete post
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end

    # Visit different user
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  test 'micropost sidebar count' do
    log_in_as(@user)
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body

    # No posts
    other_user = users(:malory)
    log_in_as(other_user)
    get root_path
    assert_equal 0, other_user.microposts.count
    assert_match "0 microposts", response.body
    content = 'Ok some content'
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: {micropost: {content: content}}
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
  end
end
