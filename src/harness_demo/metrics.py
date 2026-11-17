"""Métriques de classification binaire, sans dépendance externe."""

from collections.abc import Sequence


def precision_recall_f1(y_true: Sequence[int], y_pred: Sequence[int]) -> tuple[float, float, float]:
    """Calcule précision, rappel et F1 pour une classification binaire (classe positive = 1).

    Args:
        y_true: Étiquettes réelles (0 ou 1).
        y_pred: Étiquettes prédites (0 ou 1).

    Returns:
        Le triplet (precision, recall, f1). Vaut 0.0 quand le dénominateur est nul.

    Raises:
        ValueError: Si les deux séquences n'ont pas la même longueur.
    """
    if len(y_true) != len(y_pred):
        raise ValueError(f"Longueurs différentes : {len(y_true)} != {len(y_pred)}")

    tp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == 1 and p == 1)
    fp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == 0 and p == 1)
    fn = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == 1 and p == 0)

    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return precision, recall, f1
