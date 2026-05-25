---
tags: [analisis, rudin, cap1, induccion, enteros]
refs: [Rudin Cap. 1 — Sec. 1.10; Apéndice]
---

# Sesión — Principio de Inducción Matemática

> Prerequisito: [[Sesion-01-Numeros-Reales]]
> Lee en Reading View: `Ctrl + E`

---

## 1. ¿Por qué se necesita inducción?

Muchas propiedades matemáticas tienen la forma:

> "Para todo entero $n \geq 1$, vale $P(n)$."

No podemos verificar $P(1), P(2), P(3), \ldots$ infinitos casos. La inducción da una forma **finita** de probar infinitos casos: demostrar que la propiedad "se contagia" de un número al siguiente.

---

## 2. Principio de Inducción Matemática

### Enunciado

Sea $P(n)$ una proposición sobre los enteros positivos. Si:

1. **Base:** $P(1)$ es verdadera.
2. **Paso inductivo:** Para todo $k \geq 1$: si $P(k)$ es verdadera, entonces $P(k+1)$ también lo es.

Entonces $P(n)$ es verdadera para todo $n \in \mathbb{N}$.

### Fundamento (Rudin)

Rudin fundamenta la inducción en la propiedad del **buen orden**: todo subconjunto no vacío de $\mathbb{N}$ tiene un elemento mínimo. Si $P(n)$ fallara para algún $n$, habría un mínimo $n_0$ con $P(n_0)$ falsa. Como $P(1)$ es verdadera, $n_0 \geq 2$. Pero entonces $P(n_0 - 1)$ es verdadera y el paso inductivo da $P(n_0)$ verdadera — contradicción.

---

## 3. Estructura de una Demostración por Inducción

```
PASO 1 — Verificar la base P(1)
         Sustituir n=1 y comprobar directamente.

PASO 2 — Hipótesis inductiva
         Suponer que P(k) es verdadera para algún k ≥ 1 fijo.
         (NO para todos los k — solo para uno fijo arbitrario.)

PASO 3 — Paso inductivo: demostrar P(k+1)
         Usar la hipótesis de que P(k) vale para deducir que P(k+1) vale.
         Este es el paso creativo — hay que encontrar la conexión entre
         P(k) y P(k+1).

PASO 4 — Conclusión
         Por el Principio de Inducción, P(n) vale para todo n ∈ ℕ.
```

---

## 4. Ejemplo 1 — Suma de los primeros $n$ enteros

**Proposición $P(n)$:**

$$\sum_{k=1}^{n} k = \frac{n(n+1)}{2}$$

**Base $P(1)$:**

$$\sum_{k=1}^{1} k = 1 = \frac{1 \cdot 2}{2} = 1 \quad \checkmark$$

**Hipótesis inductiva:** Suponer que $P(k)$ es verdadera:

$$\sum_{k=1}^{k} k = \frac{k(k+1)}{2}$$

**Paso inductivo — demostrar $P(k+1)$:**

$$\sum_{j=1}^{k+1} j = \left(\sum_{j=1}^{k} j\right) + (k+1) = \frac{k(k+1)}{2} + (k+1)$$

Factorizando $(k+1)$:

$$= (k+1)\left(\frac{k}{2} + 1\right) = (k+1) \cdot \frac{k+2}{2} = \frac{(k+1)(k+2)}{2}$$

Que es exactamente la fórmula con $n = k+1$. $\blacksquare$

---

## 5. Ejemplo 2 — Suma de cuadrados

**Proposición $P(n)$:**

$$\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6}$$

**Base $P(1)$:** $1 = \frac{1 \cdot 2 \cdot 3}{6} = 1$ ✓

**Paso inductivo:**

$$\sum_{k=1}^{k+1} k^2 = \frac{k(k+1)(2k+1)}{6} + (k+1)^2$$

$$= (k+1)\left[\frac{k(2k+1)}{6} + (k+1)\right] = (k+1) \cdot \frac{k(2k+1) + 6(k+1)}{6}$$

$$= (k+1) \cdot \frac{2k^2 + 7k + 6}{6} = (k+1) \cdot \frac{(k+2)(2k+3)}{6}$$

$$= \frac{(k+1)(k+2)(2(k+1)+1)}{6} \quad \blacksquare$$

---

## 6. Ejemplo 3 — Desigualdad de Bernoulli

**Proposición $P(n)$:** Para $x > -1$,

$$(1 + x)^n \geq 1 + nx$$

**Base $P(1)$:** $(1+x)^1 = 1 + x \geq 1 + x$ ✓

**Paso inductivo:** Suponer $(1+x)^k \geq 1 + kx$. Como $1 + x > 0$:

$$(1+x)^{k+1} = (1+x)^k \cdot (1+x) \geq (1+kx)(1+x)$$

Expandiendo:

$$= 1 + kx + x + kx^2 = 1 + (k+1)x + kx^2 \geq 1 + (k+1)x$$

(ya que $kx^2 \geq 0$). $\blacksquare$

Esta desigualdad aparece en la demostración del Ejercicio 7 del Cap. 1 (logaritmos).

### Analogía — Interés compuesto

$(1 + r)^n$ es el factor de crecimiento de una inversión con tasa $r$ compuesta $n$ períodos. La desigualdad de Bernoulli dice que $(1+r)^n \geq 1 + nr$ — el interés compuesto **siempre supera o iguala** al interés simple. La igualdad solo se da en $n=1$ o $r=0$.

---

## 7. Inducción Fuerte

### Cuándo usarla

Cuando el paso inductivo necesita **todos** los casos anteriores, no solo $P(k)$.

### Enunciado

Si:
1. $P(1)$ es verdadera.
2. Para todo $k \geq 1$: si $P(1), P(2), \ldots, P(k)$ son todas verdaderas, entonces $P(k+1)$ también lo es.

Entonces $P(n)$ vale para todo $n \in \mathbb{N}$.

### Ejemplo — Todo entero $n \geq 2$ es producto de primos

**Base $P(2)$:** $2$ es primo ✓

**Paso (inducción fuerte):** Suponer que todo entero $2 \leq j \leq k$ es producto de primos. Para $k+1$:
- Si $k+1$ es primo: ya es producto de primos (de sí mismo).
- Si $k+1$ es compuesto: $k+1 = a \cdot b$ con $2 \leq a, b < k+1$. Por hipótesis (inducción fuerte) $a$ y $b$ son productos de primos, luego $k+1$ también lo es. $\blacksquare$

---

## 8. Errores comunes en inducción

### Error 1 — Olvidar verificar la base

La demostración es vacía sin la base. El paso inductivo solo dice "si alguno vale, el siguiente también vale" — pero si ninguno vale al inicio, nada arranca.

**Ejemplo clásico de demostración falsa:**

Afirmación: "Todos los caballos son del mismo color."

*"Base"*: con 1 caballo, trivialmente todos son del mismo color ✓

*"Paso"*: supongamos que cualquier grupo de $k$ caballos es del mismo color. En un grupo de $k+1$, los primeros $k$ son del mismo color y los últimos $k$ también. Como se superponen... **ERROR**: para $k=1$ el paso falla porque los dos grupos de tamaño $k=1$ no se superponen. La inducción se rompe en $k=1 \to k+1=2$.

### Error 2 — Usar P(k+1) en la demostración de P(k+1)

Razonamiento circular. Hay que demostrar $P(k+1)$ **solo** usando $P(k)$ (o anteriores en inducción fuerte).

---

## 9. Inducción hacia atrás

Una variante: demostrar $P(n)$ para $n$ potencia de 2, y luego pasar de $P(n)$ a $P(n-1)$.

Ejemplo: la desigualdad de las medias aritmética-geométrica $\text{MA} \geq \text{MG}$ se demuestra primero para potencias de 2 y luego se extiende por inducción hacia atrás.

---

## Ejercicios

- [ ] **E1.** Demuestra por inducción que $\sum_{k=1}^{n} k^3 = \left(\dfrac{n(n+1)}{2}\right)^2$.
- [ ] **E2.** Demuestra que $2^n > n^2$ para todo $n \geq 5$. *(La base es $n=5$, no $n=1$.)*
- [ ] **E3.** Usa la desigualdad de Bernoulli para demostrar que $\left(1 + \frac{1}{n}\right)^n$ es creciente.
- [ ] **E4.** Demuestra por inducción que $n! \geq 2^{n-1}$ para todo $n \geq 1$.
- [ ] **E5 (Trading).** Sea $r$ el retorno diario constante de un EA y $B_n = B_0(1+r)^n$ el balance después de $n$ días. Demuestra por inducción que $B_n = B_0(1+r)^n$. *(Aunque parece obvio, el ejercicio entrena la estructura formal.)*
- [ ] **E6.** Demuestra que $1 + 2 + 4 + \cdots + 2^{n-1} = 2^n - 1$ para todo $n \geq 1$.
