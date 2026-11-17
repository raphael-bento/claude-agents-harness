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


def _is_label(value: object) -> bool:
    """Indique si ``value`` est un entier valant 0 ou 1 (``bool`` inclus)."""
    return isinstance(value, int) and value in (0, 1)


def accuracy(y_true: Sequence[int], y_pred: Sequence[int]) -> float:
    """Calcule la proportion de prédictions correctes.

    Args:
        y_true: Étiquettes réelles.
        y_pred: Étiquettes prédites.

    Returns:
        L'accuracy entre 0.0 et 1.0. Vaut 0.0 pour des séquences vides.

    Raises:
        ValueError: Si les deux séquences n'ont pas la même longueur.
    """
    if len(y_true) != len(y_pred):
        raise ValueError(f"Longueurs différentes : {len(y_true)} != {len(y_pred)}")
    if len(y_true) == 0:
        return 0.0
    return sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == p) / len(y_true)


def confusion_matrix(y_true: Sequence[int], y_pred: Sequence[int]) -> list[list[int]]:
    """Calcule la matrice de confusion binaire (classe positive = 1).

    Args:
        y_true: Étiquettes réelles (0 ou 1).
        y_pred: Étiquettes prédites (0 ou 1).

    Returns:
        La matrice ``[[tn, fp], [fn, tp]]`` : lignes = réel, colonnes = prédit.

    Raises:
        ValueError: Si les longueurs diffèrent ou si une étiquette n'est pas l'entier 0 ou 1
            (les booléens sont acceptés ; les flottants comme ``1.0`` et ``None`` sont rejetés).
    """
    if len(y_true) != len(y_pred):
        raise ValueError(f"Longueurs différentes : {len(y_true)} != {len(y_pred)}")
    matrix = [[0, 0], [0, 0]]
    for t, p in zip(y_true, y_pred, strict=True):
        if not (_is_label(t) and _is_label(p)):
            raise ValueError(f"Étiquette invalide (attendu 0 ou 1) : {t}, {p}")
        matrix[t][p] += 1
    return matrix
