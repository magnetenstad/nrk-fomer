#+vet unused shadowing using-stmt style semicolon
package main
import "core:math"

Min_Heap :: struct($T: typeid) {
	array: [dynamic]T,
	less:  proc(a: T, b: T) -> bool,
}

parent :: proc(i: int) -> int {
	return int(math.floor(f32(i) / 2.0))
}

left :: proc(i: int) -> int {
	return 2 * i + 1
}

right :: proc(i: int) -> int {
	return 2 * i + 2
}

min_heapify :: proc(A: ^Min_Heap($T), i: int) {
	l := left(i)
	r := right(i)
	heap_size := len(A.array)

	smallest := i
	if l < heap_size && A.less(A.array[l], A.array[i]) {
		smallest = l
	}
	if r < heap_size && A.less(A.array[r], A.array[smallest]) {
		smallest = r
	}

	if smallest != i {
		A.array[i], A.array[smallest] = A.array[smallest], A.array[i]
		min_heapify(A, smallest)
	}
}

build_min_heap :: proc(
	array: [dynamic]$T,
	less: proc(a: T, b: T) -> bool,
) -> Min_Heap(T) {

	A := Min_Heap(T) {
		array = array,
		less  = less,
	}
	half := int(math.floor(f32(len(array)) / 2.0))

	for i := half; i >= 0; i -= 1 {
		min_heapify(&A, i)
	}

	return A
}

pop :: proc(A: ^Min_Heap($T)) -> T {
	heap_size := len(A.array)
	if heap_size < 0 {
		print("ERROR: heap underflow")
	}
	min_ := A.array[0]
	A.array[0] = A.array[heap_size - 1]
	ordered_remove(&A.array, len(A.array) - 1)
	min_heapify(A, 0)
	return min_
}

push :: proc(A: ^Min_Heap($T), key: T) {
	append(&A.array, key)
	i := len(A.array) - 1
	A.array[i] = key
	for i > 0 && A.less(A.array[i], A.array[parent(i)]) {
		A.array[i], A.array[parent(i)] = A.array[parent(i)], A.array[i]
		i = parent(i)
	}
}
