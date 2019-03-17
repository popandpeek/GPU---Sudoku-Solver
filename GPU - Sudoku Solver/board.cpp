/*
** Ben Pittman
** Greg Smith
** Calvin Winston Fei
** Term Project - board.cpp
** Static class for checking solutions.
** Assumptions: Assumes valid board size and 1D memory allocation
*/

#include "board.h"

Board::Board() {
	for (int i = 0; i < BOARD_SIZE; i++) {
		board[i] = new bool[SUB_BOARD_SIZE + 1];
		for (int j = 0; j < SUB_BOARD_SIZE + 1; j++) {
			board[i][j] = false;
		}
	}
}

// Destructor to free memory allocations
Board::~Board() {
	for (int i = 0; i < BOARD_SIZE; i++) {
		free(board[i]);
	}

	delete to_pass;
	delete border;
	delete board;
}

// Functions to set the board according to passed integer array
// Marks an empty cells potential values as all true
void Board::set_board(int* filled) {
	for (int i = 0; i < BOARD_SIZE; i++) {
		if (filled[i] != 0) {
			board[i][0] = true;
			board[i][filled[i]] = true;
		}

		else {
			for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
				board[i][j] = true;
			}
			++empty_cells;
		}
	}
}

// Updates the potentials after a cell gets filled
void Board::update_potentials(int _loc, int _val) {
	if (board[_loc][0] == false) // dont do anything if cell is not filled
		return;

	int row = _loc / SUB_BOARD_SIZE;
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int row_ind = row * SUB_BOARD_SIZE + i;
		if (row_ind != _loc) {
			board[row_ind][_val] = false;
		}
	}

	int col = _loc % SUB_BOARD_SIZE;
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int col_ind = col + (SUB_BOARD_SIZE * i);
		if (col_ind != _loc) {
			board[col_ind][_val] = false;
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
				board[ind][_val] = false;
			}
		}
	}
}

// sets a cell
void Board::set_cell(int _row, int _col, int _val) {
	int board_cell = _row + _col * SUB_BOARD_SIZE;
	is_legal();
	board[board_cell][0] = true;
	for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
		if (board[board_cell][i] == true && i != _val) {
			board[board_cell][i] = false;
		}
	}
	update_potentials(board_cell, _val);
	is_legal();
	--empty_cells;
}

// sets a cell using 1d coordinates
void Board::set_cell(int _loc, int _val) {
	is_legal();
	board[_loc][0] = true;
	for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
		if (board[_loc][i] == true && i != _val) {
			board[_loc][i] = false;
		}
	}
	update_potentials(_loc, _val);
	is_legal();
	--empty_cells;
}

// method for reducing potential values for empty cells
void Board::annotate_potential_entries() {
	is_legal();

	//print_board();
	// std::cout << empty_cells << std::endl;
	for (int row = 0; row < SUB_BOARD_SIZE; row++) {
		// set to hold non-filled values in the row
		std::set<int> row_vals;

		// std::cout << row_vals.size() << std::endl;
		// remove values from set that correspond to filled cells in the row
		for (int i = row * SUB_BOARD_SIZE; i < SUB_BOARD_SIZE + (row * SUB_BOARD_SIZE); i++) {
			if (board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
					if (board[i][j] == true) {
						row_vals.insert(j);
					}
				}
			}
		}

		// std::cout << "Got to 76" << std::endl;
		// Fill cells with true where indeces correspond to values it cannot have 
		if (!row_vals.empty()) {
			for (int i = row * SUB_BOARD_SIZE; i < (row * SUB_BOARD_SIZE) + SUB_BOARD_SIZE; i++) {
				if (board[i][0] == false) {
					for (auto it = row_vals.begin(); it != row_vals.end(); ++it) {
						board[i][*it] = false;
						is_legal();
					}

					// check for single potential value and set if true
					int count = 0;
					int val = 0;
					for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
						if (board[i][j] == true) {
							val = j;
							++count;
						}
					}
					if (count == 1) {
						set_cell(i, val);
						is_legal();
					}
				}
			}
		}
	}

	// std::cout << "Got to 101" << std::endl;
	// scan col for filled in values and store in temp set
	for (int col = 0; col < SUB_BOARD_SIZE; col++) {
		std::set<int> col_vals;

		for (int i = col; i < BOARD_SIZE; i += SUB_BOARD_SIZE) {
			// std::cout << "Got to 106" << std::endl;
			if (board[i][0] == true) {
				for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
					if (board[i][j] == true) {
						col_vals.insert(j);
						break;
					}
				}
			}
		}
		// std::cout << col_vals.size() << std::endl;
		// std::cout << "Got to 118" << std::endl;
		// Fill cells with true where indeces correspond to values it cannot have 
		if (!col_vals.empty()) {
			for (int i = col; i < BOARD_SIZE; i += SUB_BOARD_SIZE) {
				if (board[i][0] == false) {
					for (auto it = col_vals.begin(); it != col_vals.end(); ++it) {
						if (board[i][*it] == true) {
							board[i][*it] = false;
							is_legal();
						}
					}

					// check for single potential value and set if true
					int count = 0;
					int val = 0;
					for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
						if (board[i][j] == true) {
							val = j;
							++count;
						}
					}
					if (count == 1) {
						set_cell(i, val);
						is_legal();
					}
				}
			}
		}
	}
	// std::cout << "Got to 144" << std::endl;
	// Reduce potentials for sub grid intersections
	for (int grid_x = 0; grid_x < SUB_BOARD_DIM; grid_x++) {
		for (int grid_y = 0; grid_y < SUB_BOARD_DIM; grid_y++) {
			std::set<int> grid_vals;
			int grid_start = grid_x * 9 * 3 + grid_y * 3;
			for (int row = 0; row < SUB_BOARD_DIM; row++) {
				for (int loc = grid_start + row * SUB_BOARD_SIZE; loc < (grid_start + row * SUB_BOARD_SIZE) + SUB_BOARD_DIM; loc++) {
					if (board[loc][0] == true) {
						for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
							if (board[loc][j] == true) {
								grid_vals.insert(j);
								break;
							}
						}
					}
				}
			}

			// std::cout << grid_vals.size() << std::endl;
			for (int row = 0; row < SUB_BOARD_DIM; row++) {
				for (int loc = grid_start + row * SUB_BOARD_SIZE; loc < (grid_start + row * SUB_BOARD_SIZE) + SUB_BOARD_DIM; loc++) {
					if (board[loc][0] == false) {
						for (auto it = grid_vals.begin(); it != grid_vals.end(); ++it) {
							if (board[loc][*it] == true) {
								board[loc][*it] = false;
								is_legal();
							}
						}

						// check for single potential value and set if true
						int count = 0;
						int val = 0;
						for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
							if (board[loc][i] == true) {
								val = i;
								++count;
							}
						}
						if (count == 1) {
							board[loc][0] = true;
							set_cell(loc, val);
							is_legal();
						}
					}
				}
			}
		}
	}
	// std::cout << empty_cells << std::endl;
}

// Helper method to get value in a cell
int Board::get_entry(int _loc) {
	int ret_val = 0;
	if (board[_loc][0] == true) {
		for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
			if (board[_loc][i] == true) {
				ret_val = i;
			}
		}
	}

	return ret_val;
}

// Helper function to get a cells potential or filled value(s)
int* Board::get_potentials(int _loc) {
	if (board[_loc][0] == false) {
		to_pass = new int[SUB_BOARD_SIZE];
		for (int i = 0; i < SUB_BOARD_SIZE; i++) {
			if (board[_loc][i] == true) {
				to_pass[i] = i;
			}

			else {
				to_pass[i] = 0;
			}
		}
	}

	return to_pass;
}

// Helper method to get potential values in an unfilled cell
std::set<int> Board::get_potential_set(int _loc) {
	std::set<int> vals;
	if (board[_loc][0] == false) {
		for (int i = 1; i < SUB_BOARD_SIZE + 1; i++) {
			if (board[_loc][i] == true) {
				vals.insert(i);
			}
		}
	}
	return vals;
}

// Helper method to remove specified potential values from a cell
void Board::remove_potential_values(std::set<int> _vals, int _loc) {
	if (board[_loc][0] == false) {
		for (auto it = _vals.begin(); it != _vals.end(); ++it) {
			board[_loc][*it] = false;
		}
	}
}

// Helper to remove potential values from a row of a sub-grid
// assumes row_start is the leftmost cell of the row
void Board::remove_potential_values_from_row(std::set<int> _vals, int row_start) {
	remove_potential_values(_vals, row_start);
	remove_potential_values(_vals, row_start + 1);
	remove_potential_values(_vals, row_start + 2);
}


// Helper to remove potential values from a col of a sub-grid
// assumes col_start is the topmost cell of the col
void Board::remove_potential_values_from_col(std::set<int> _vals, int col_start) {
	remove_potential_values(_vals, col_start);
	remove_potential_values(_vals, col_start + SUB_BOARD_SIZE);
	remove_potential_values(_vals, col_start + SUB_BOARD_SIZE * 2);
}

// combs through sub-grids and removes potential values from them if a double or triple is found
// sub-grid dims: s-g(0, 0) : top left, s-g(2,2) : bottom right for 9x9 sudoku
void Board::remove_doubles_and_triples_by_sub_grid() {
	is_legal();
	// Iterate by sub grid 
	for (int sub_grid_row = 0; sub_grid_row < SUB_BOARD_DIM; sub_grid_row++) {
		for (int sub_grid_col = 0; sub_grid_col < SUB_BOARD_DIM; sub_grid_col++) {

			// Iterate through sub-grid rows first
			int grid_start = (SUB_BOARD_DIM * SUB_BOARD_SIZE * sub_grid_row) + (SUB_BOARD_DIM * sub_grid_col);

			// For 9x9 sudoku
			if (SUB_BOARD_DIM == 3) {

				// For each row, we get the 3 potential sets for the cells
				for (int row = 0; row < SUB_BOARD_DIM; row++) {
					std::set<int>cell_1 = get_potential_set(row * SUB_BOARD_SIZE + grid_start);
					std::set<int>cell_2 = get_potential_set(row * SUB_BOARD_SIZE + grid_start + 1);
					std::set<int>cell_3 = get_potential_set(row * SUB_BOARD_SIZE + grid_start + 2);

					// check for triples
					if (cell_1.size() == 3 && cell_2.size() == 3 && cell_3.size() == 3) {
						if (cell_1 == cell_2 && cell_1 == cell_3) { // found a row triple

							// remove triple from all grid cells besides these 3
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(cell_1, SUB_BOARD_SIZE * row_remove + grid_start);
								}
							}

							continue; // If triple was found, we don't want to waste time checking for a double
						}
					}

					// check for doubles - things gonna get a bit messy
					// start with cell 1
					if (cell_1.size() == 2) {
						if (cell_1 == cell_2) { // double found
							// remove cell_3 vals and then the potential vals from other 2 rows
							remove_potential_values(cell_2, row * SUB_BOARD_SIZE + grid_start + 2);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(cell_2, SUB_BOARD_SIZE * row_remove + grid_start);
								}
							}
						}
						else if (cell_1 == cell_3) { // double found
							// remove cell_2 vals and then the potential vals from other 2 rows
							remove_potential_values(cell_2, row * SUB_BOARD_SIZE + grid_start + 1);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(cell_2, SUB_BOARD_SIZE * row_remove + grid_start);
								}
							}
						}
					} // cell 1 out of the running
					else if (cell_2.size() == 2 && cell_3.size() == 2) {
						if (cell_2 == cell_3) { // double found
							// remove cell_1 vals and then the potential vals from other 2 rows
							remove_potential_values(cell_2, row * SUB_BOARD_SIZE + grid_start);
							for (int row_remove = 0; row_remove < SUB_BOARD_DIM; row_remove++) {
								if (row_remove != row) {
									remove_potential_values_from_row(cell_2, SUB_BOARD_SIZE * row_remove + grid_start);
								}
							}
						}
					}

					// no doubles or triples found on this row
				}

				// Now we do columns
				for (int col = 0; col < SUB_BOARD_DIM; col++) {
					std::set<int>cell_1 = get_potential_set(col + grid_start);
					std::set<int>cell_2 = get_potential_set(col + grid_start + SUB_BOARD_SIZE);
					std::set<int>cell_3 = get_potential_set(col + grid_start + SUB_BOARD_SIZE * 2);

					// check for triples
					if (cell_1.size() == 3 && cell_2.size() == 3 && cell_3.size() == 3) {
						if (cell_1 == cell_2 && cell_1 == cell_3) { // found a row triple

							// remove triple from all grid cells besides these 3
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(cell_1, col_remove + grid_start);
								}
							}

							continue; // If triple was found, we don't want to waste time checking for a double
						}
					}

					// check for doubles - things gonna get a bit messy
					// start with cell 1
					if (cell_1.size() == 2) {
						if (cell_1 == cell_2) { // double found
							// remove cell_3 vals and then the potential vals from other 2 cols
							remove_potential_values(cell_2, col + grid_start + SUB_BOARD_SIZE * 2);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(cell_2, col_remove + grid_start);
								}
							}
						}
						else if (cell_1 == cell_3) { // double found
							// remove cell_2 vals and then the potential vals from other 2 rows
							remove_potential_values(cell_2, col + grid_start + SUB_BOARD_SIZE);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(cell_2, col_remove + grid_start);
								}
							}
						}
					} // cell 1 out of the running
					else if (cell_2.size() == 2 && cell_3.size() == 2) {
						if (cell_2 == cell_3) { // double found
							// remove cell_1 vals and then the potential vals from other 2 rows
							remove_potential_values(cell_2, col + grid_start);
							for (int col_remove = 0; col_remove < SUB_BOARD_DIM; col_remove++) {
								if (col_remove != col) {
									remove_potential_values_from_col(cell_2, col_remove + grid_start);
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

// performs unique potential on the entire board
void Board::find_unique_potentials() {
	for (int i = 0; i < BOARD_SIZE; i++) {
		find_unique_cell_potential(i);
	}
}

void Board::find_unique_cell_potential(int _loc) {
	is_legal();
	// do nothing if the board cell is already filled
	if (board[_loc][0] == true)
		return;

	std::set<int> pooled_potentials;
	std::set<int> selected_potentials = get_potential_set(_loc);

	// Do rows first
	int row = _loc / SUB_BOARD_SIZE;
	// pool all row cell potentials besides the selected cell
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int row_ind = row * SUB_BOARD_SIZE + i;
		if (row_ind != _loc) {
			std::set<int> cell_set = get_potential_set(row_ind);

			pooled_potentials.insert(cell_set.begin(), cell_set.end());
		}
	}

	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentials.size() > 0) {
		std::set<int> diff;
		std::set_difference(selected_potentials.begin(),
			selected_potentials.end(),
			pooled_potentials.begin(),
			pooled_potentials.end(),
			std::inserter(diff, diff.begin()));

		// only matters if we found a unique potential
		if (diff.size() == 1) {
			auto it = diff.begin();
			set_cell(_loc, *it);
			is_legal();
			// cell is set now so we're done
			return;
		}
	}

	// Do cols next
	pooled_potentials.clear();
	int col = _loc % SUB_BOARD_SIZE;
	// pool all col cell potentials besides the selected cell
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		int col_ind = col + (SUB_BOARD_SIZE * i);
		if (col_ind != _loc) {
			std::set<int> cell_set = get_potential_set(col_ind);
			pooled_potentials.insert(cell_set.begin(), cell_set.end());
		}
	}

	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentials.size() > 0) {
		std::set<int> diff;
		std::set_difference(selected_potentials.begin(),
			selected_potentials.end(),
			pooled_potentials.begin(),
			pooled_potentials.end(),
			std::inserter(diff, diff.begin()));

		// only matters if we found a unique potential
		if (diff.size() == 1) {
			auto it = diff.begin();
			set_cell(_loc, *it);
			is_legal();
			// cell is set now so we're done
			return;
		}
	}

	// Finally, do sub grids 
	pooled_potentials.clear();
	int sub_grid_x = row / SUB_BOARD_DIM; // 0, 1, or 2
	int sub_grid_y = col / SUB_BOARD_DIM; // 0, 1, or 2
	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			//		  start ind     rows of grid         col
			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
			if (ind != _loc) {
				std::set<int> cell_set = get_potential_set(ind);
				pooled_potentials.insert(cell_set.begin(), cell_set.end());
			}
		}
	}

	// If not, perform set difference of first set w.r.t. pooled set
	if (pooled_potentials.size() > 0) {
		std::set<int> diff;
		std::set_difference(selected_potentials.begin(),
			selected_potentials.end(),
			pooled_potentials.begin(),
			pooled_potentials.end(),
			std::inserter(diff, diff.begin()));

		// only matters if we found a unique potential
		if (diff.size() == 1) {
			auto it = diff.begin();
			set_cell(_loc, *it);
			is_legal();
			// cell is set now so we're done
			return;
		}
	}
}

// Prints out the sudoku game board
// Assumes N is either 4, 9 or 16 but can be extended to add more sizes
void Board::print_board() {

	if (SUB_BOARD_SIZE == 4) {
		border = new char[14]{ "|-----+-----|" };
	}
	else if (SUB_BOARD_SIZE == 9) {
		border = new char[26]{ "|-------+-------+-------|" };
	}
	else if (SUB_BOARD_SIZE == 16) {
		border = new char[42]{ "|---------+---------+---------+---------|" };
	}
	else {
		return;
	}

	std::cout << border << std::endl;
	int split = sqrt(SUB_BOARD_SIZE);
	for (int i = 0; i < BOARD_SIZE; i++) {
		if (i % SUB_BOARD_SIZE == 0) {
			std::cout << "| ";
		}
		else if (i % split == 0) {
			std::cout << "| ";
		}

		// change to call a get_entry function that will return the value
		int value = get_entry(i);
		if (value != 0) {
			std::cout << value << " ";
		}
		else {
			std::cout << ". ";
		}

		if (i % SUB_BOARD_SIZE == SUB_BOARD_SIZE - 1) {
			std::cout << "|" << std::endl;

			if (((i + 1) % (BOARD_SIZE / split)) == 0) {
				std::cout << border << std::endl;
			}
		}
	}
	std::cout << std::endl;
}

// Function to return integer array of board state
int* Board::board_to_ints() {
	if (board_to_int != nullptr) {
		delete board_to_int;
	}
		
	board_to_int = new int[BOARD_SIZE];
	for (int i = 0; i < BOARD_SIZE; i++) {
		if (board[i][0] == true) {
			for (int j = 1; j < SUB_BOARD_SIZE + 1; j++) {
				if (board[i][j] == true) {
				board_to_int[i] = j;
				}
			}
		}

		else {
			board_to_int[i] = 0;
		}
	}

	return board_to_int;
}


//bool row_check(const int* _board, int _board_root, int _row, int _entry, int loc) {
//	for (int i = _row * _board_root; i < _row * _board_root + _board_root; i++) {
//		if (i != loc && _board[i] == _entry) {
//			std::cout << "row check failed at index: " << i << " value: " << _entry << " row: " << _row  << std::endl;
//			return false;
//		}
//	}
//
//	return true;
//}
//
//bool column_check(const int* _board, int _board_root, int _col, int _entry, int loc) {
//	for (int i = _col; i < _board_root * _board_root - (_board_root - _col); i += _board_root) {
//		if (i != loc && _board[i] == _entry) {
//			std::cout << "col check failed at index: " << i << " value: " << _entry << " col: " << _col << std::endl;
//			return false;
//		}
//	}
//
//	return true;
//}
//
//bool grid_check(const int* _board, int _board_root, int _start_row, int _start_col, int _entry, int loc) {
//	int sub_grid_x = _start_row / SUB_BOARD_DIM; // 0, 1, or 2
//	int sub_grid_y = _start_col / SUB_BOARD_DIM; // 0, 1, or 2
//	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
//	for (int i = 0; i < 3; i++) {
//		for (int j = 0; j < 3; j++) {
//			//		  start ind     rows of grid         col
//			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
//			if (ind != loc && _board[ind] == _entry) {
//				std::cout << "grid check failed at index: " << ind << " value: " << _entry << " row, col: " << _start_row << ", " << _start_col << std::endl;
//				return false;
//			}
//		}
//	}
//
//	return true;
//}
//
//bool is_legal_entry(const int* _board, int _board_root, int _row, int _col, int _entry, int loc) {
//	return row_check(_board, _board_root, _row, _entry, loc) &&
//		column_check(_board, _board_root, _col, _entry, loc) &&
//		grid_check(_board, _board_root, _row, _col, _entry, loc);
//}



void print_boarder(int *board) {

	char* border = new char[26]{ "|-------+-------+-------|" };

	std::cout << border << std::endl;
	int split = sqrt(9);
	for (int i = 0; i < 9 * 9; i++) {
		if (i % 9 == 0) {
			std::cout << "| ";
		}
		else if (i % split == 0) {
			std::cout << "| ";
		}

		int value = board[i];
		if (value != 0) {
			std::cout << value << " ";
		}
		else {
			std::cout << ". ";
		}

		if (i % 9 == 9 - 1) {
			std::cout << "|" << std::endl;

			if (((i + 1) % (9 * 9 / split)) == 0) {
				std::cout << border << std::endl;
			}
		}
	}
	std::cout << std::endl;
}

bool Board::is_legal() {
	for (int i = 0; i < BOARD_SIZE; i++) {
		int* int_board = board_to_ints();
		int row = i / SUB_BOARD_SIZE;
		int col = i % SUB_BOARD_SIZE;

		if (int_board[i] != 0 ){//////////////////////&& !is_legal_entry(int_board, SUB_BOARD_SIZE, row, col, int_board[i], i)) {
			print_board();
			print_cell(i);
			throw;
		}
	}
	return true;
}


// Function to compare two integer arrays
bool Board::compare_boards(int* _one, int* _two) {
	if (_one == nullptr || _two == nullptr) {
		return false;
	}

	for (int i = 0; i < BOARD_SIZE; i++) {
		if (_one[i] != _two[i]) {
			return false;
		}
	}

	return true;
}

void Board::print_cell(int _loc) {
	std::cout << "Cell : " << _loc << std::endl;
	for (int i = 0; i < SUB_BOARD_SIZE + 1; i++) {
		std::cout << i << " : " << board[_loc][i];
		if (i < SUB_BOARD_SIZE) {
			std::cout << " | ";
		}
	}
	std::cout << std::endl;
}

int Board::get_empty_cell_count() {
	return empty_cells;
}

bool Board::is_complete() {
	if (this->get_empty_cell_count() == 0)
		return true;
	else
		return false;
}