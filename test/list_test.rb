require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 3.0.0'
require 'active_record'
require 'ruby-debug'

require File.join(File.dirname(__FILE__), '../lib/has_features')
require File.join(File.dirname(__FILE__), 'schema')

class FeaturedTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| FeaturedMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
    FeaturedMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  end

  def test_next_prev
    assert_equal FeaturedMixin.find(2), FeaturedMixin.find(1).lower_item
    assert_nil FeaturedMixin.find(1).higher_item
    assert_equal FeaturedMixin.find(3), FeaturedMixin.find(4).higher_item
    assert_nil FeaturedMixin.find(4).lower_item
  end

  def test_injection
    item = FeaturedMixin.new(:parent_id => 1)
    assert_equal '"mixins"."parent_id" = 1', item.scope_condition
    assert_equal "pos", item.featured_position_column
  end

  def test_insert
    new = FeaturedMixin.create(:parent_id => 20)
    assert_equal nil, new.pos
    assert !new.first?
    assert !new.last?
  end
  
  def test_featuring
    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 1, new.pos
    assert new.featured?
    assert new.featured
    assert new.first?
    assert new.last?

    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = FeaturedMixin.create(:parent_id => 0)
    new.featured = true
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end
  
  def test_unfeaturing
    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 1, new.pos
    new.featured = false
    assert_nil new.pos
  end

  def test_feature_at
    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 1, new.pos

    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 2, new.pos

    new = FeaturedMixin.create(:parent_id => 20)
    new.featured = true
    assert_equal 3, new.pos

    new4 = FeaturedMixin.create(:parent_id => 20)
    new4.featured = true
    assert_equal 4, new4.pos

    new4.feature_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.feature_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = FeaturedMixin.create(:parent_id => 20)
    new5.featured = true
    assert_equal 5, new5.pos

    new5.feature_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    FeaturedMixin.find(2).destroy

    assert_equal [1, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    assert_equal 1, FeaturedMixin.find(1).pos
    assert_equal 2, FeaturedMixin.find(3).pos
    assert_equal 3, FeaturedMixin.find(4).pos

    FeaturedMixin.find(1).destroy

    assert_equal [3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    assert_equal 1, FeaturedMixin.find(3).pos
    assert_equal 2, FeaturedMixin.find(4).pos
  end

  def test_with_string_based_scope
    new = FeaturedWithStringScopeMixin.create(:parent_id => 500)
    new.featured = true
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = FeaturedMixin.create, FeaturedMixin.create, FeaturedMixin.create
    new1.featured = true
    new2.featured = true
    new3.featured = true
    new2.move_higher
    assert_equal [new2, new1, new3], FeaturedMixin.where('parent_id IS NULL').order('pos')
  end

  def test_unfeature_should_then_fail_in_list? 
    assert_equal true, FeaturedMixin.find(1).in_list?
    FeaturedMixin.find(1).unfeature
    assert_equal false, FeaturedMixin.find(1).in_list?
  end 
  
  def test_unfeature_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  
    FeaturedMixin.find(2).unfeature 
  
    assert_equal [2, 1, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  
    assert_equal 1,   FeaturedMixin.find(1).pos
    assert_equal nil, FeaturedMixin.find(2).pos
    assert_equal 2,   FeaturedMixin.find(3).pos
    assert_equal 3,   FeaturedMixin.find(4).pos
  end 
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  
    FeaturedMixin.find(2).unfeature 
    FeaturedMixin.find(2).destroy 
  
    assert_equal [1, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)
  
    assert_equal 1, FeaturedMixin.find(1).pos
    assert_equal 2, FeaturedMixin.find(3).pos
    assert_equal 3, FeaturedMixin.find(4).pos
  end 
  
  def test_before_destroy_callbacks_do_not_update_position_to_nil_before_deleting_the_record
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    # We need to trigger all the before_destroy callbacks without actually
    # destroying the record so we can see the affect the callbacks have on
    # the record.
    list = FeaturedMixin.find(2)
    if list.respond_to?(:run_callbacks)
      list.run_callbacks(:destroy)
    else
      list.send(:callback, :before_destroy)
    end

    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5).order('pos').map(&:id)

    assert_equal 1, FeaturedMixin.find(1).pos
    assert_equal 2, FeaturedMixin.find(2).pos
    assert_equal 2, FeaturedMixin.find(3).pos
    assert_equal 3, FeaturedMixin.find(4).pos
  end

end

class FeaturedSubTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |i| ((i % 2 == 1) ? FeaturedMixinSub1 : FeaturedMixinSub2).create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)
    FeaturedMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)
  end

  def test_next_prev
    assert_equal FeaturedMixin.find(2), FeaturedMixin.find(1).lower_item
    assert_nil FeaturedMixin.find(1).higher_item
    assert_equal FeaturedMixin.find(3), FeaturedMixin.find(4).higher_item
    assert_nil FeaturedMixin.find(4).lower_item
  end

  def test_injection
    item = FeaturedMixin.new("parent_id"=>1)
    assert_equal '"mixins"."parent_id" = 1', item.scope_condition
    assert_equal "pos", item.featured_position_column
  end

  def test_feature_at
    new = FeaturedMixin.create("parent_id" => 20)
    new.featured = true
    assert_equal 1, new.pos

    new = FeaturedMixinSub1.create("parent_id" => 20)
    new.featured = true
    assert_equal 2, new.pos

    new = FeaturedMixinSub2.create("parent_id" => 20)
    new.featured = true
    assert_equal 3, new.pos

    new4 = FeaturedMixin.create("parent_id" => 20)
    new4.featured = true
    assert_equal 4, new4.pos

    new4.feature_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.feature_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = FeaturedMixinSub1.create("parent_id" => 20)
    new5.featured = true
    assert_equal 5, new5.pos

    new5.feature_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    FeaturedMixin.find(2).destroy

    assert_equal [1, 3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    assert_equal 1, FeaturedMixin.find(1).pos
    assert_equal 2, FeaturedMixin.find(3).pos
    assert_equal 3, FeaturedMixin.find(4).pos

    FeaturedMixin.find(1).destroy

    assert_equal [3, 4], FeaturedMixin.where(:parent_id => 5000).order('pos').map(&:id)

    assert_equal 1, FeaturedMixin.find(3).pos
    assert_equal 2, FeaturedMixin.find(4).pos
  end

end

class ArrayScopeFeaturedTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ArrayScopeFeaturedMixin.create! :pos => counter, :parent_id => 5, :parent_type => 'ParentClass' }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
    ArrayScopeFeaturedMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  end

  def test_next_prev
    assert_equal ArrayScopeFeaturedMixin.find(2), ArrayScopeFeaturedMixin.find(1).lower_item
    assert_nil ArrayScopeFeaturedMixin.find(1).higher_item
    assert_equal ArrayScopeFeaturedMixin.find(3), ArrayScopeFeaturedMixin.find(4).higher_item
    assert_nil ArrayScopeFeaturedMixin.find(4).lower_item
  end

  def test_injection
    item = ArrayScopeFeaturedMixin.new(:parent_id => 1, :parent_type => 'ParentClass')
    assert_equal '"mixins"."parent_id" = 1 AND "mixins"."parent_type" = \'ParentClass\'', item.scope_condition
    assert_equal "pos", item.featured_position_column
  end

  def test_insert
    ArrayScopeFeaturedMixin.destroy_all
    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ArrayScopeFeaturedMixin.create(:parent_id => 0, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_feature_at
    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert new.featured?
    assert new.featured
    assert_equal 1, new.pos

    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 2, new.pos

    new = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new.featured = true
    assert_equal 3, new.pos

    new4 = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new4.featured = true
    assert_equal 4, new4.pos

    new4.feature_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.feature_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ArrayScopeFeaturedMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    new5.featured = true
    assert_equal 5, new5.pos

    new5.feature_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    ArrayScopeFeaturedMixin.find(2).destroy

    assert_equal [1, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    assert_equal 1, ArrayScopeFeaturedMixin.find(1).pos
    assert_equal 2, ArrayScopeFeaturedMixin.find(3).pos
    assert_equal 3, ArrayScopeFeaturedMixin.find(4).pos

    ArrayScopeFeaturedMixin.find(1).destroy

    assert_equal [3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)

    assert_equal 1, ArrayScopeFeaturedMixin.find(3).pos
    assert_equal 2, ArrayScopeFeaturedMixin.find(4).pos
  end
  
  def test_unfeature_should_then_fail_in_list? 
    assert_equal true, ArrayScopeFeaturedMixin.find(1).in_list?
    ArrayScopeFeaturedMixin.find(1).unfeature
    assert_equal false, ArrayScopeFeaturedMixin.find(1).in_list?
  end 
  
  def test_unfeature_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  
    ArrayScopeFeaturedMixin.find(2).unfeature 
  
    assert_equal [2, 1, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  
    assert_equal 1,   ArrayScopeFeaturedMixin.find(1).pos
    assert_equal nil, ArrayScopeFeaturedMixin.find(2).pos
    assert_equal 2,   ArrayScopeFeaturedMixin.find(3).pos
    assert_equal 3,   ArrayScopeFeaturedMixin.find(4).pos
  end 
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  
    ArrayScopeFeaturedMixin.find(2).unfeature 
    ArrayScopeFeaturedMixin.find(2).destroy 
  
    assert_equal [1, 3, 4], ArrayScopeFeaturedMixin.where(:parent_id => 5, :parent_type => 'ParentClass').order('pos').map(&:id)
  
    assert_equal 1, ArrayScopeFeaturedMixin.find(1).pos
    assert_equal 2, ArrayScopeFeaturedMixin.find(3).pos
    assert_equal 3, ArrayScopeFeaturedMixin.find(4).pos
  end 
  
end

