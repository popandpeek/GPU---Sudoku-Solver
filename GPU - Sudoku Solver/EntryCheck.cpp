/*
** Ben Pittman
** Greg Smith
** Calvin Winston Fei
** Term Project - EntryCheck.cpp
** Static class for checking solutions.
** Assumptions: Assumes valid board size and 1D memory allocation
*/

#include <stdio.h>
#include <iostream>

static class EntryCheck {

	bool is_legal_entry(const int* _board, int _board_root, int _row, int _col, int _entry) {
		return row_check(_board, _board_root, _row, _entry) &&
			column_check(_board, _board_root, _col, _entry) &&
			grid_check(_board, _board_root, _row, _col, _entry);
	}

	bool row_check(const int* _board, int _board_root, int _row, int _entry) {
		for (int i = _row * _board_root; i < _row * _board_root + _board_root; i ++) {
			if (_board[i] == _entry) {
				return false;
			}
		}

		return true;
	}

	bool column_check(const int* _board, int _board_root, int _col, int _entry) {
		for (int i = _col; i < _board_root * _board_root - (_board_root - _col); i += _board_root) {
			if (_board[i] == _entry) {
				return false;
			}
		}

		return true;
	}

	bool grid_check(const int* _board, int _board_root, int _start_row, int _start_col, int _entry) {
		for (int i = _start_row; i < _start_row + (int)sqrt(_board_root); i++) {
			for (int j = _start_col; j < _start_col + (int)sqrt(_board_root); j++) {
				if (_board[i * _start_col + j] == _entry) {
					return false;
				}
			}
		}

		return true;
	}
};
