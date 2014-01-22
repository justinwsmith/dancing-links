
# Copyright (c) 2006 Justin W Smith

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


require 'test/unit'
require 'dancing_links'

class Array
  def to_s
    s = "["
    each_index do |i|
      s << " " + self[i].to_s
      s << ", " unless (i == self.length-1)
    end
    s << "]"
  end
  
  def comb_helper head, tail, &block
    if tail.length == 0
      block.call(head)
    else
      tail.each_index do |i|
        t = tail.clone
        t.delete_at(i)
        comb_helper head.clone << tail[i], t, &block
      end
    end
  end

  def combinations &block
    comb_helper [], self, &block
  end
end

class TC_DancingLinks < Test::Unit::TestCase
  include DancingLinks
  
  def setup
    @a1 = [ [1, 0, 1], [0, 0, 1], [1, 1, 0], [ 1, 0, 0] ]
    @b1 = [ [ true, false, true],
            [false, false, true],
            [true, true, false],
            [true, false, false] ]
    @matrix1 = SparseMatrix.new convert_rows_fixnum_to_boolean(@a1)
    @s1 = [ [ 0, 0, 1], [ 1, 1, 0] ]

    @a2 = [ [1, 0, 1], [1, 1, 0], [0, 1, 1], [ 0, 0, 0] ]
    @e2 = [ [0, 0, 1] ]
    @matrix2 = SparseMatrix.new convert_rows_fixnum_to_boolean(@a2)
    @s2 = [ [0, 0, 1], [ 1, 1, 0] ]

    @a3 = [ [1, 0, 1], [1, 1, 0], [0, 1, 1], [ 1, 1, 1] ]
    @matrix3 = SparseMatrix.new convert_rows_fixnum_to_boolean(@a3)
    @s3 = [[1, 1, 1]]

    @a4 = [ [1, 0, 1], [1, 1, 0], [0, 1, 1], [ 0, 1, 0] ]
    @matrix4 = SparseMatrix.new convert_rows_fixnum_to_boolean(@a4)
    @s4 = [[1, 0, 1], [0, 1, 0]]

    @a5 = [ [1, 0, 1], [1, 1, 0], [1, 1, 1], [ 0, 1, 1] ]
    @matrix5 = SparseMatrix.new convert_rows_fixnum_to_boolean(@a4)
    @s5 = [[1, 1, 1]]

    @a6 = [ [1, 0, 1], [1, 0, 0], [1, 1, 1], [ 0, 1, 1], [1, 1, 0] ]

    @a7 = [ [0, 0, 1], [ 0, 1, 0], [0, 1, 1], [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1] ]
    @s7 = [
            [ [ 1, 1, 1] ],
            [ [ 0, 1, 1], [ 1, 0, 0 ] ].sort,
            [ [ 1, 0, 1], [ 0, 1, 0 ] ].sort,
            [ [ 1, 1, 0], [ 0, 0, 1] ].sort,
            [ [ 0, 0, 1], [0, 1, 0], [1, 0, 0] ].sort ]
  end
  
  def test_convert_rows
    assert_equal(@a1, convert_rows_boolean_to_fixnum(@b1) )
    assert_equal(@b1, convert_rows_fixnum_to_boolean(@a1) )
  end
  
  def test_sparse_matrix
    root = @matrix1.root
    assert_equal(3, root.count)
    assert_equal(3, root.right.count)
    assert_equal(1, root.right.right.count)
    assert_equal(2, root.right.right.right.count)
    assert_equal(root.right.up.left, root.right.up)
    assert_equal(root.left.up.left, root.right.right.right.down.down)
    assert_equal(root.right.down.header, root.right)
    assert_equal(root.left.up.header, root.left)
    assert_equal(root.right.right.right.right, root)
    assert_equal(root.left.left.left.left, root)
    
    assert_equal(0, root.left.down.row_num)
    assert_equal(1, root.left.down.down.row_num)
    assert_equal(2, root.right.right.down.row_num)
    assert_equal(3, root.right.up.row_num)
        
    assert_equal(0, root.right.index)
    assert_equal(3, root.right.count)
    assert_equal(1, root.right.right.index)
    assert_equal(1, root.right.right.count)
    assert_equal(2, root.right.right.right.index)
    assert_equal(2, root.right.right.right.count)
    
  end

  def test_remove_rows_for_header
    root = @matrix1.root
    remove_rows_for_header root.right
    assert_equal( 0,  root.right.count)
    assert_equal( 0,  root.right.right.count)
    assert_equal( 1,  root.right.right.right.count)
    assert_equal( root.right.right.right,  root.left)
    assert_equal( root.left.down,  root.right.right.right.up)
    assert_equal( 1, root.left.down.row_num)
  end
  
  def test_restore_rows_for_header
    root = @matrix1.root
    restore_rows_for_header( remove_rows_for_header( root.right))
    test_sparse_matrix
  end

  def test_select_row
    root = @matrix1.root
    header_stk, row_stk_stk = select_row root.right.right.down

    assert_equal( 1, root.count)
    assert_equal( 1, root.right.count)
    assert_equal( 2, root.right.index )
    assert_equal( root.right.down, root.left.down)
    assert_equal( root.right.down.down, root.left)
    assert_equal( root.right.down.down, root.left)

  end

  def test_restore_selected_row

    root = @matrix1.root
    restore_selected_row( *select_row( root.right.right.down))
    test_sparse_matrix
    restore_selected_row( *select_row( root.right.down))
    test_sparse_matrix
    restore_selected_row( *select_row( root.left.down))
    test_sparse_matrix
    restore_selected_row( *select_row( root.left.up))
    test_sparse_matrix
    restore_selected_row( *select_row( root.right.up))
    test_sparse_matrix
    restore_selected_row( *select_row( root.left.up))
    test_sparse_matrix

    header_stk, row_stk_stk = select_row( root.right.right.down)
    restore_selected_row( *select_row( root.right.down) )
    restore_selected_row( header_stk, row_stk_stk)
    test_sparse_matrix

  end

  def test_min_column
    root = @matrix1.root
    header = min_column root
    assert_equal( root.right.right, header)
  end

  def test_solve_exact_cover
    s = convert_rows_boolean_to_fixnum(solve_exact_cover( @b1))
    assert_equal(@s1.sort, s.sort)

    s = solve_exact_cover( convert_rows_fixnum_to_boolean(@a2))
    assert_equal(0, s)

    s = convert_rows_boolean_to_fixnum(solve_exact_cover( convert_rows_fixnum_to_boolean(@a2), convert_rows_fixnum_to_boolean(@e2)))
    assert_equal(@s2.sort, s.sort)

    s = convert_rows_boolean_to_fixnum(solve_exact_cover( convert_rows_fixnum_to_boolean(@a3)))
    assert_equal(@s3.sort, s.sort)

    s = convert_rows_boolean_to_fixnum(solve_exact_cover( convert_rows_fixnum_to_boolean(@a4)))
    assert_equal(@s4.sort, s.sort)

    s = convert_rows_boolean_to_fixnum(solve_exact_cover( convert_rows_fixnum_to_boolean(@a5)))
    assert_equal(@s5.sort, s.sort)

    s = solve_exact_cover( convert_rows_fixnum_to_boolean(@a6)){false}
    assert_equal(2, s)

  end
  
  def test_solve_exact_cover2

    @a7.combinations do |comb|
      s = @s7.clone
      solve_exact_cover(convert_rows_fixnum_to_boolean(comb)) do |result|
        result = convert_rows_boolean_to_fixnum( result ).sort!
        assert( s.member?( result ), "\ncomb: #{comb.to_s}\nresult: #{result}\nsolutions left: #{s.to_s}")
        s.delete result
        false
      end
      assert_equal( [], s)
    end
    
  end

end
