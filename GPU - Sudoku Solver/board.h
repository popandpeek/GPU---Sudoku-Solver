/*
** Ben Pittman
** Greg Smith
** Calvin Winston Fei
** Term Project - board.h
** Static class for checking solutions.
** Assumptions: Assumes valid board size and 1D memory allocation
*/

#include <algorithm>
#include <vector>
#include <iterator>
#include <stdio.h>
#include <iostream>
#include <set>

#pragma once

const int BOARD_SIZE = 81;
const int SUB_BOARD_SIZE = 9;
const int SUB_BOARD_DIM = 3;

class Board {

public:

	// Array of bool pointers to hold cells for board
	// 0 item in each array signifies filled or empty, 1-9 signifies filled value or potential value
	bool **board = new bool*[BOARD_SIZE];
	int empty_cells = 0;

	// Used in the print function
	char* border;

	// Used to get potential bool array
	int* to_pass = nullptr;

	// Used to get integer array of board values
	int* board_to_int = nullptr;

	Board();

	~Board();

	// Method to set the board according to passed integer array
	// assumes the filled integer array is of size BOARD_SIZE contains only values between 1 and 9	
	void set_board(int*);
	
	// Updates the potentials after a cell gets filled
	void update_potentials(int, int);

	// sets a cell
	void set_cell(int, int, int);

	// sets a cell using 1d coordinates
	void set_cell(int, int);

	// method for finding potential values for empty cells
	void annotate_potential_entries();

	// Helper method to get value in cell
	int get_entry(int);

	// Helper function to get a cells potential or filled value(s)
	int* get_potentials(int);

	// Helper method to get potential values in an unfilled cell
	std::set<int> get_potential_set(int);

	// Helper method to remove specified potential values from a cell
	void remove_potential_values(std::set<int>, int);

	// Helper to remove potential values from a row of a sub-grid
	// assumes row_start is the leftmost cell of the row
	void remove_potential_values_from_row(std::set<int>, int);


	// Helper to remove potential values from a col of a sub-grid
	// assumes col_start is the topmost cell of the col
	void remove_potential_values_from_col(std::set<int>, int);

	// combs through sub-grids and removes potential values from them if a double or triple is found
	// sub-grid dims: s-g(0, 0) : top left, s-g(2,2) : bottom right for 9x9 sudoku
	void remove_doubles_and_triples_by_sub_grid();

	// performs unique potential on the entire board
	void find_unique_potentials();

	// Takes a cell location and then compares it with the potentials of its rows/cols/sub-grids
	// If it contains a unique potential, the cell gets filled
	void find_unique_cell_potential(int);

	// Prints out the passed in sudoku game board
	// Assumes N is either 4, 9 or 16 but can be extended to add more sizes
	void print_board();

	// Function to return integer array of cell values
	int* board_to_ints();

	bool is_legal();

	// Function to compare integer arrays of values
	bool compare_boards(int*, int*);

	// Prints a bool array that corresponds to one cell
	void print_cell(int);

	int get_empty_cell_count();

	bool is_complete();
};