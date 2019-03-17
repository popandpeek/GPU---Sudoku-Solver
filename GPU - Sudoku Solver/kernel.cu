
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <set>
#include "board.h"
#include <chrono>
#include <string>

// Function to return integer array of board state
__device__ int* board_to_ints(Board * _board)
{
	if (_board->board_to_int != nullptr) {
		delete _board->board_to_int;
	}

	_board->board_to_int = new int[BOARD_SIZE];
	for (int i = 0; i < BOARD_SIZE; i++) {
		if (_board->board[i][0] == true) {
			for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
				if (_board->board[i][j] == true) {
					_board->board_to_int[i] = j;
				}
			}
		}

		else {
			_board->board_to_int[i] = 0;
		}
	}

	return _board->board_to_int;
}

__device__ bool row_check(const int* _board, int _board_root, int _row, int _entry, int loc) 
{
	for (int i = _row * _board_root; i < _row * _board_root + _board_root; i++) {
		if (i != loc && _board[i] == _entry) 
		{
			return false;
		}
	}

	return true;
}

__device__ bool column_check(const int* _board, int _board_root, int _col, int _entry, int loc) 
{
	for (int i = _col; i < _board_root * _board_root - (_board_root - _col); i += _board_root) {
		if (i != loc && _board[i] == _entry) {
			return false;
		}
	}

	return true;
}

__device__ bool grid_check(const int* _board, int _board_root, int _start_row, int _start_col, int _entry, int loc)
{
	int sub_grid_x = _start_row / SUB_BOARD_DIM; // 0, 1, or 2
	int sub_grid_y = _start_col / SUB_BOARD_DIM; // 0, 1, or 2
	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			//		  start ind     rows of grid         col
			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
			if (ind != loc && _board[ind] == _entry) {
				return false;
			}
		}
	}

	return true;
}

__device__ bool is_legal_entry(const int* _board, int _board_root, int _row, int _col, int _entry, int loc) 
{
	return row_check(_board, _board_root, _row, _entry, loc) &&
		column_check(_board, _board_root, _col, _entry, loc) &&
		grid_check(_board, _board_root, _row, _col, _entry, loc);
}

__device__ bool is_legal(Board * _board)
{
	for (int i = 0; i < BOARD_SIZE; i++)
	{
		int* int_board = board_to_ints(_board);
		int row = i / SUB_BOARD_SIZE;
		int col = i % SUB_BOARD_SIZE;

		if (int_board[i] != 0 && !is_legal_entry(int_board, SUB_BOARD_SIZE, row, col, int_board[i], i)) 
		{
			//print_board();
			//print_cell(i);
			//throw;
			return false;
		}
	}
	return true;
}

__device__ void update_potentials(Board * _board, int _loc, int _val)
{
	if (_board->board[_loc][0] == false) // dont do anything if cell is not filled
		return;

	int row = _loc / SUB_BOARD_SIZE;
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int row_ind = row * SUB_BOARD_SIZE + i;
		if (row_ind != _loc) {
			_board->board[row_ind][_val] = false;
		}
	}

	int col = _loc % SUB_BOARD_SIZE;
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int col_ind = col + (SUB_BOARD_SIZE * i);
		if (col_ind != _loc) {
			_board->board[col_ind][_val] = false;
		}
	}

	int sub_grid_x = row / SUB_BOARD_DIM; // 0, 1, or 2
	int sub_grid_y = col / SUB_BOARD_DIM; // 0, 1, or 2
	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			//		  start ind     rows of grid         col
			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
			if (ind != _loc) {
				_board->board[ind][_val] = false;
			}
		}
	}
}

// sets a cell using 1d coordinates
__device__ void set_cell(Board * _board, int _loc, int _val) {
	is_legal(_board);
	_board->board[_loc][0] = true;
	for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
		if (_board->board[_loc][i] == true && i != _val) {
			_board->board[_loc][i] = false;
		}
	}
	update_potentials(_board, _loc, _val);
	is_legal(_board);
	--_board->empty_cells;
}

//sets a cell
__device__ void set_cell(Board * _board, int _row, int _col, int _val)
{
	int board_cell = _row + _col * SUB_BOARD_SIZE;
	is_legal(_board);
	_board->board[board_cell][0] = true;
	for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
		if (_board->board[board_cell][i] == true && i != _val) {
			_board->board[board_cell][i] = false;
		}
	}
	update_potentials(_board, board_cell, _val);
	is_legal(_board);
	--_board->empty_cells;
}

__device__ int* get_potentials(Board * _board, int _loc) {
	if (_board->board[_loc][0] == false) {
		_board->to_pass = new int[SUB_BOARD_SIZE];
		for (int i = 0; i < SUB_BOARD_SIZE; i++) {
			if (_board->board[_loc][i] == true) {
				_board->to_pass[i] = i;
			}

			else {
				_board->to_pass[i] = 0;
			}
		}
	}

	return _board->to_pass;
}

// Helper method to get potential values in an unfilled cell
__device__ int * get_potential_set(Board * _board, int _loc, int &count) 
{
	count = 0;
	//Get count
	if (_board->board[_loc][0] == false) {
		for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
			if (_board->board[_loc][i] == true) 
			{
				count++;
			}
		}
	}
	//Get values
	int *vals = new int[count];
	count = 0;
	if (_board->board[_loc][0] == false) {
		for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
			if (_board->board[_loc][i] == true)
			{
				vals[count] = i; //Made need to reorder small -> largest if problems seen //////////////////////////////////////////////////////////////////
				count++;
			}
		}
	}
	return vals;
}

__device__ void annotate_potential_entries(Board * _board)
{
	is_legal(_board);

	//print_board();
	// std::cout << empty_cells << std::endl;
	for (int row = 0; row < SUB_BOARD_SIZE; row++) {
		// set to hold non-filled values in the row
		int * row_vals;
		int row_valsCount = 0;

		// std::cout << row_vals.size() << std::endl;
		// remove values from set that correspond to filled cells in the row
		for (int i = row * SUB_BOARD_SIZE; i < SUB_BOARD_SIZE + (row * SUB_BOARD_SIZE); i++) 
		{
			if (_board->board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) 
				{
					if (_board->board[i][j] == true) 
					{
						row_valsCount++;
					}
				}
			}
		}
		row_vals = new int[row_valsCount];
		row_valsCount = 0;
		for (int i = row * SUB_BOARD_SIZE; i < SUB_BOARD_SIZE + (row * SUB_BOARD_SIZE); i++)
		{
			if (_board->board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++)
				{
					if (_board->board[i][j] == true)
					{

						row_vals[row_valsCount] = j;
						row_valsCount++;
					}
				}
			}
		}

		// std::cout << "Got to 76" << std::endl;
		// Fill cells with true where indeces correspond to values it cannot have 
		if (row_valsCount > 0)
		{
			for (int i = row * SUB_BOARD_SIZE; i < (row * SUB_BOARD_SIZE) + SUB_BOARD_SIZE; i++) {
				if (_board->board[i][0] == false) 
				{
					for (int rowValue = 0; rowValue < row_valsCount -1; ++rowValue) ///////////////////////////////////////row_valsCount -1?
					{
						_board->board[i][row_vals[rowValue]] = false;
						is_legal(_board);
					}

					// check for single potential value and set if true
					int count = 0;
					int val = 0;
					for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
						if (_board->board[i][j] == true) {
							val = j;
							++count;
						}
					}
					if (count == 1) {
						set_cell(_board, i, val);
						is_legal(_board);
					}
				}
			}
		}
	}

	// std::cout << "Got to 101" << std::endl;
	// scan col for filled in values and store in temp set
	for (int col = 0; col < SUB_BOARD_SIZE; col++) 
	{
		int * col_vals;
		int col_valsCount = 0;
		for (int i = col; i < BOARD_SIZE; i += SUB_BOARD_SIZE) {
			// std::cout << "Got to 106" << std::endl;
			if (_board->board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
					if (_board->board[i][j] == true) 
					{
						col_valsCount++;
						break;
					}
				}
			}
		}
		col_vals = new int[col_valsCount];
		col_valsCount = 0;
		for (int i = col; i < BOARD_SIZE; i += SUB_BOARD_SIZE) {
			// std::cout << "Got to 106" << std::endl;
			if (_board->board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
					if (_board->board[i][j] == true)
					{
						col_vals[col_valsCount] = j;
						col_valsCount++;
						break;
					}
				}
			}
		}
		// std::cout << col_vals.size() << std::endl;
		// std::cout << "Got to 118" << std::endl;
		// Fill cells with true where indeces correspond to values it cannot have 
		if (col_valsCount > 0) 
		{
			for (int i = col; i < BOARD_SIZE; i += SUB_BOARD_SIZE) {
				if (_board->board[i][0] == false) 
				{
					for (int colsValue = 0; colsValue < col_valsCount -1; ++colsValue) ///////////////////////////////////////////////colsvalCount -1 ?
					{
						if (_board->board[i][col_vals[colsValue]] == true) {
							_board->board[i][col_vals[colsValue]] = false;
							is_legal(_board);
						}
					}

					// check for single potential value and set if true
					int count = 0;
					int val = 0;
					for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
						if (_board->board[i][j] == true) {
							val = j;
							++count;
						}
					}
					if (count == 1) {
						set_cell(_board, i, val);
						is_legal(_board);
					}
				}
			}
		}
	}
	// std::cout << "Got to 144" << std::endl;
	// Reduce potentials for sub grid intersections
	for (int grid_x = 0; grid_x < SUB_BOARD_DIM; grid_x++) {
		for (int grid_y = 0; grid_y < SUB_BOARD_DIM; grid_y++) 
		{
			int* grid_vals;
			int grid_valsCount = 0;
			int grid_start = grid_x * 9 * 3 + grid_y * 3;
			for (int row = 0; row < SUB_BOARD_DIM; row++) {
				for (int loc = grid_start + row * SUB_BOARD_SIZE; loc < (grid_start + row * SUB_BOARD_SIZE) + SUB_BOARD_DIM; loc++) {
					if (_board->board[loc][0] == true) {
						for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
							if (_board->board[loc][j] == true) 
							{
								grid_valsCount++;
								break;
							}
						}
					}
				}
			}
			grid_vals = new int[grid_valsCount];
			grid_valsCount = 0;
			grid_start = grid_x * 9 * 3 + grid_y * 3;
			for (int row = 0; row < SUB_BOARD_DIM; row++) {
				for (int loc = grid_start + row * SUB_BOARD_SIZE; loc < (grid_start + row * SUB_BOARD_SIZE) + SUB_BOARD_DIM; loc++) {
					if (_board->board[loc][0] == true) {
						for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
							if (_board->board[loc][j] == true)
							{
								grid_vals[grid_valsCount] = j;
								grid_valsCount++;
								break;
							}
						}
					}
				}
			}

			// std::cout << grid_vals.size() << std::endl;
			for (int row = 0; row < SUB_BOARD_DIM; row++) {
				for (int loc = grid_start + row * SUB_BOARD_SIZE; loc < (grid_start + row * SUB_BOARD_SIZE) + SUB_BOARD_DIM; loc++) {
					if (_board->board[loc][0] == false) 
					{
						for (int gridVal = 0; gridVal < grid_valsCount -1; ++gridVal) /////////////////////////////////////////////////////////////// grid_valsCount -1?
						{
							if (_board->board[loc][grid_vals[gridVal]] == true) {
								_board->board[loc][grid_vals[gridVal]] = false;
								is_legal(_board);
							}
						}

						// check for single potential value and set if true
						int count = 0;
						int val = 0;
						for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
							if (_board->board[loc][i] == true) {
								val = i;
								++count;
							}
						}
						if (count == 1) {
							_board->board[loc][0] = true;
							set_cell(_board, loc, val);
							is_legal(_board);
						}
					}
				}
			}
		}
	}
	// std::cout << empty_cells << std::endl;
}

__device__ void remove_potential_values(Board * _board, int* _vals, int _loc, int valCount) 
{
	if (_board->board[_loc][0] == false) 
	{
		for (int i = 0; i < valCount - 1; ++i) ////////////////////////////////////////////////valCount - 1? ////////////////////////////////////
		{
			_board->board[_loc][_vals[i]] = false;
		}
	}
}

// Helper to remove potential values from a row of a sub-grid assumes row_start is the leftmost cell of the row
__device__ void remove_potential_values_from_row(Board* _board, int* _vals, int row_start, int valCount) 
{
	remove_potential_values(_board, _vals, row_start, valCount);
	remove_potential_values(_board, _vals, row_start + 1, valCount);
	remove_potential_values(_board, _vals, row_start + 2, valCount);
}

// Helper to remove potential values from a col of a sub-grid assumes col_start is the topmost cell of the col
__device__ void remove_potential_values_from_col(Board* _board, int* _vals, int col_start, int valCount) {
	remove_potential_values(_board, _vals, col_start, valCount);
	remove_potential_values(_board, _vals, col_start + SUB_BOARD_SIZE, valCount);
	remove_potential_values(_board, _vals, col_start + SUB_BOARD_SIZE * 2, valCount);
}

// Helper method to remove specified potential values from a cell

__device__ void remove_doubles_and_triples_by_sub_grid(Board * _board)
{
	is_legal(_board);
	// Iterate by sub grid 
	for (int sub_grid_row = 0; sub_grid_row < SUB_BOARD_DIM; sub_grid_row++) {
		for (int sub_grid_col = 0; sub_grid_col < SUB_BOARD_DIM; sub_grid_col++) {

			// Iterate through sub-grid rows first
			int grid_start = (SUB_BOARD_DIM * SUB_BOARD_SIZE * sub_grid_row) + (SUB_BOARD_DIM * sub_grid_col);

			// For 9x9 sudoku
			if (SUB_BOARD_DIM == 3) {

				// For each row, we get the 3 potential sets for the cells
				for (int row = 0; row < SUB_BOARD_DIM; row++) 
				{
					int cell1Count = 0;
					int *cell_1 = get_potential_set(_board, row * SUB_BOARD_SIZE + grid_start, cell1Count);
					int cell2Count = 0;
					int *cell_2 = get_potential_set(_board, row * SUB_BOARD_SIZE + grid_start + 1, cell2Count);
					int cell3Count = 0;
					int *cell_3 = get_potential_set(_board, row * SUB_BOARD_SIZE + grid_start + 2, cell2Count);

					// check for triples
					if (cell1Count == 3 && cell2Count == 3 && cell3Count == 3)
					{
						//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Potential problem area. Had to change cell_x to int*
						bool tripleFound = true;
						if (cell1Count == cell2Count && cell1Count == cell3Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_2[count] || cell_1[count] != cell_3[count])
								{
									tripleFound = false;
								}
							}
						}
						else
						{
							tripleFound = false;
						}

						if (tripleFound)
						{ // found a row triple

							// remove triple from all grid cells besides these 3
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) 
								{
									remove_potential_values_from_row(_board, cell_1, SUB_BOARD_SIZE * row_remove + grid_start, cell1Count);
								}
							}

							continue; // If triple was found, we don't want to waste time checking for a double
						}
					}

					// check for doubles - things gonna get a bit messy
					// start with cell 1
					if (cell1Count == 2)
					{
						bool doubleFoundC1C2 = true;
						if (cell1Count == cell2Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_2[count])
								{
									doubleFoundC1C2 = false;
								}
							}
						}
						else
						{
							doubleFoundC1C2 = false;
						}

						bool doubleFoundC1C3 = true;
						if (cell1Count == cell3Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_3[count])
								{
									doubleFoundC1C3 = false;
								}
							}
						}
						else
						{
							doubleFoundC1C3 = false;
						}

						if (doubleFoundC1C2)
						{ // double found
							// remove cell_3 vals and then the potential vals from other 2 rows
							remove_potential_values(_board, cell_2, row * SUB_BOARD_SIZE + grid_start + 2, cell2Count);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(_board, cell_2, SUB_BOARD_SIZE * row_remove + grid_start, cell2Count);
								}
							}
						}
						else if (doubleFoundC1C3) 
						{ // double found
							// remove cell_2 vals and then the potential vals from other 2 rows
							remove_potential_values(_board, cell_2, row * SUB_BOARD_SIZE + grid_start + 1, cell2Count);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(_board, cell_2, SUB_BOARD_SIZE * row_remove + grid_start, cell2Count);
								}
							}
						}
					} // cell 1 out of the running
					else if (cell2Count == 2 && cell3Count == 2)
					{
						bool doubleFoundC2C3 = true;
						if (cell2Count == cell3Count)
						{
							for (int count = 0; count < cell2Count; count++)
							{
								if (cell_2[count] != cell_3[count])
								{
									doubleFoundC2C3 = false;
								}
							}
						}
						else
						{
							doubleFoundC2C3 = false;
						}

						if (doubleFoundC2C3)
						{ // double found
							// remove cell_1 vals and then the potential vals from other 2 rows
							remove_potential_values(_board, cell_2, row * SUB_BOARD_SIZE + grid_start, cell2Count);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(_board, cell_2, SUB_BOARD_SIZE * row_remove + grid_start, cell2Count);
								}
							}
						}
					}

					// no doubles or triples found on this row
				}

				// Now we do columns
				for (int col = 0; col < SUB_BOARD_DIM; col++) 
				{
					int cell1Count = 0;
					int*cell_1 = get_potential_set(_board, col + grid_start, cell1Count);
					int cell2Count = 0;
					int*cell_2 = get_potential_set(_board, col + grid_start + SUB_BOARD_SIZE, cell2Count);
					int cell3Count = 0;
					int*cell_3 = get_potential_set(_board, col + grid_start + SUB_BOARD_SIZE * 2, cell3Count);

					// check for triples
					if (cell1Count == 3 && cell2Count == 3 && cell3Count == 3) 
					{

						bool tripleFound = true;
						if (cell1Count == cell2Count && cell1Count == cell3Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_2[count] || cell_1[count] != cell_3[count])
								{
									tripleFound = false;
								}
							}
						}
						else
						{
							tripleFound = false;
						}


						if (tripleFound) { // found a row triple

							// remove triple from all grid cells besides these 3
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) 
							{
								if (col_remove != col) {
									remove_potential_values_from_col(_board, cell_1, col_remove + grid_start, cell1Count);
								}
							}

							continue; // If triple was found, we don't want to waste time checking for a double
						}
					}

					// check for doubles - things gonna get a bit messy
					// start with cell 1
					if (cell1Count == 2) 
					{

						bool doubleFoundC1C2 = true;
						if (cell1Count == cell2Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_2[count])
								{
									doubleFoundC1C2 = false;
								}
							}
						}
						else
						{
							doubleFoundC1C2 = false;
						}

						bool doubleFoundC1C3 = true;
						if (cell1Count == cell3Count)
						{
							for (int count = 0; count < cell1Count; count++)
							{
								if (cell_1[count] != cell_3[count])
								{
									doubleFoundC1C3 = false;
								}
							}
						}
						else
						{
							doubleFoundC1C3 = false;
						}


						if (doubleFoundC1C2) 
						{ // double found
							// remove cell_3 vals and then the potential vals from other 2 cols
							remove_potential_values(_board, cell_2, col + grid_start + SUB_BOARD_SIZE * 2, cell2Count);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(_board, cell_2, col_remove + grid_start, cell2Count);
								}
							}
						}
						else if (doubleFoundC1C3) 
						{ // double found
							// remove cell_2 vals and then the potential vals from other 2 rows
							remove_potential_values(_board, cell_2, col + grid_start + SUB_BOARD_SIZE, cell2Count);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(_board, cell_2, col_remove + grid_start, cell2Count);
								}
							}
						}
					} // cell 1 out of the running
					else if (cell2Count == 2 && cell3Count == 2) 
					{
						bool doubleFoundC2C3 = true;
						if (cell2Count == cell3Count)
						{
							for (int count = 0; count < cell2Count; count++)
							{
								if (cell_2[count] != cell_3[count])
								{
									doubleFoundC2C3 = false;
								}
							}
						}
						else
						{
							doubleFoundC2C3 = false;
						}

						if (doubleFoundC2C3) 
						{ // double found
							// remove cell_1 vals and then the potential vals from other 2 rows
							remove_potential_values(_board, cell_2, col + grid_start, cell2Count);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(_board, cell_2, col_remove + grid_start, cell2Count);
								}
							}
						}
					}

					// no doubles or triples found on this col
				}
			}
			else {
				// TODO: Any other sudoku dimensions.
				//  e.g. 16x16 sudoku which will need to check for quadruples as well.
			}
		}
	}
}

__device__ void find_unique_cell_potential(Board * _board, int _loc)
{
	is_legal(_board);
	// do nothing if the board cell is already filled
	if (_board->board[_loc][0] == true)
		return;

	int pooled_potentialsCount = 0;
	int * pooled_potentials;
	int selected_potentialsCount = 0;
	int * selected_potentials = get_potential_set(_board, _loc, selected_potentialsCount);

	// Do rows first
	int row = _loc / SUB_BOARD_SIZE;
	// pool all row cell potentials besides the selected cell
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int row_ind = row * SUB_BOARD_SIZE + i;
		if (row_ind != _loc) 
		{
			int cell_setCount = 0;
			int* cell_set = get_potential_set(_board, row_ind, cell_setCount);

			pooled_potentialsCount = cell_setCount;
			pooled_potentials = new int[pooled_potentialsCount];
			for (int j = 0; j < pooled_potentialsCount; j++)
			{
				pooled_potentials[j] = cell_set[j];
			}			
		}
	}

	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentialsCount > 0) 
	{
		//Need to find first number in selected not found
		int diff = 0;
		int diffCount = 0;
		for (int i = 0; i < selected_potentialsCount; i++)
		{
			bool found = false;
			for (int j = 0; j < pooled_potentialsCount; j++)
			{
				if (selected_potentials[i] == pooled_potentials[j])
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				diff = selected_potentials[i];
				diffCount++;
			}
		}

		// only matters if we found a unique potential
		if (diffCount == 1)
		{
			set_cell(_board, _loc, diff);
			is_legal(_board);
			// cell is set now so we're done
			return;
		}
	}

	// Do cols next
	delete[] pooled_potentials;
	pooled_potentialsCount = 0;
	int col = _loc % SUB_BOARD_SIZE;
	// pool all col cell potentials besides the selected cell
	for (int i = 0; i < SUB_BOARD_SIZE; i++) 
	{
		int col_ind = col + (SUB_BOARD_SIZE * i);
		if (col_ind != _loc)
		{
			int cell_setCount = 0;
			int* cell_set = get_potential_set(_board, col_ind, cell_setCount);
			pooled_potentialsCount = cell_setCount;
			pooled_potentials = new int[pooled_potentialsCount];
			for (int j = 0; j < pooled_potentialsCount; j++)
			{
				pooled_potentials[j] = cell_set[j];
			}
		}
	}

	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentialsCount > 0) 
	{
		//Need to find first number in selected not found
		int diff = 0;
		int diffCount = 0;
		for (int i = 0; i < selected_potentialsCount; i++)
		{
			bool found = false;
			for (int j = 0; j < pooled_potentialsCount; j++)
			{
				if (selected_potentials[i] == pooled_potentials[j])
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				diff = selected_potentials[i];
				diffCount++;
			}
		}

		// only matters if we found a unique potential
		if (diffCount == 1)
		{
			set_cell(_board, _loc, diff);
			is_legal(_board);
			// cell is set now so we're done
			return;
		}

	}

	// Finally, do sub grids 
	delete[] pooled_potentials;
	pooled_potentialsCount = 0;
	int sub_grid_x = row / SUB_BOARD_DIM; // 0, 1, or 2
	int sub_grid_y = col / SUB_BOARD_DIM; // 0, 1, or 2
	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			//		  start ind     rows of grid         col
			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
			if (ind != _loc) 
			{
				int cell_setCount = 0;
				int* cell_set = get_potential_set(_board, ind, cell_setCount);
				pooled_potentialsCount = cell_setCount;
				pooled_potentials = new int[pooled_potentialsCount];
				for (int j = 0; j < pooled_potentialsCount; j++)
				{
					pooled_potentials[j] = cell_set[j];
				}
			}
		}
	}
	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentialsCount > 0)
	{
		//Need to find first number in selected not found
		int diff = 0;
		int diffCount = 0;
		for (int i = 0; i < selected_potentialsCount; i++)
		{
			bool found = false;
			for (int j = 0; j < pooled_potentialsCount; j++)
			{
				if (selected_potentials[i] == pooled_potentials[j])
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				diff = selected_potentials[i];
				diffCount++;
			}
		}

		// only matters if we found a unique potential
		if (diffCount == 1)
		{
			set_cell(_board, _loc, diff);
			is_legal(_board);
			// cell is set now so we're done
			return;
		}

	}
}

// performs unique potential on the entire board
__device__ void find_unique_potentials(Board * _board) 
{
	for (int i = 0; i < BOARD_SIZE; i++) 
	{
		find_unique_cell_potential(_board, i);
	}
}

__global__ void SudukoSolver(Board * _board)
{
	annotate_potential_entries(_board);
	remove_doubles_and_triples_by_sub_grid(_board);
	find_unique_potentials(_board);
}


#pragma region Boards
/*Boards*/
// https://www.puzzles.ca/sudoku_puzzles/sudoku_easy_487.html
int* test_board_easy = new int[81]{ 0, 7, 0, 0, 0, 1, 0, 0, 0,
									6, 0, 0, 0, 0, 0, 0, 0, 0,
									0, 0, 0, 0, 5, 3, 0, 0, 0,
									0, 0, 0, 8, 0, 0, 0, 2, 0,
									0, 3, 0, 0, 4, 7, 1, 6, 0,
									4, 0, 0, 0, 0, 0, 5, 7, 0,
									0, 0, 0, 0, 1, 0, 7, 5, 0,
									0, 6, 0, 5, 2, 0, 0, 4, 0,
									3, 0, 0, 0, 0, 9, 0, 8, 6 };

int* easy_test_answer = new int[81]{ 5, 7, 9, 6, 8, 1, 4, 3, 2,
									6, 2, 3, 7, 9, 4, 8, 1, 5,
									1, 8, 4, 2, 5, 3, 6, 9, 7,
									7, 1, 6, 8, 3, 5, 9, 2, 4,
									2, 3, 5, 9, 4, 7, 1, 6, 8,
									4, 9, 8, 1, 6, 2, 5, 7, 3,
									8, 4, 2, 3, 1, 6, 7, 5, 9,
									9, 6, 7, 5, 2, 8, 3, 4, 1,
									3, 5, 1, 4, 7, 9, 2, 8, 6 };

int* test_board_easy2 = new int[81]{ 0, 0, 0, 0, 9, 0, 0, 0, 0,
									  0, 3, 0, 0, 0, 0, 7, 4, 2,
									  6, 1, 0, 0, 3, 0, 0, 0, 0,
									  0, 0, 8, 0, 0, 0, 0, 0, 0,
									  0, 2, 9, 1, 4, 7, 0, 0, 8,
									  4, 5, 0, 0, 0, 0, 0, 7, 0,
									  0, 4, 0, 0, 0, 0, 0, 6, 0,
									  5, 0, 0, 6, 0, 0, 0, 3, 0,
									  0, 0, 0, 0, 8, 1, 2, 0, 0 };

int* easy_test2_answer = new int[81]{ 2, 8, 4, 7, 9, 5, 3, 1, 6,
									   9, 3, 5, 8, 1, 6, 7, 4, 2,
									   6, 1, 7, 2, 3, 4, 5, 8, 9,
									   1, 7, 8, 5, 6, 9, 4, 2, 3,
									   3, 2, 9, 1, 4, 7, 6, 5, 8,
									   4, 5, 6, 3, 2, 8, 9, 7, 1,
									   8, 4, 2, 9, 5, 3, 1, 6, 7,
									   5, 9, 1, 6, 7, 2, 8, 3, 4,
									   7, 6, 3, 4, 8, 1, 2, 9, 5 };

// https://www.puzzles.ca/sudoku_puzzles/sudoku_medium_487.html
int* test_board_medium = new int[81]{ 0, 0, 0, 0, 0, 0, 3, 0, 0,
									   8, 5, 2, 3, 0, 0, 0, 0, 1,
									   0, 9, 0, 2, 0, 0, 0, 0, 4,
									   9, 7, 4, 0, 0, 0, 0, 0, 0,
									   0, 1, 0, 0, 6, 0, 0, 0, 0,
									   0, 0, 0, 0, 4, 0, 0, 0, 0,
									   6, 0, 9, 0, 8, 0, 0, 3, 7,
									   3, 0, 0, 0, 0, 0, 0, 6, 0,
									   0, 2, 0, 0, 0, 5, 0, 0, 0 };

int* medium_test_answer = new int[81]{ 4, 6, 7, 9, 1, 8, 3, 2, 5,
										8, 5, 2, 3, 7, 4, 6 ,9, 1,
										1, 9, 3, 2, 5, 6, 7, 8, 4,
										9, 7, 4, 5, 2, 3, 8, 1, 6,
										2, 1, 8, 7, 6, 9, 4, 5, 3,
										5, 3, 6, 8, 4, 1, 2, 7, 9,
										6, 4, 9, 1, 8, 2, 5, 3, 7,
										3, 8, 5, 4, 9, 7, 1, 6, 2,
										7, 2, 1, 6, 3, 5, 9, 4, 8 };


// https://www.puzzles.ca/sudoku_puzzles/sudoku_medium_487.html
int* test_board_hard = new int[81]{ 0, 7, 0, 5, 0, 6, 0, 0, 0,
									 4, 0, 3, 0, 0, 0, 0, 0, 1,
									 0, 6, 0, 0, 0, 0, 9, 0, 7,
									 0, 0, 0, 7, 3, 0, 8, 2, 0,
									 8, 0, 4, 0, 5, 0, 0, 7, 3,
									 0, 9, 0, 0, 2, 0, 0, 0, 5,
									 0, 0, 1, 0, 0, 0, 0, 0, 0,
									 0, 0, 0, 1, 0, 0, 2, 0, 6,
									 0, 0, 0, 3, 8, 2, 0, 0, 0 };

//int* hard_test_answer = new int[81]{    4, 6, 7, 9, 1, 8, 3, 2, 5,
//										8, 5, 2, 3, 7, 4, 6 ,9, 1,
//										1, 9, 3, 2, 5, 6, 7, 8, 4,
//										9, 7, 4, 5, 2, 3, 8, 1, 6,
//										2, 1, 8, 7, 6, 9, 4, 5, 3,
//										5, 3, 6, 8, 4, 1, 2, 7, 9,
//										6, 4, 9, 1, 8, 2, 5, 3, 7,
//										3, 8, 5, 4, 9, 7, 1, 6, 2,
//										7, 2, 1, 6, 3, 5, 9, 4, 8 };

// http://www.ams.org/notices/200904/rtx090400460p.pdf
int* test_board_diabolical = new int[81]{ 0, 9, 0, 7, 0, 0, 8, 6, 0,
										  0, 3, 1, 0, 0, 5, 0, 2, 0,
										  8, 0, 6, 0, 0, 0, 0, 0, 0,
										  0, 0, 7, 0, 5, 0, 0, 0, 6,
										  0, 0, 0, 3, 0, 7, 0, 0, 0,
										  5, 0, 0, 0, 1, 0, 7, 0, 0,
										  0, 0, 0, 0, 0, 0, 1, 0, 9,
										  0, 2, 0, 6, 0, 0, 3, 5, 0,
										  0, 5, 4, 0, 0, 8, 0, 7, 0 };

int* diabolical_test_answer = new int[81]{ 2, 9, 5, 7, 4, 3, 8, 6, 1,
										   4, 3, 1, 8, 6, 5, 9, 2, 7,
										   8, 7, 6, 1, 9, 2, 5, 4, 3,
										   3, 8, 7, 4, 5, 9, 2, 1, 6,
										   6, 1, 2, 3, 8, 7, 4, 9, 5,
										   5, 4, 9, 2, 1, 6, 7, 3, 8,
										   7, 6, 3, 5, 2, 4, 1, 8, 9,
										   9, 2, 8, 6, 7, 1, 3, 5, 4,
										   1, 5, 4, 9, 3, 8, 6, 7, 2 };

#pragma endregion


Board *SetBoard()
{
	Board *board = new Board();
	board->set_board(test_board_easy);
	board->print_board();
	return board;
}

//Print timing of gpu memory and op timing as well as just op timing
void PrintTiming(float _opTime, float _memAndOpTime)
{
	std::cout << "\tMemory and Operation time: " << _memAndOpTime << " milliseconds." << std::endl;
	std::cout << "\tOperation time: " << _opTime << " milliseconds.\n" << std::endl;
}

void SolvePuzzle(Board *_board)
{
	cudaEvent_t startMem, stopMem, startOp, stopOp;
	cudaEventCreate(&startMem);
	cudaEventCreate(&stopMem);
	cudaEventCreate(&startOp);
	cudaEventCreate(&stopOp);

	Board *device_board;
	int memorySize = BOARD_SIZE * sizeof(Board);

	cudaError_t cudaStatus;

	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
	}

	cudaStatus = cudaMalloc((void **)&device_board, memorySize);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
	}



	int loop_count_easy = 0;
	//while (_board->is_complete() == false)
	//{

		// start memory + solver timing
		cudaEventRecord(startMem);

		cudaStatus = cudaMemcpy(device_board, _board, memorySize, cudaMemcpyHostToDevice);
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaMemcpy failed!");
		}

		//Start timing math only
		cudaEventRecord(startOp);

		//Call Kernel
		SudukoSolver << <1, 1 >> > (device_board);

		cudaStatus = cudaGetLastError();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		}

		//Stop puzzle only timing
		cudaEventRecord(stopOp);

		// Copy result back to host
		cudaMemcpy(_board, device_board, memorySize, cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaMemcpy failed!\n\n");
		}


		//Stop memory timing: sync must go here or it loses these timing events
		cudaEventRecord(stopMem);
		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus != cudaSuccess) 
		{
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching SudukoSolver!\n\n", cudaStatus);
		}


		float millisecondsOp = 0;
		float millisecondsMem = 0;
		cudaEventElapsedTime(&millisecondsOp, startOp, stopOp);
		cudaEventElapsedTime(&millisecondsMem, startMem, stopMem);

		//Print Timings
		PrintTiming(millisecondsOp, millisecondsMem);

	//	if (loop_count_easy++ > 15) {
	//		break;
	//	}

	//}
}

int main()
{
	// Instantiates, Sets, and Prints out the initial game board
	Board *easy_sudoku = SetBoard();
	int loop_count_easy = 0;

	SolvePuzzle(easy_sudoku);

	easy_sudoku->print_board();

	//std::cout << "Loops: " << loop_count_easy << " | Empty Cells: ";
	//std::cout << easy_sudoku->empty_cells << std::endl;



	/*while (easy_sudoku->is_complete() == false) 
	{
		easy_sudoku->annotate_potential_entries();
		easy_sudoku->remove_doubles_and_triples_by_sub_grid();
		easy_sudoku->find_unique_potentials();
		std::cout << "Loops: " << ++loop_count_easy << " | Empty Cells: ";
		std::cout << easy_sudoku->empty_cells << std::endl;
		if (loop_count_easy > 15) {
			break;
		}
	}


	std::cout << "Easy Board is correct: " << easy_sudoku->is_legal() << std::endl;*/
	//easy_sudoku->print_board();


}
