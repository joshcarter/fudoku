# Solver for this problem:
#
#        +-+ +-+
#        |B|-|E|
#        +-+ +-+
#       / | X | \
#    +-+ +-+ +-+ +-+
#    |A|-|C|-|F|-|H|
#    +-+ +-+ +-+ +-+
#       \ | X | /
#        +-+ +-+
#        |D|-|G|
#        +-+ +-+
#
# Contraits:
# - Cell A has starting value of 2
# - Numbers 1..8 must be used exactly once
# - A cell cannot have a neighbor whose value is 1 greater or 1
#   less than the cell's value.
#

require 'set'

# Exception class used internally by the solver.
class Solved < Exception
  attr_reader :cells

  def initialize(cells)
    @cells = cells
  end
end

# Exception thrown by Grid#solve() and Grid#[]= if grid is unsolvable.
class Unsolvable < Exception
end

# Grid class used to represent state of our the 8-cell problem.
class Grid
  # Create initial grid
  def initialize
    @possible_values = Set.new([1, 2, 3, 4, 5, 6, 7, 8])

    # Cell map. Set initial known value and all others nil.
    @cells = Hash.new
    @cells[:a] = 2 # known value
    @cells[:b] = nil
    @cells[:c] = nil
    @cells[:d] = nil
    @cells[:e] = nil
    @cells[:f] = nil
    @cells[:g] = nil
    @cells[:h] = nil

    # Figure out peers for each cell. This flat list of peers lets us
    # traverse them quickly when we need to re-evaluate their list
    # of possible values.
    @peers = Hash.new
    @peers[:a] = [:b, :c, :d]
    @peers[:b] = [:a, :c, :e, :f]
    @peers[:c] = [:a, :b, :d, :e, :f, :g]
    @peers[:d] = [:a, :c, :f, :g]
    @peers[:e] = [:b, :c, :f, :h]
    @peers[:f] = [:b, :c, :d, :e, :g, :h]
    @peers[:g] = [:c, :d, :f, :h]
    @peers[:h] = [:e, :f, :g]
    @peers.freeze

    # Calculate options for each unknown cell; this will fill in the
    # nil cells with their initial possible values.
    @cells.each_key do |index|
      update_possible_values(index)
    end
  end

  # Custom dup that copies its cells. Peer list is intentionally not
  # copied, as that can be shared among grids of same dimensions.
  def dup
    copy = super
    @cells = @cells.dup # Need to copy the cells, but nothing else
    copy
  end

  # Updates possible values for a cell. Does nothing if cell is
  # already solved.
  def update_possible_values(index)
    value = @cells[index]

    return if value.class == Fixnum # Cell already solved

    # Remove any values used across the entire grid; each number can
    # only be used once.
    used_values = Set.new

    @cells.each_value do |val|
      if val.class == Fixnum
        used_values << val
      end
    end

    # Now remove the +1 and -1 values of all peers.
    @peers[index].each do |peer|
      peer_value = @cells[peer]

      if peer_value.class == Fixnum
        if peer_value > 1
          used_values << peer_value - 1
        end

        if peer_value < 8
          used_values << peer_value + 1
        end
      end
    end

    # Possible values are everything that's left
    values = (@possible_values - used_values).to_a

    case values.length
    when 0
      puts "this grid is unsolvable; there are no possible values for cell #{index}"
      puts self.to_s
      raise Unsolvable.new("no possible values for cell #{index}")
    when 1
      # Cell is solved. Note: assignment of cell will force peers to
      # update their possible values, i.e. this method is re-entrant.
      puts "setting cell #{index} to #{values.first}"
      self[index] = values.first
    else
      puts "setting cell #{index} to #{values}"
      @cells[index] = values
    end
  end

  # Prints value(s) of particular cell.
  def cell_to_s(idx)
    if @cells[idx].nil?
      "_"
    elsif @cells[idx].class == Fixnum
      "#{@cells[idx]}"
    else
      "#{idx.to_s}" # More than one possible value; just print cell letter
    end
  end

  # Returns grid state in pretty format.
  def to_s
    str = String.new
    str << "      +-+ +-+\n"
    str << "      |#{cell_to_s(:b)}|-|#{cell_to_s(:e)}|\n"
    str << "      +-+ +-+\n"
    str << "     / | X | \\\n"
    str << "  +-+ +-+ +-+ +-+\n"
    str << "  |#{cell_to_s(:a)}|-|#{cell_to_s(:c)}|-|#{cell_to_s(:f)}|-|#{cell_to_s(:h)}|\n"
    str << "  +-+ +-+ +-+ +-+\n"
    str << "     \\ | X | /\n"
    str << "      +-+ +-+\n"
    str << "      |#{cell_to_s(:d)}|-|#{cell_to_s(:g)}|\n"
    str << "      +-+ +-+\n"
    str
  end

  # Get cell value at index.
  def [](index)
    @cells[index]
  end

  # Set cell value at index, forcing peers with unknown value to update
  # their list of possible values. Will throw Unsolvable if setting the
  # cell makes the grid unsolvable.
  def []=(index, value)
    @cells[index] = value
    @peers[index].each { |peer| update_possible_values(peer) }
  end

  # True if all cells are solved.
  def solved?
    @cells.each_value do |value|
      return false if value.class != Fixnum
    end

    return true
  end

  # Main solve method. Will do depth-first search as required to figure
  # out anything that the constraint solver can't figure out. Raises 
  # Unsolvable if puzzle is truly unsolvable.
  def solve
    begin
      solve_with_guesses
    rescue Solved => e
      @cells = e.cells # Copy over cells from solved grid
    end
  end

  # Internal method to do depth-first search. Raises Solved with solution
  # cells when complete (aborting all further searching) or Unsolvable if
  # search can't find any solution.
  def solve_with_guesses
    return if solved?

    # Find all cells with unknown values.  We're guaranteed to have at least
    # one Array value in there because otherwise solved? would have returned
    # true.
    unknown_cells = @cells.select do |index, value|
      value.class == Array
    end

    # Pick cell with least number of unknowns, i.e. the guess of least risk.
    index, values = unknown_cells.min { |a, b| a[1].length <=> b[1].length }

    values.each do |value|
      begin
        # Subsequent work needs to operate on a copy of the grid, as this
        # guess may have been wrong.
        new_grid = self.dup
        puts "guessing cell #{index} value #{value}"
        new_grid[index] = value
        puts "possible grid at this point"
        puts new_grid.to_s
        new_grid.solve_with_guesses

        # Solved. Bail out to top-level solve()
        raise Solved.new(new_grid.instance_variable_get(:@cells))
      rescue Unsolvable
      end
    end

    raise Unsolvable unless solved?
  end
end

g = Grid.new()
g.solve
puts "final solution, yay!"
puts g.to_s
