require 'test/unit'
 
require 'rubygems'
gem 'rails'
require 'active_record'
require 'action_view'
require 'active_support'
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/info.log")
RAILS_ROOT = File.join( File.dirname(__FILE__), "../../../.." )

module Papermill
  OPTIONS = {
    :aliases => {
      'tall' => :"1000x1000",
      :small => "100x100",
      :hashed_style => {:geometry => "100x100"}
    }
  }
end
require File.join(File.dirname(__FILE__), '../init')
 
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "test.sqlite3")
ActiveRecord::Schema.define(:version => 1) do
  create_table :papermill_assets, :force => true do |t|
    t.string   :title, :file_file_name, :file_content_type, :assetable_type, :assetable_key, :type
    t.integer  :file_file_size, :position, :assetable_id
    t.timestamps
  end
  
  create_table :articles, :force => true do |t|
    t.string :type
  end
end

class MyAsset < PapermillAsset
end

class Article < ActiveRecord::Base
  def self.table_name 
    :articles
  end
  papermill
  papermill :my_assets, :class_name => MyAsset
end

class PapermillTest < Test::Unit::TestCase
  @article = Article.create!
  @file = File.new(File.join(File.dirname(__FILE__), "fixtures", "5k.png"), 'rb')
  PapermillAsset.create!(:Filedata => @file, :assetable => @article, :assetable_key => "asset1")
  PapermillAsset.create!(:Filedata => @file, :assetable => @article, :assetable_key => "asset2")
  MyAsset.create!(:Filedata => @file, :assetable => @article, :assetable_key => "my_assets")
  MyAsset.create!(:Filedata => @file, :assetable => @article, :assetable_key => "my_assets")
  
  def initialize(*args)
    super
    @article = Article.first
    @file = File.new(File.join(File.dirname(__FILE__), "fixtures", "5k.png"), 'rb')
    @asset1 = PapermillAsset.all[0]
    @asset2 = PapermillAsset.all[1]
    @asset3 = PapermillAsset.all[2]
    @asset4 = PapermillAsset.all[3]
  end
  
  def test_active_record_hooks
    assert_equal @article.assets.map(&:id).sort, [@asset1, @asset2, @asset3, @asset4].map(&:id).sort
    assert_equal @article.assets(:asset1), [@asset1]
    assert_equal @article.assets(:my_assets), @article.my_assets
  end

  def test_default_active_record_hooks_retrieve_order
    assert_equal @article.my_assets.map(&:position), [1,2]
  end
  
  def test_id_partition
    assert_equal @asset1.id_partition, "000/000/001"
  end
  
  def test_name
    assert_equal @asset1.name, "5k.png"
  end
  
  def test_width
    assert_equal @asset1.width, 434.0
  end
  
  def test_height
    assert_equal @asset1.height, 66.0
  end
  
  def test_size
    assert_equal @asset1.size, 4456
  end
  
  def test_url
    assert_equal @asset1.url, "/system/papermill/000/000/001/original/5k.png"
    assert_equal @asset1.url("400x300#"), "/system/papermill/000/000/001/400x300%23/5k.png"
  end
  
  def test_path
    assert_equal @asset1.path, "./test/../../../../public/system/papermill/000/000/001/original/5k.png"
    assert_equal @asset1.path("400x300#"), "./test/../../../../public/system/papermill/000/000/001/400x300#/5k.png"
  end
  
  def test_content_type
    assert_equal @file.get_content_type, "image/png"
    assert_equal @asset1.content_type, "image/png"
  end
  
  def test_is_image
    assert @asset1.image?
  end
  
  def test_compute_style
    assert_equal PapermillAsset.compute_style(:tall), :geometry => "1000x1000"
    assert_equal PapermillAsset.compute_style("tall"),  :geometry => "1000x1000"
    assert_equal PapermillAsset.compute_style(:small),  :geometry => "100x100"
    assert_equal PapermillAsset.compute_style("small"),  :geometry => "100x100"
    assert_equal PapermillAsset.compute_style("hashed_style"), :geometry => "100x100"
    assert_equal PapermillAsset.compute_style("100x100"),  :geometry => "100x100"
    assert_equal PapermillAsset.compute_style(:"100x100"),  :geometry => "100x100"
    Papermill::PAPERMILL_DEFAULTS[:alias_only] = true
    assert_equal PapermillAsset.compute_style("100x100"), false
  end
end