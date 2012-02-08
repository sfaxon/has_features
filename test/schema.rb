require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection(
  :adapter => defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jdbcsqlite3' : 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'test.db')
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :mixins, :force => true do |t|
      t.integer :pos
      t.integer :parent_id
      t.string :parent_type
      t.timestamp
    end
  end
end

def setup_db
  CreateSchema.suppress_messages do
    CreateSchema.migrate(:up)
  end
end

setup_db

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class FeaturedMixin < Mixin
  self.table_name = 'mixins'
  
  has_features :column => "pos", :scope => :parent
end

class FeaturedMixinSub1 < FeaturedMixin
end

class FeaturedMixinSub2 < FeaturedMixin
end

class FeaturedWithStringScopeMixin < ActiveRecord::Base
  self.table_name = 'mixins'

  has_features :column => "pos", :scope => 'parent_id = #{parent_id}'
end

class ArrayScopeFeaturedMixin < Mixin
  self.table_name = 'mixins'

  has_features :column => "pos", :scope => [:parent_id, :parent_type]
end