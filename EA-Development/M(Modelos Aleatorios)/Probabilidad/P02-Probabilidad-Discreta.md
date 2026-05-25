---
tags: [probabilidad, discreta]
refs: [Ross Cap. 1-2]
---

# Cálculo de Probabilidades Discretas

## Axiomas de Kolmogorov
Para todo evento $A \subseteq \Omega$:
1. $P(A) \geq 0$
2. $P(\Omega) = 1$
3. Si $A \cap B = \emptyset$ entonces $P(A \cup B) = P(A) + P(B)$

## Espacio equiprobable
Si $\Omega$ tiene $n$ resultados igualmente probables:
$$P(A) = \frac{|A|}{|\Omega|} = \frac{\text{casos favorables}}{\text{casos totales}}$$

## Propiedades derivadas

| Propiedad | Fórmula |
|-----------|---------|
| Complemento | $P(A^c) = 1 - P(A)$ |
| Imposible | $P(\emptyset) = 0$ |
| Unión general | $P(A \cup B) = P(A) + P(B) - P(A \cap B)$ |
| Monotonía | $A \subseteq B \Rightarrow P(A) \leq P(B)$ |

## Probabilidad condicional
$$P(A \mid B) = \frac{P(A \cap B)}{P(B)}, \quad P(B) > 0$$

## Independencia
$A$ y $B$ son **independientes** si:
$$P(A \cap B) = P(A) \cdot P(B)$$

## Regla de la multiplicación
$$P(A \cap B) = P(A \mid B) \cdot P(B) = P(B \mid A) \cdot P(A)$$

## Herramientas de conteo

| Técnica | Fórmula | Cuándo |
|---------|---------|--------|
| Permutaciones | $P(n,r) = \frac{n!}{(n-r)!}$ | orden importa, sin repetición |
| Combinaciones | $\binom{n}{r} = \frac{n!}{r!(n-r)!}$ | orden no importa |
| Con repetición | $n^r$ | orden importa, con repetición |

## Ejercicios
- [ ] 
