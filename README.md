Solver for this 8-cell puzzle:

        +-+ +-+
        |B|-|E|
        +-+ +-+
       / | X | \
    +-+ +-+ +-+ +-+
    |A|-|C|-|F|-|H|
    +-+ +-+ +-+ +-+
       \ | X | /
        +-+ +-+
        |D|-|G|
        +-+ +-+

i.e. cell C has neighbors and A, B, D, E, F, G.

Constraints are as follows:

- Cell A has starting value of 2

- Numbers 1..8 must be used exactly once

- A cell cannot have a neighbor whose value is 1 greater or 1
  less than the cell's value.

Run `ruby fudoku.rb` to generate solution.

Implementation Details
----------------------

The Grid class represents the current state of the puzzle. Each solved
cell contains a single value, and each unsolved cell contains an array
of possible values. Taking a cue from Peter Norvig [1], setting any
cell causes all peer cells to update their list of possible values. If
any of these cells reduce to a single value, that'll cause its peers
to recalculate, and so on.

Another important note is that the grid contains a map of every cell's
index to a flat array of all its peers. This map is computed in
initialize() so that the constraint operation (above) can operate very
quickly.

When `Grid.solve_with_guesses` runs, it selects a cell and starts
guessing values. Before each guess the grid is copied, the guess is
made, and constraints applied. The grid is printed at this state. The
solver will recurse until either a solution is found or the exception
`Unsolvable` is raised. The `Unsolvable` forces backtracking and
choosing another possible value.

[1]: http://norvig.com/sudoku.html

License
-------

MIT License
Copyright (c) 2017

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sub-license, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
