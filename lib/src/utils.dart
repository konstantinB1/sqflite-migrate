// Iterate over list from last to first, breaking on bool predicate
// callback and returning the result
List<T> untilReverse<T>(List<T> list, bool Function(T, int index) predicate,
    {startIndex = 0}) {
  List<T> result = [];

  for (int i = startIndex; i >= 0; i--) {
    if (predicate(list[i], i)) {
      break;
    }

    result.add(list[i]);
  }

  return result;
}
