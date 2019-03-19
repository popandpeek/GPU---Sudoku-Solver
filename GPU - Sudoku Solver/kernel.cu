
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>

#include <stdio.h>

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <set>
#include <chrono>
#include <string>


#define BOARD_SIZE 81
#define SUB_BOARD_SIZE 9
#define SUB_BOARD_DIM 3

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


__device__ bool row_check_dev(const int* _board, int _board_root, int _row, int _entry, int loc)
{
	for (int i = _row * _board_root; i < _row * _board_root + _board_root; i++) {
		if (i != loc && _board[i] == _entry)
		{
			return false;
		}
	}

	return true;
}

__device__ bool column_check_dev(const int* _board, int _board_root, int _col, int _entry, int loc)
{
	for (int i = _col; i < _board_root * _board_root - (_board_root - _col); i += _board_root) {
		if (i != loc && _board[i] == _entry) {
			return false;
		}
	}

	return true;
}

__device__ bool grid_check_dev(const int* _board, int _board_root, int _start_row, int _start_col, int _entry, int loc)
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

__device__ bool is_legal_entry_dev(const int* _board, int _board_root, int _row, int _col, int _entry, int loc)
{
	return row_check_dev(_board, _board_root, _row, _entry, loc) &&
		column_check_dev(_board, _board_root, _col, _entry, loc) &&
		grid_check_dev(_board, _board_root, _row, _col, _entry, loc);
}

// Returns whether or not it is valid to put a value in specified location for this board
__device__ bool IsLegal(int *_board, int _loc, int _val)
{
	if (is_legal_entry_dev(_board, SUB_BOARD_SIZE, _loc / SUB_BOARD_DIM, _loc % SUB_BOARD_DIM, _val, _loc)) {
		_board[_loc] = _val;
		return true;
	}

	return false;
}

// Find next empty cell in passed in board
__device__ int FindNextEmptyCell(int* board) {
	for (int i = 0; i < BOARD_SIZE; i++) {
		if (board[i] == 0) {
			return i;
		}
	}
	return -1;
}

// new boards points to the end of the filled in prev boards
__global__ void GenerateBoardsByCell(int *prev_boards, int prev_board_num, int *new_boards, int *new_board_num) {

	// gives the previous board number to look at
	int t_idx = blockDim.x * blockIdx.x + threadIdx.x;

	// each thread will look at 1 previous board 
	// thread only does work if the amount of previous boards greater than its thread num
	// maybe should use a for loop in the case a thread has to do more than one thread. Will this ever occur?
	if (t_idx < prev_board_num) {
		int prev_board_start = t_idx * BOARD_SIZE;
		int* thread_prev_board = (int*)malloc(sizeof(int) * BOARD_SIZE);

		for (int i = 0; i < SUB_BOARD_SIZE; i++) { // read prev board into a sudoku sized local array
			thread_prev_board[i] = prev_boards[prev_board_start + i];
		}

		// find next index we can add to
		int empty_cell = FindNextEmptyCell(thread_prev_board);
		if (empty_cell == -1) { // Board is full
			return;
		}

		// Now try all possible numbers in this cell that islegal
		for (int i = 1; i <= 9; i++) {
			if (IsLegal(thread_prev_board, empty_cell, i)) { // number can go in this cell

				// where to start appending for the new board
				int new_board_offset = atomicAdd(&new_board_num, 1); // increment amount of boards at the new depth

				for (int j = 0; j < BOARD_SIZE; j++) {
					int ind = (new_board_offset * BOARD_SIZE) + j;

					new_boards[ind] = thread_prev_board[j];
				}
			}
		}
	}

}

__global__ void SolveBoard(int **_all_boards, int *_solved_board) {

}

void solve(int *board, int depth) {


	int *new_boards;
	int *old_boards;
	int *solution;
	int *board_num;
	int host_solution[SUB_BOARD_SIZE*SUB_BOARD_SIZE];

	int DEPTH = 7;

	const int memSize = 81 * pow(9, DEPTH);

	// alloc device memory
	cudaMalloc(&new_boards, memSize * sizeof(int));
	cudaMalloc(&old_boards, memSize * sizeof(int));
	cudaMalloc(&solution, SUB_BOARD_SIZE * SUB_BOARD_SIZE * sizeof(int));
	cudaMalloc(&board_num, sizeof(int));

	cudaMemset(board_num, 0, sizeof(int));
	cudaMemset(new_boards, 0, memSize * sizeof(int));
	cudaMemset(old_boards, 0, memSize * sizeof(int));
	cudaMemset(solution, 0, SUB_BOARD_SIZE * SUB_BOARD_SIZE * sizeof(int));

	for (int i = 0; i < depth; i++) {

		/// Generate Board
		/// Save New Boards
		/// Fix indices
		/// reiterate

	}
}

int main()
{
	// Solve medium sized board and go to depth 7 of BFS
	solve(test_board_medium, 7);
}
