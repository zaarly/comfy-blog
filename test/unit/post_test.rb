require File.expand_path('../test_helper', File.dirname(__FILE__))

class SofaBlog::PostTest < ActiveSupport::TestCase
  
  def test_fixtures_validity
    Blog::Post.all.each do |post|
      assert post.valid?, post.errors.full_messages.to_s
    end
  end
  
  def test_validation
    post = Blog::Post.new
    assert post.invalid?
    assert_has_errors_on post, [:title, :slug, :content]
  end
  
  def test_validation_of_slug_uniqueness
    old_post = blog_posts(:default)
    old_post.update_attributes!(:year => Time.now.year, :month => Time.now.month)
    post = Blog::Post.new(:title => old_post.title, :content => 'Test Content')
    assert post.invalid?
    assert_has_errors_on post, [:slug]
    
    old_post.update_attributes!(:year => 1.year.ago.year, :month => Time.now.month)
    assert post.valid?
  end
  
  def test_creation
    assert_difference 'Blog::Post.count' do
      post = Blog::Post.create!(
        :title    => 'Test Post',
        :content  => 'Test Content'
      )
      assert_equal 'test-post', post.slug
      assert_equal Time.now.year, post.year
      assert_equal Time.now.month, post.month
    end
  end
  
  def test_set_slug
    post = Blog::Post.new(:title => 'Test Title')
    post.send(:set_slug)
    assert_equal 'test-title', post.slug
  end
  
  def test_set_date
    post = Blog::Post.new
    post.send(:set_date)
    assert_equal Time.now.year, post.year
    assert_equal Time.now.month, post.month
  end
  
  def test_sync_tags
    post = blog_posts(:default)
    assert_equal 'Default Tag', post.tag_names
    
    post.tag_names = 'one, two, three'
    assert_equal 'one, two, three', post.tag_names
    
    assert_difference ['Blog::Tag.count', 'Blog::Tagging.count'], 2 do
      post.save!
      post.reload
      assert_equal 'one, two, three', post.tag_names
    end
  end
  
  def test_destroy
    assert_difference ['Blog::Post.count', 'Blog::Comment.count'], -1 do
      blog_posts(:default).destroy
    end
  end
  
  def test_scope_published
    post = blog_posts(:default)
    assert post.is_published?
    assert_equal 1, Blog::Post.published.count
    
    post.update_attribute(:is_published, false)
    assert_equal 0, Blog::Post.published.count
  end
  
  def test_scope_for_year
    assert_equal 1, Blog::Post.for_year(2012).count
    assert_equal 0, Blog::Post.for_year(2013).count
  end
  
  def test_scope_for_month
    assert_equal 1, Blog::Post.for_month(1).count
    assert_equal 0, Blog::Post.for_month(2).count
  end
  
  def test_scope_tagged_with
    assert_equal 1, Blog::Post.tagged_with('Default Tag').count
    assert_equal 0, Blog::Post.tagged_with('invalid').count
  end
  
end
