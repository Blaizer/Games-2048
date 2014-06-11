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
