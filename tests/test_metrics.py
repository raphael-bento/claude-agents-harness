import pytest

from harness_demo import precision_recall_f1


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
