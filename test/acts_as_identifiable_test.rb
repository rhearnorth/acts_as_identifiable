# Test for acts_as_identifiable
#
# There are several ways to execute this test:
#
# 1. Open this file on a Mac in TextMate and press APPLE + R
# 2. Go to "vendor/plugins/acts_as_identifiable/test" and run "rake test" in a terminal window
# 3. Run "rake test:plugins" in a terminal window to execute tests of all plugins
#
# For further information see http://blog.funkensturm.de/downloads

require 'test/unit'

require 'rubygems'
require 'active_record'
require 'action_view'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
$stdout = StringIO.new # Prevent ActiveRecord's annoying schema statements

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table "users", :force => true do |t|
      t.string "my_username"
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db # Because the plugin needs an existing table before initialization (e.g. for attr_readonly)

$:.unshift File.dirname(__FILE__) + '/../lib' # make "lib" known to "require"
require 'active_record/acts/identifiable'
require File.dirname(__FILE__) + '/../init' # Initialize Plugin

class User < ActiveRecord::Base
  acts_as_identifiable :column => 'my_username'
end

teardown_db # Because UserTest's setup method won't execute setup_db otherwise

class UserTest < Test::Unit::TestCase
  
  def setup
    setup_db
    assert @u1 = User.create!(:my_username => 'Martin')
    assert @u2 = User.create!(:my_username => 'Martin Luther')
    assert @u3 = User.create!(:my_username => 'Martin Luther King')
    assert @u4 = User.create!(:my_username => 'Martin Luther King jr.')
    assert @u5 = User.create!(:my_username => 'abcdefghijklmnop')
    assert @u6 = User.create!(:my_username => 'xxx')
    assert @u7 = User.create!(:my_username => 'Märtin Gruß')
    assert @u8 = User.create!(:my_username => 'Märtin Jonés')
    assert @u9 = User.create!(:my_username => 'Martin Müller')
  end

  def teardown
    teardown_db
  end

  def test_special_characters
    assert_equal 7, User.identify('Märtin G')
    assert_equal 9, User.identify('Müller')
    assert_equal 7, User.identify('Gruß')
  end
  
  def test_ambivalent_match
    assert !User.identify('Mart')
    assert !User.identify('King Luther Martin')
    assert !User.identify('King Luther')
    assert_equal 4, User.identify('Martin jr.')
    assert_equal 7, User.identify('Gruß')
    assert !User.identify('Jonés Smith')
  end
  
  def test_multiple_partial_patterns
    assert_equal 5, User.identify('a b c')
    assert_equal 5, User.identify(' p o n ')
    assert_equal 5, User.identify('abc def ghi')
    assert_equal 5, User.identify('  ghi fg  mn   ')
  end
  
  def test_exact_match
    assert_equal 1, User.identify('Martin')
    assert_equal 2, User.identify('Martin Luther')
    assert_equal 4, User.identify('Martin Luther King jr.')
    assert_equal 4, User.identify('    Martin Luther King jr.     ')
    assert_equal 4, User.identify('    Martin     Luther    King       jr.     ')
  end
  
  def test_whitespace_and_minimum_length
    assert !User.identify('') 
    assert !User.identify(' ') 
    assert !User.identify('           ') 
    assert !User.identify('        xx       ') 
    assert !User.identify('xx') 
    assert_equal 6, User.identify('      xxx       ') 
  end

end
