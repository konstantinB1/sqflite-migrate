int nearestIndexOf(String text, List<String> searchTerms, int startIndex) {
  int nearestIndex = -1;
  int nearestDistance = text.length;

  for (String term in searchTerms) {
    int index = text.indexOf(term, startIndex);

    if (index != -1 && index < nearestDistance) {
      nearestIndex = index;
      nearestDistance = index;
    }
  }

  return nearestIndex;
}

String nextLine(String text, int startIndex) {
  int nextLineIndex = text.indexOf('\n', startIndex);

  if (nextLineIndex == -1) {
    return text.substring(startIndex);
  }

  return text.substring(startIndex, nextLineIndex);
}

List<T> until<T>(List<T> list, bool Function(T, int index) predicate,
    {startIndex = 0}) {
  List<T> result = [];

  for (int i = startIndex; i < list.length; i++) {
    if (predicate(list[i], i)) {
      break;
    }

    result.add(list[i]);
  }

  return result;
}

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
