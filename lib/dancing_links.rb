
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


module DancingLinks

private
=begin rdoc
This class is used internally by the "Dancing Links" algorithm.

This "matrix" contains nodes for all of the "1"s of the matrix.
The nodes linked together in a doubly-linked chain both horizontally and vertically.
Each column in the matrix has a header node, and the column headers have a "header" called the root.

The headers, links, counters, etc... all serve to do the "book keeping" of the algorithm
so that columns/rows can quickly be removed/replaced while the search occuring.

The algorithm is essentially a depth-first search (aka backtracking) with the matrix
facilitating the neccessary operations.

=end
  class SparseMatrix

=begin rdoc
  All nodes within the matrix are instances of this class.
=end
    class SparseMatrixNode
      def initialize row_num=-1, header=self, left=self, right=self, up=self, down=self
        @row_num = row_num
        @header = header
        @left = left
        @right = right
        @up = up
        @down = down
        
        #puts "row: #{row_num}"
        
        @header.count = (@header.count + 1) if @header
        @left.right = self if @left
        @right.left = self if @right
        @up.down = self if @up
        @down.up = self if @down
      end

      attr_accessor :up, :down, :left, :right, :header, :row_num
    end

=begin rdoc
  The class for the header nodes within the matrix.  Adds two attributes that are
  needed by the headers.
=end
    class SparseMatrixHeader < SparseMatrixNode
      def initialize index=nil, *args
        super( -1, *args )
        @index = index
        @count = 0
      end
      
      attr_accessor :count, :index
    end

=begin rdoc
  The class for the root node of the matrix. Adds one attribute that is needed
  by the root node.
=end
    class SparseMatrixRoot < SparseMatrixNode
      def initialize *args
        super( -1, nil, *args )
        @count = 0
      end
      attr_accessor :count
    end

=begin rdoc
  creates the root node and calls build_sparse_matrix to construct the matrix.
  * matrix - an array of boolean arrays.  This array represents the available rows from which the algorithm must choose.
=end
    def initialize matrix
      #puts "init"
      @root = SparseMatrixRoot.new
      build_sparse_matrix(matrix)
      #puts "end-init"
    end

=begin rdoc
  Iterates through the matrix (an array of boolean arrays).  When finding a "true"
  value, it constructs a node and places the node appropriately within the matrix.
  
  Note that any columns (from the array) which contain no "true" values will simply
  be ignored.  The algorithm will still attempt to find a solution for the existing
  columns.
=end
    def build_sparse_matrix(matrix)
      matrix.each_index do |i|
        row = matrix[i]
        row_node = nil
        row.each_index do |j|
          if row[j]
            header = get_column_header j
            if row_node
              row_node = node =
                SparseMatrixNode.new( i, header, row_node, row_node.right, header.up, header)
            else
              node =
                SparseMatrixNode.new( i, header, nil, nil, header.up, header)
              row_node= node.left= node.right= node
            end
          end
        end
      end
    end

=begin rdoc
  A utility for build_sparse_matrix.  Finds and/or constructs (if needed) the header
  node for a given column.
=end
    def get_column_header index
      header = @root.right
      
      while header != @root && header.index <= index
        if header.index == index
          return header
        end
        header = header.right
      end
      new_header = SparseMatrixHeader.new( index, @root, header.left, header)

    end

    attr_accessor :root
  end

=begin rdoc
An internal recursive method which does the "searching" for the solution.
=end
  def solve( root, selected_rows, sol_count, &block )

# terminating condition
    if root.right == root
      unless block == nil
        block.call(selected_rows)
      end
      sol_count += 1
      return sol_count
    end

# determine direction of search (which column to proceed with)
    header = min_column root
    if header.count == 0
      #puts header.index
      return sol_count
    end
    
    node = header.down
    
# iterate through rows with nodes in the column
    while node != header
      header_stk, row_stk_stk = select_row node
      sol_count = solve( root, selected_rows.push(node.row_num), sol_count, &block)
      selected_rows.pop
      restore_selected_row header_stk, row_stk_stk
      node = node.down
    end
    sol_count
  end

=begin rdoc
An internal utility method which modifies the "sparse matrix"
=end
  def select_row row_node
    row_stk_stk = Array.new
    header_stk = Array.new
    node = row_node
    loop do
      header = node.header
      row_stk_stk.push( remove_rows_for_header(header) )
      remove_horizontal header

      header_stk.push(header)
      node = node.right
      break if node == row_node
    end
    [header_stk, row_stk_stk]
  end
  
=begin rdoc
An internal utility method which modifies the "sparse matrix"
=end
  def restore_selected_row header_stk, row_stk_stk
    until header_stk.empty?
      row_stk = row_stk_stk.pop
      header = header_stk.pop

      restore_horizontal header
      restore_rows_for_header row_stk
    end
  end

=begin rdoc
An internal utility method which modifies the "sparse matrix"
=end
  def remove_rows_for_header header
    row_stk = Array.new
    col_node = header.down
    while col_node != header
      node = col_node
      row_stk.push( node )
      loop do
        remove_vertical node
        node = node.right
        break if node == col_node
      end
      col_node = col_node.down
    end
    row_stk
  end

=begin rdoc
An internal utility method which modifies the "sparse matrix"
=end
  def restore_rows_for_header row_stk
    until row_stk.empty?
      node = col_node = row_stk.pop
      loop do
        restore_vertical node
        node = node.right
        break if node == col_node
      end
    end
  end

=begin rdoc
An internal utility method which detrmines the column with which to proceed.
=end
  def min_column root
    node = root.right
    min = nil
    while node != root 
      min ||= node
      if node.count < min.count
        min = node
      end
      node = node.right
    end
    min
  end

=begin rdoc
An internal utility method which modifies a node within the "sparse matrix"
=end
  def restore_horizontal node
    node.left.right = node
    node.right.left = node
    node.header.count = node.header.count + 1
  end

=begin rdoc
An internal utility method which modifies a node within the "sparse matrix"
=end
  def restore_vertical node
    node.up.down = node
    node.down.up = node
    node.header.count = node.header.count + 1
  end

=begin rdoc
An internal utility method which modifies a node within the "sparse matrix"
=end
  def remove_horizontal node
    node.left.right = node.right
    node.right.left = node.left
    node.header.count = node.header.count - 1
    node
  end

=begin rdoc
An internal utility method which modifies a node within the "sparse matrix"
=end
  def remove_vertical node
    node.up.down = node.down
    node.down.up = node.up
    node.header.count = node.header.count - 1
    node
  end
  
public

=begin rdoc
Attempts to solve an "exact cover" problem represented by the given arrays.

* available - an array of boolean arrays. Each boolean array represent one of the available vectors. true <-> 1, false <-> 0.  Available vectors will be added to the existing vectors to form the resulting solution.
* existing - an array of boolean arrays. Each boolean array represent one of the  vectors. true <-> 1, false <-> 0.  Existing vectors are assumed to be non-conflicting, and will used as part of the resulting solution.
* block - a "block" or Proc.  This block will be called for each solution found.

The return value:
* If no block is given then the first solution found will be returned.
* If a block is given, and when called returns any value other than false or nil, the algorithm will stop, and return the result from the block.
* If a block is given, but the block never returns any value other than false or nil, the total number of solutions found will be returned.

=end 
  def solve_exact_cover(available, existing = [], &block)
    matrix = SparseMatrix.new available
    existing.each do |row|
      row.each_index do |i|
        if row[i]
          node = matrix.root.right
          unless until node == matrix.root
              if node.index == i
                remove_rows_for_header node
                remove_horizontal node
                break true
              end
              node = node.right
            end
          then
            throw "Column conflict or not found."
          end
        end
      end
    end
    
    solution = existing.clone
    solve(matrix.root, [], 0) do |sel|
      sel.each do |row|
        solution.push(available[row])
      end

      unless block == nil
        if(result = block.call(solution))
          return result
        end
      else
        return solution
      end
      solution = existing.clone
    end
  end

=begin rdoc
  This utility method will convert an array of 0's and 1's to an array of booleans.
  
  Used to facilitate the displaying of 0's and 1's in problems/solution, which is easier to read.
=end
  def convert_row_fixnum_to_boolean ary
    Array.new(ary.length) { |i| ary[i] == 1 } unless ary == nil
  end

=begin rdoc
  This utility method will convert an array of fixnum arrays (0's and 1's) to an array of boolean arrays.
  
  Used to facilitate the displaying of 0's and 1's in problems/solution, which is easier to read.
=end
  def convert_rows_fixnum_to_boolean ary
    Array.new(ary.length) { |i| convert_row_fixnum_to_boolean ary[i] } unless ary == nil
  end

=begin rdoc
  This utility method will convert an array of booleans to an array of 0's and 1's
  
  Used to facilitate the displaying of 0's and 1's in problems/solution, which is easier to read.
=end
  def convert_row_boolean_to_fixnum ary
    Array.new(ary.length) { |i| ary[i] ? 1 : 0 } unless ary == nil
  end

=begin rdoc
  This utility method will convert an array of boolean arrays to an array of fixnum arrays (0's and 1's).
  
  Used to facilitate the displaying of 0's and 1's in problems/solution, which is easier to read.
=end
  def convert_rows_boolean_to_fixnum ary
    Array.new(ary.length) { |i| convert_row_boolean_to_fixnum ary[i] } unless ary == nil
  end

end
