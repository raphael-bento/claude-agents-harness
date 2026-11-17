import pytest

from harness_demo import accuracy, confusion_matrix, precision_recall_f1


@pytest.mark.parametrize(
    ("y_true", "y_pred", "expected"),
    [
        ([1, 0, 1, 1], [1, 0, 1, 1], (1.0, 1.0, 1.0)),
        ([1, 1, 0, 0], [1, 0, 1, 0], (0.5, 0.5, 0.5)),
        ([0, 0, 0], [0, 0, 0], (0.0, 0.0, 0.0)),
        ([], [], (0.0, 0.0, 0.0)),
    ],
)
def test_precision_recall_f1_known_cases(y_true, y_pred, expected):
    assert precision_recall_f1(y_true, y_pred) == pytest.approx(expected)


def test_precision_recall_f1_length_mismatch_raises():
    with pytest.raises(ValueError):
        precision_recall_f1([1, 0], [1])


@pytest.mark.parametrize(
    ("y_true", "y_pred", "expected"),
    [
        ([1, 0, 1, 1], [1, 0, 1, 1], 1.0),
        ([1, 1, 0, 0], [1, 0, 1, 0], 0.5),
        ([1, 1], [0, 0], 0.0),
        ([1, 1, 1], [1, 1, 1], 1.0),  # une seule classe
        ([], [], 0.0),
    ],
)
def test_accuracy_known_cases(y_true, y_pred, expected):
    assert accuracy(y_true, y_pred) == pytest.approx(expected)


def test_accuracy_length_mismatch_raises():
    with pytest.raises(ValueError):
        accuracy([1, 0], [1])


@pytest.mark.parametrize(
    ("y_true", "y_pred", "expected"),
    [
        ([1, 0, 1, 0], [1, 0, 0, 1], [[1, 1], [1, 1]]),
        ([1, 1, 1], [1, 1, 1], [[0, 0], [0, 3]]),  # une seule classe
        ([0, 0], [0, 0], [[2, 0], [0, 0]]),
        ([], [], [[0, 0], [0, 0]]),
        ([1, 1, 0], [1, 0, 0], [[1, 0], [1, 1]]),  # asymétrique : distingue fp de fn
        ([True, False], [True, True], [[0, 1], [0, 1]]),  # bool accepté
    ],
)
def test_confusion_matrix_known_cases(y_true, y_pred, expected):
    assert confusion_matrix(y_true, y_pred) == expected


def test_confusion_matrix_length_mismatch_raises():
    with pytest.raises(ValueError):
        confusion_matrix([1, 0], [1])


@pytest.mark.parametrize(
    ("y_true", "y_pred"),
    [([2], [1]), ([1], [2]), ([-1], [1]), ([1], [-1]), ([None], [1]), ([1.0], [1]), ([1], [0.0])],
)
def test_confusion_matrix_invalid_label_raises(y_true, y_pred):
    with pytest.raises(ValueError):
        confusion_matrix(y_true, y_pred)
