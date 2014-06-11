2048 Test Plan
==============

The 2048 game can be broken down into four main components that each need to function correctly for the game to work. These are:


* Grid logic

  The grid needs to keep track of whether a cell is empty, or which number is in it. The grid also needs to respond to being moved in four different directions. There are well defined rules for how the grid should react in any state to an input.

* Game logic

  The game itself is more than just moving around numbers on a grid. The game defines the starting numbers that get put into the grid on a new game. The game defines how numbers will be added to the grid after each move. The game also defines the winning and losing conditions. The game is also responsible for keeping track of your score.

* User input

  The game needs to respond to four different user inputs for each direction the grid can be moved. It also needs to respond to any other messages such as restarting the game, quitting, or other events like these.

* User interface

  The grid needs to be displayed correctly after every change. Things like your score and other messages also need to be displayed.


The former two points can be tested effectively in an automated way such as with unit testing or integration testing.

To test grid logic, we will use a bottom up approach. First we will only deal with one column or row at a time, since the game only moves within singular columns or rows at a time. Then we'll check that moving the whole board works, to make sure that rows and columns don't interfere with each other.

We can also use a bottom up approach when testing rows and columns. We can start with an empty row, and test that it stays empty. Then test that a single number moves correctly within a row. Then test that two numbers move correctly within a row, and that they merge if they're equal. Then three numbers, and then four. We should also test that newly merged numbers behave in the same way as numbers we've added to the grid ourselves.

Unit tests can also be used to test the game logic. The board can be put into winning or losing conditions to check that the game sets the winning or losing flags.

Integration testing can also be used at this stage. To test the rest of the functionality of the game, it makes sense to set up an automated playthrough of an entire game, or at least the most important parts of a playthrough: the starting moves of a game, losing, and winning. This can be done by abstracting the input system of the game to allow input from a testing program. Then the program can start a game, and then send the game its list of inputs one by one, checking the state of the game is correct after each one. To make these tests deterministic, the RNG of the game can be "rigged" by seeding it with a known value.

The latter two points are more appropriately tested in a QA kind of way. This is because they are more concerned with if it "looks right" or responds to input "fast" enough or is "user friendly" enough.
