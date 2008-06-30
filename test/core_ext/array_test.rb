require File.dirname(__FILE__) + "/../test_helper"
require "core_ext/array"

class ArrayTest < Test::Unit::TestCase
  EPSILON = 0.001

  def test_mean_of_empty_array_is_zero
    assert_in_delta 0.0, [].mean, EPSILON
  end

  def test_mean_of_array_with_nil_fails
    assert_raises ArgumentError do
      [1, nil, 2].mean
    end
  end

  def test_mean_of_integers_converted_to_float
    assert_in_delta 2.0, [1, 2, 3].mean, EPSILON
  end

  def test_mean_of_float_array
    assert_in_delta 2.5, [1.5, 2.5, 3.5].mean, EPSILON
  end

  def test_mean_of_single_element_integer_array_is_floated_value_of_that_array
    assert_in_delta 3.0, [3].mean, EPSILON
  end

  def test_sum_of_empty_array_is_identity
    assert_equal 0, [].sum(0)
  end

  def test_sum_of_array_with_nils_raises_argument_error
    assert_raise ArgumentError do
      [1, nil, 2].sum
    end
  end

  def test_stddev_of_empty_array_is_zero
    assert_in_delta 0.0, [].stddev, EPSILON
  end

  def test_stddev_of_array_with_nil_raises_argument_error
    assert_raise ArgumentError do
      [1, nil, 2].stddev
    end
  end

  def test_stddev_of_single_element_array_is_zero
    assert_in_delta 0.0, [3].stddev, EPSILON
  end

  def test_stddev_with_integers
    assert_in_delta 1.0, [1, 2, 3].stddev, EPSILON
  end

  def test_stddev_with_floats
    assert_in_delta 1.0, [1.5, 2.5, 3.5].stddev, EPSILON
  end

  def test_stddev_with_larger_numbers
    assert_in_delta 3.0, [3, 6, 9].stddev, EPSILON
  end
end
