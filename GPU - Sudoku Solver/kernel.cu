#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>

#include <stdlib.h>
#include <cmath>
#include <vector>
#include <cstring>
#include <iostream>
#include <fstream>

#define THREADS_PER_BLOCK 512
#define BOARD_SIZE 81
#define SUB_BOARD_SIZE 9
#define SUB_BOARD_DIM 3

void print_board_1d(int *board) {

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

// function to examine if there are conflicts or not if cell [row][col] is num
__device__
bool noConflicts(int matrix[BOARD_SIZE], int row, int col, int num) {
	if (num <= 0 || num > SUB_BOARD_SIZE) return false;
	for (int i = 0; i < SUB_BOARD_SIZE; i++) {
		if (i == row)   continue;
		if (matrix[i * SUB_BOARD_SIZE + col] == num) {
			return false;
		}
	}

	for (int j = 0; j < SUB_BOARD_SIZE; j++) {
		if (j == col)   continue;
		if (matrix[row * SUB_BOARD_SIZE + j] == num) {
			return false;
		}
	}

	for (int i = 0; i < SUB_BOARD_DIM; i++) {
		for (int j = 0; j < SUB_BOARD_DIM; j++) {
			int mat_row = (row / SUB_BOARD_DIM)*SUB_BOARD_DIM + i;
			int mat_col = (col / SUB_BOARD_DIM)*SUB_BOARD_DIM + j;
			if (mat_row == row && mat_col == col)   continue;
			if (matrix[mat_row * SUB_BOARD_SIZE + mat_col] == num) {
				return false;
			}
		}
	}
	return true;
}

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



__device__ bool row_check_dev(const int* _board, int _board_root, int _row, int _entry, int loc, int _boardStart)
{
	for (int i = _row * _board_root; i < _row * _board_root + _board_root; i++) {
		if (i != loc && _board[i + _boardStart] == _entry)
		{
			return false;
		}
	}

	return true;
}

__device__ bool column_check_dev(const int* _board, int _board_root, int _col, int _entry, int loc, int _boardStart)
{
	for (int i = _col; i < _board_root * _board_root - (_board_root - _col); i += _board_root) {
		if (i != loc && _board[i + _boardStart] == _entry) {
			return false;
		}
	}

	return true;
}

__device__ bool grid_check_dev(const int* _board, int _board_root, int _start_row, int _start_col, int _entry, int loc, int _boardStart)
{
	int sub_grid_x = _start_row / SUB_BOARD_DIM; // 0, 1, or 2
	int sub_grid_y = _start_col / SUB_BOARD_DIM; // 0, 1, or 2
	int grid_start = (sub_grid_x * SUB_BOARD_SIZE * SUB_BOARD_DIM) + (sub_grid_y * SUB_BOARD_DIM);
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			//		  start ind     rows of grid         col
			int ind = grid_start + (i * SUB_BOARD_SIZE) + j;
			if (ind != loc && _board[ind + _boardStart] == _entry) {
				return false;
			}
		}
	}

	return true;
}

__device__ bool is_legal_entry_dev(const int* _board, int _board_root, int _row, int _col, int _entry, int loc, int _boardStart)
{
	return row_check_dev(_board, _board_root, _row, _entry, loc, _boardStart) &&
		column_check_dev(_board, _board_root, _col, _entry, loc, _boardStart) &&
		grid_check_dev(_board, _board_root, _row, _col, _entry, loc, _boardStart);
}

// Returns whether or not it is valid to put a value in specified location for this board
__device__ bool IsLegal(int *_board, int _loc, int _val, int _boardStart)
{
	if (is_legal_entry_dev(_board, SUB_BOARD_SIZE, _loc / SUB_BOARD_DIM + _boardStart, _loc % SUB_BOARD_DIM + _boardStart, _val, _loc, _boardStart)) {
		_board[_loc] = _val;
		return true;
	}

	return false;
}

// Find next empty cell in passed in board
__device__ int FindNextEmptyCell(int* board, int _boardStart) {
	for (int i = 0; i < BOARD_SIZE; i++)
	{
		if (board[i + _boardStart] == 0) {
			return i;
		}
	}
	return -1;
}

// new boards points to the end of the filled in prev boards
__global__ void GenerateBoardsByCell(int *old_boards, int old_board_num, int *new_boards, int *new_board_num) {

	// gives the previous board number to look at
	int t_idx = blockDim.x * blockIdx.x + threadIdx.x;

	// each thread will look at 1 previous board 
	// thread only does work if the amount of previous boards greater than its thread num
	// maybe should use a for loop in the case a thread has to do more than one thread. Will this ever occur?
	if (t_idx < old_board_num) {
		int old_board_start = t_idx * BOARD_SIZE;


		// find next index we can add to
		int empty_cell_ind = FindNextEmptyCell(old_boards, old_board_start);
		if (empty_cell_ind == -1) { // Board is full
			return;
		}

		// Now try all possible numbers in this cell that is legal
		for (int i = 1; i <= 9; i++) {
			if (IsLegal(old_boards, empty_cell_ind, i, old_board_start)) { // number can go in this cell

				// where to start appending for the new board
				int new_board_offset = atomicAdd(new_board_num, 1); // increment amount of boards at the new depth

				for (int j = 0; j < BOARD_SIZE; j++)
				{
					int ind = (new_board_offset * BOARD_SIZE) + j;

					new_boards[ind] = old_boards[j + old_board_start];
				}
			}
		}
	}

}

// Use DFS to solve specified board per thread
__global__ void SolveBoard(int *boards, int total_boards, int* solution) {
	int t_idx = blockIdx.x * blockDim.x + threadIdx.x;


	if (t_idx < total_boards) {

		int empty_cells = 0;

		int* empty_indices = (int*)malloc(sizeof(int) * BOARD_SIZE);
		int* thread_board = (int*)malloc(sizeof(int) * BOARD_SIZE);

		int board_start = t_idx * BOARD_SIZE;
		for (int i = 0; i < BOARD_SIZE; i++) {
			int ind = board_start + i;

			thread_board[i] = boards[ind];
			if (thread_board[i] == 0) {
				empty_indices[empty_cells] = i;
				empty_cells++;
			}
		}

		int filled_empty_cells = 0;
		while (filled_empty_cells >= 0 && filled_empty_cells < empty_cells) {

			int next_cell = empty_indices[filled_empty_cells];
			int row = next_cell / SUB_BOARD_SIZE;
			int col = next_cell % SUB_BOARD_SIZE;

			int val = thread_board[next_cell] + 1;
			thread_board[next_cell]++;

			if (noConflicts(thread_board, row, col, val)) { // IsLegal does not work here?
				filled_empty_cells++;
			}
			else if (thread_board[next_cell] >= SUB_BOARD_SIZE) {
				thread_board[next_cell] = 0;
				filled_empty_cells--;
			}
		}
		if (filled_empty_cells == empty_cells) {
			memcpy(solution, thread_board, BOARD_SIZE * sizeof(int));
		}
	}
}

// Every additional depth guesses one cell with every possible potential
void GenerateBoardsBFS(int* prev_boards, int* new_board_num, int* new_boards, int depth) {

	// 1 because of the first board. This will then change iteration according to the permutations at each depth
	int prev_board_num = 1;

	for (int i = 0; i < depth; i++) {
		int block_num = (prev_board_num + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
		cudaMemset(new_board_num, 0, sizeof(int));
		GenerateBoardsByCell << <block_num, THREADS_PER_BLOCK >> > (prev_boards, prev_board_num, new_boards, new_board_num);
		int* tmp = prev_boards;
		prev_boards = new_boards;
		new_boards = tmp;
		cudaMemcpy(&prev_board_num, new_board_num, sizeof(int), cudaMemcpyDeviceToHost);
	}
}

// The main solve function
void solve_board(int * board, int depth) {

	// Board that wil FIRST hold the old depth boards (first board)
	int *old_boards;

	// This needs to be a pointer since we want to increment in a device function
	int *old_board_num;

	// Clear storage until second iteration
	int *new_boards;

	// Solution
	int *solution;
	int h_solution[BOARD_SIZE];
	memset(h_solution, 0, BOARD_SIZE * sizeof(int));

	// Theoretical upper bound of boards each cell of a level having all 9 potentials
	const int memSize = 81 * pow(9, depth);

	// alloc device memory
	cudaMalloc(&old_board_num, sizeof(int));
	cudaMalloc(&new_boards, memSize * sizeof(int));
	cudaMalloc(&old_boards, memSize * sizeof(int));
	cudaMalloc(&solution, BOARD_SIZE * sizeof(int));


	cudaMemset(old_board_num, 0, sizeof(int));
	cudaMemset(old_boards, 0, memSize * sizeof(int));
	cudaMemset(new_boards, 0, memSize * sizeof(int));
	cudaMemset(solution, 0, BOARD_SIZE * sizeof(int));

	// Copy the starting board into our storage array 
	cudaMemcpy(old_boards, board, BOARD_SIZE * sizeof(int), cudaMemcpyHostToDevice);

	// generates a set of boards with the first depth cells filled in
	GenerateBoardsBFS(old_boards, old_board_num, new_boards, depth);

	// get the total number of boards back
	int total_board_num = 1;
	cudaMemcpy(&total_board_num, old_board_num, sizeof(int), cudaMemcpyDeviceToHost);

	// Now we solve each board per thread on the GPU by DFS
	int block_num = (total_board_num + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
	SolveBoard << <total_board_num, THREADS_PER_BLOCK >> > (old_boards, total_board_num, solution);
	cudaDeviceSynchronize();

	cudaMemcpy(h_solution, solution, BOARD_SIZE * sizeof(int), cudaMemcpyDeviceToHost);

	// Get the solution and print for correctness
	print_board_1d(h_solution);


	// free all used memory
	cudaFree(new_boards);
	cudaFree(&old_boards);
	cudaFree(&old_board_num);
	cudaFree(&solution);
}


int main(int argc, char* argv[]) {

	int* board = new int[81]{		  
		0, 0, 0, 0, 0, 0, 3, 0, 0,
		8, 5, 2, 3, 0, 0, 0, 0, 1,
		0, 9, 0, 2, 0, 0, 0, 0, 4,
		9, 7, 4, 0, 0, 0, 0, 0, 0,
		0, 1, 0, 0, 6, 0, 0, 0, 0,
		0, 0, 0, 0, 4, 0, 0, 0, 0,
		6, 0, 9, 0, 8, 0, 0, 3, 7,
		3, 0, 0, 0, 0, 0, 0, 6, 0,
		0, 2, 0, 0, 0, 5, 0, 0, 0 };

	solve_board(board, 5);

	return 0;
}