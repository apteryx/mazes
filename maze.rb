class Maze
  # convert maze cell coordinates to corresponding grid coords
  def m2g *coords
    coords.map { |c| c * 2 + 1 }
  end

  # initialize a grid representing a maze of heigh n, width m
  def initialize n, m
    @maze_h = n
    @maze_w = m
    grid_h, grid_w = m2g(n, m)
    @grid = Array.new(grid_h) { Array.new(grid_w) }
  end

  # load a bitstring into the grid
  def load maze_string
    ints = maze_string.chars.map { |e| e.to_i }
    @grid.map! { |row| ints.slice!(0, row.size) }
  end

  # return true if path exists from (begX, begY) to (endX, endY)
  def solve begX, begY, endX, endY
    walk(begX, begY, endX, endY)
  end

  # same as solved but prints trace if path found
  def trace begX, begY, endX, endY
    if (solution = walk(begX, begY, endX, endY))
      solution.each do |x, y|
        gx, gy = m2g(x, y)
        @grid[gy][gx] = 2
        display
        @grid[gy][gx] = 0
        puts "\n"
      end
      return true
    else
      return false
    end
  end

  # test [x, y] are valid maze coordinates
  def on_maze? x, y
    x.between?(0, @maze_w-1) && y.between?(0, @maze_h-1)
  end

  # find walls around cell [mx, my]
  def walls mx, my
    gx, gy = m2g(mx, my)
    {
      :up => @grid[gy-1][gx] == 1,
      :left => @grid[gy][gx-1] == 1,
      :right => @grid[gy][gx+1] == 1,
      :down => @grid[gy+1][gx] == 1
    }
  end

  # return reachable cells adjacent to [nx, ny]
  def find_next nx, ny
    walls = walls(nx, ny)

    legal = []
    legal << [nx, ny-1] unless walls[:up]
    legal << [nx-1, ny] unless walls[:left]
    legal << [nx+1, ny] unless walls[:right]
    legal << [nx, ny+1] unless walls[:down]

    return legal
  end

  def walkback trace, x, y
    return if trace[[x, y]].nil?
    # follow backpointers to start of the trace
    cell = [x, y]
    sol = [cell]
    until (cell = trace[cell]) == :start
      sol.unshift(cell)
    end
    return sol
  end

  # BFS storing backptrs to mark visited squares and trace solution
  def walk begX, begY, endX, endY
    return nil unless on_maze?(begX, begY) && on_maze?(endX, endY)

    # current level of search (array of cells)
    ply = [[begX, begY]]
    # maps each visited cell to the cell it was visited from
    backptrs = { [begY, begX] => :start }

    loop do
      nextply = []
      ply.each do |c|
        # find legal adjacent cells
        find_next(*c).each do |n|
          # add to next level of search if unvisited
          if backptrs[n].nil?
            nextply << n
            backptrs[n] = c
          end
        end
      end
      ply = nextply
      break if ply.empty?
    end
    puts backptrs

    return walkback(backptrs, endX, endY)
  end

  # convert binary (or ternary) array to chars for display
  def mchars arr
    arr.map.with_index do |row, i|
      i.even? ? convert_even(row) : convert_odd(row)
    end
  end

  # converts array from ints to chars, then prints row by row
  def display
    self.mchars(@grid).each { |row| puts row.join('') }
  end

  def convert_even row
    row.map.with_index do |b, i|
      case b
      when 0
        ' '
      when 1
        i.even? ? '+' : '-'
      when 2
        '*'
      end
    end
  end

  def convert_odd row
    row.map do |b|
      case b
      when 0
        ' '
      when 1
        '|'
      when 2
        '*'
      end
    end
  end

  # set all grid points from [min_x, y] to [max_x, y] to walls
  def draw_horz_wall y, min_x, max_x
    @grid[y].map!.with_index do |b, i|
      i.between?(*m2g(min_x, max_x)) ? 1 : b
    end

    # create a passage
    @grid[y][*m2g(rand(min_x...max_x))] = 0
  end

  # set all grid points from [x, min_y] to [x, max_y] to walls
  def draw_vert_wall x, min_y, max_y
    @grid.each.with_index do |r, i|
      r[x] = 1 if i.between?(*m2g(min_y, max_y))
    end

    # create passage
    @grid[*m2g(rand(min_y...max_y))][x] = 0
  end

  # performs recursive division on given subdivision of maze (defaults to
  # entire maze for start of algorithm
  def recursive_div xrange=(0...@maze_w-1), yrange=(0...@maze_h-1)
    return if xrange.first == xrange.last || yrange.first == yrange.last

    # vsplit: last col left of split
    # hsplit: last row above split
    vsplit = rand(xrange)
    hsplit = rand(yrange)

    minX, maxX = [xrange.first, xrange.last]
    minY, maxY = [yrange.first, yrange.last]
    wminX, wmaxX, wminY, wmaxY = m2g(minX, maxX, minY, maxY)

    vert_wall = vsplit*2 + 2
    draw_vert_wall(vert_wall, minY, maxY)

    horz_wall = hsplit*2 + 2
    draw_horz_wall(horz_wall, minX, maxX)

    left_range = (minX...vsplit)
    right_range = (vsplit+1...maxX)
    top_range = (minY...hsplit)
    bottom_range = (hsplit+1...maxY)

    recursive_div(left_range, top_range)
    recursive_div(right_range, top_range)
    recursive_div(left_range, bottom_range)
    recursive_div(right_range, bottom_range)

  end

  def redesign
    # reset the grid
    @grid.map! { |row| row.map! { |b| 0 } }
    draw_borders

    # recursive division
    recursive_div
  end

  def draw_borders
    @grid.first.fill(1)
    @grid.last.fill(1)
    @grid.each do |row|
      row[0] = 1
      row[-1] = 1
    end
  end
end
