"""
Los 5 tipos de propiedades — ejemplos ejecutables (Python / hypothesis)
Referencia generativa para /property-test. @seed fijo = reproducible.

    pip install hypothesis pytest
    pytest property_types.py
"""
from hypothesis import given, seed, settings, strategies as st

SEED = 42


# --- funciones de ejemplo bajo prueba ---
def serialize_amount(n: float) -> str:
    return f"{n:.2f}"


def parse_amount(s: str) -> float:
    return float(s)


def normalize_tag(s: str) -> str:
    return s.strip().lower()


def tax_of(price: float) -> float:
    return round(price * 0.19, 2)


def discounted_price(price: float, discount: float) -> float:
    return max(0.0, price - discount)


def fast_sum(xs: list[int]) -> int:
    return sum(xs)


def ref_sum(xs: list[int]) -> int:
    total = 0
    for x in xs:
        total += x
    return total


# 1. ROUND-TRIP: parse(serialize(x)) ~= x
@seed(SEED)
@settings(max_examples=100)
@given(st.floats(min_value=0, max_value=1e6, allow_nan=False, allow_infinity=False))
def test_round_trip(x):
    r = round(x, 2)
    assert abs(parse_amount(serialize_amount(r)) - r) < 1e-9


# 2. IDEMPOTENCY: f(f(x)) == f(x)
@seed(SEED)
@given(st.text())
def test_idempotency(s):
    assert normalize_tag(normalize_tag(s)) == normalize_tag(s)


# 3. MONOTONICITY: a <= b => f(a) <= f(b)
@seed(SEED)
@given(st.floats(0, 1e4, allow_nan=False), st.floats(0, 1e4, allow_nan=False))
def test_monotonicity(a, b):
    if a <= b:
        assert tax_of(a) <= tax_of(b)


# 4. INVARIANTS: postcondición siempre cierta
@seed(SEED)
@given(st.floats(0, 1e6, allow_nan=False), st.floats(0, 1e6, allow_nan=False))
def test_invariant_non_negative(p, d):
    assert discounted_price(p, d) >= 0


# 5. ORACLE: impl optimizada == impl de referencia
@seed(SEED)
@given(st.lists(st.integers(-1000, 1000), max_size=50))
def test_oracle(xs):
    assert fast_sum(xs) == ref_sum(xs)
