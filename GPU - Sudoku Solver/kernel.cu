
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

#define THREAD_PER_BLOCK 1024

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
	int t_idx = blockDim.x * blockIdx.x + threadIdx.x;

	// Each thread does DFS on 1 board
	if (t_idx < total_boards) 
	{
		int board_start = t_idx * BOARD_SIZE;
		int* thread_board = (int*)malloc(sizeof(int) * BOARD_SIZE);

		for (int i = 0; i < SUB_BOARD_SIZE; i++)// read prev board into a sudoku sized local array
		{ 
			thread_board[i] = boards[board_start + i];
		}



	}

}


// The main solve function to be called
void solve(int *board, int depth) {

	int h_solution[BOARD_SIZE];
	memset(h_solution, 0, BOARD_SIZE * sizeof(int));

	int *new_boards;
	int *old_boards;
	int *solution;
	int *next_board_num;

	const int memSize = 81 * pow(9, depth);

	// allocate device memory and set everything to 0
	cudaMalloc(&next_board_num, sizeof(int));
	cudaMalloc(&solution, BOARD_SIZE * sizeof(int));
	cudaMalloc(&new_boards, memSize * sizeof(int));
	cudaMalloc(&old_boards, memSize * sizeof(int));

	cudaMemset(next_board_num, 0, sizeof(int));
	cudaMemset(solution, 0, BOARD_SIZE * sizeof(int));
	cudaMemset(new_boards, 0, memSize * sizeof(int));
	cudaMemset(old_boards, 0, memSize * sizeof(int));


	// BFS on GPU

	// copy starting board to device memory
	cudaMemcpy(old_boards, board, BOARD_SIZE * sizeof(int), cudaMemcpyHostToDevice);

	// 1 due to starting board
	int old_board_num = 1;
	for (int i = 0; i < depth; i++) {

		// Need 1 thread per old board
		int num_blocks = (old_board_num + THREAD_PER_BLOCK - 1) / THREAD_PER_BLOCK;

		// need to set next board num to 0 before we start next depth
		cudaMemset(next_board_num, 0, sizeof(int));

		// we will read from old boards first and put into new boards
		GenerateBoardsByCell << <num_blocks, THREAD_PER_BLOCK >> > (old_boards, old_board_num, new_boards, next_board_num);

		// old and new boards are swapped in order for us to reuse the memory since we only care about the last depth
		
		int* temp_board = old_boards;
		old_boards = new_boards;
		new_boards = temp_board;

		// update the amount of boards in previous depth for next iteration
		cudaMemcpy(&old_board_num, next_board_num, sizeof(int), cudaMemcpyDeviceToHost);
	}


	// DFS on GPU
	// total amount of boards is just the boards in last depth
	int total_board_num = old_board_num;
	//cudaMemcpy(&total_board_num, next_board_num, sizeof(int), cudaMemcpyDeviceToHost);

	int num_blocks = (total_board_num + THREAD_PER_BLOCK - 1) / THREAD_PER_BLOCK;

	SolveBoard << <num_blocks, THREAD_PER_BLOCK >> > (old_boards, total_board_num, solution);

	cudaDeviceSynchronize();

	// copy the devicce solution to the host
	cudaMemcpy(h_solution, solution, BOARD_SIZE * sizeof(int), cudaMemcpyDeviceToHost);

	// Print board?

	cudaFree(new_boards);
	cudaFree(&old_boards);
	cudaFree(&solution);
	cudaFree(&next_board_num);

	return;
}

int main()
{
	// Solve medium sized board and go to depth 7 of BFS
	//solve(test_board_medium, 7);
	solve(test_board_medium, 1);
}
