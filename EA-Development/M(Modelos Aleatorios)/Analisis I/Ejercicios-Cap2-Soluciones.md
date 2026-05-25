---
tags: [analisis, rudin, cap2, topologia, ejercicios, soluciones]
refs: [Rudin Cap. 2 — Ejercicios 1–17 (selección)]
---

# Ejercicios Capítulo 2 — Topología Básica (Rudin)

> Prerequisito: [[Sesion-01-Numeros-Reales]] · [[Sesion-02-Campo-Real]]
> Lee en Reading View: `Ctrl + E`

---

## Contexto del capítulo

El Capítulo 2 de Rudin construye el **lenguaje topológico** que hace posible hablar de límites, continuidad y convergencia de forma rigurosa. Los conceptos clave son:

| Concepto | Significado intuitivo |
|----------|-----------------------|
| Espacio métrico $(X, d)$ | Conjunto con noción de distancia |
| Vecindad $N_r(p)$ | Bola abierta de radio $r$ alrededor de $p$ |
| Punto límite | Todo vecindario contiene puntos del conjunto distintos de él |
| Conjunto abierto | Cada punto es interior (tiene una bola entera dentro) |
| Conjunto cerrado | Contiene todos sus puntos límite |
| Compacto | Toda cubierta abierta tiene una subcubierta finita |
| Conexo | No puede dividirse en dos abiertos disjuntos no vacíos |

La distancia estándar en $\mathbb{R}$ es $d(x, y) = |x - y|$. En $\mathbb{R}^k$ es la distancia euclidiana.

---

## Ejercicio 1

> **Enunciado:** Demuestra que el conjunto vacío $\emptyset$ es subconjunto de cada conjunto.

### Demostración

La definición de $A \subset B$ (Rudin Def. 2.1) es:

$$A \subset B \iff \forall\, x \in A,\quad x \in B$$

Para $A = \emptyset$: la afirmación "$\forall\, x \in \emptyset,\ x \in B$" es **vacuamente verdadera** — no existe ningún $x \in \emptyset$ que la pueda falsificar.

Por lo tanto $\emptyset \subset B$ para cualquier conjunto $B$. $\blacksquare$

### ¿Qué significa "vacuamente verdadero"?

Una proposición de la forma "para todo $x$ con propiedad $P$, ocurre $Q$" es verdadera si no existe ningún $x$ con la propiedad $P$. No hay contraejemplo posible.

Analogía: "Todos los trades que duran 1000 años tienen RR > 2" es verdadera — porque no existe ninguno.

---

## Ejercicio 2

> **Enunciado:** Un número complejo $z$ es **algebraico** si existen enteros $a_0, a_1, \ldots, a_n$ (no todos cero) tales que $a_0 z^n + a_1 z^{n-1} + \cdots + a_n = 0$. Demuestra que el conjunto de todos los números algebraicos es **numerable**.

### Contexto

Todo entero, racional, $\sqrt{2}$, $\sqrt[3]{5}$, $i$, $e^{i\pi}$ es algebraico. Los trascendentes ($\pi$, $e$, la mayoría de los reales) no lo son.

### Demostración

**Paso 1 — Polinomios de grado $n$ con altura $N$.**

Para cada entero positivo $N$, define el conjunto de polinomios con coeficientes enteros tales que:

$$n + |a_0| + |a_1| + \cdots + |a_n| = N$$

Hay un número **finito** de ellos (hay finitas formas de escribir un entero como suma finita de enteros no negativos).

Cada polinomio tiene a lo más $n \leq N$ raíces complejas.

Por lo tanto, el conjunto de raíces algebraicas que provienen de polinomios con altura $N$ es **finito**.

**Paso 2 — El conjunto total es unión numerable de conjuntos finitos.**

El conjunto de todos los algebraicos es:

$$\text{Alg} = \bigcup_{N=1}^{\infty} \{\text{raíces de polinomios con altura } N\}$$

Cada término de la unión es finito. Una **unión numerable de conjuntos finitos es numerable** (Rudin Teo. 2.12).

Por lo tanto $\text{Alg}$ es numerable. $\blacksquare$

---

## Ejercicio 3

> **Enunciado:** Demuestra que existen números reales que no son algebraicos (números trascendentes).

### Demostración

Por el Ejercicio 2, el conjunto de algebraicos es numerable. Pero $\mathbb{R}$ es **no numerable** (Rudin Teo. 2.43 — el argumento de la diagonal de Cantor).

Si todos los reales fueran algebraicos, $\mathbb{R}$ sería numerable. Contradicción.

Por lo tanto, existen reales no algebraicos — los **números trascendentes**. $\blacksquare$

### Nota histórica

$\pi$ y $e$ son trascendentes (probado en 1882 y 1873 respectivamente). La demostración del Ejercicio 3 prueba que existen, pero no construye ninguno explícitamente. Es una demostración de existencia pura.

---

## Ejercicio 4

> **Enunciado:** ¿Es numerable el conjunto de todos los números reales irracionales?

### Respuesta: No. El conjunto de los irracionales es **no numerable**.

### Demostración

Supón por contradicción que $\mathbb{R} \setminus \mathbb{Q}$ es numerable. Entonces:

$$\mathbb{R} = \mathbb{Q} \cup (\mathbb{R} \setminus \mathbb{Q})$$

es unión de dos conjuntos numerables. Una unión numerable de numerables es numerable (Teo. 2.12). Entonces $\mathbb{R}$ sería numerable.

Pero $\mathbb{R}$ es no numerable (Cantor). Contradicción.

Por lo tanto $\mathbb{R} \setminus \mathbb{Q}$ es **no numerable**. $\blacksquare$

### Interpretación

Aunque $\mathbb{Q}$ es denso en $\mathbb{R}$ (hay racionales en cada intervalo), los irracionales son "casi todos" los reales en el sentido de cardinalidad. Los racionales son una fracción de medida cero.

### Analogía — Precios

Los precios cotizados son racionales (finitos decimales). Los precios "teóricos" de derivados (valuación Black-Scholes, por ejemplo) son irracionales con probabilidad 1. En la práctica los redondeamos — pero la matemática dice que los valores exactos son trascendentes casi siempre.

---

## Ejercicio 5

> **Enunciado:** Construye un conjunto acotado de números reales que tenga **exactamente tres puntos límite**.

### Construcción

Sea:

$$E = \left\{\frac{1}{3} + \frac{1}{n} : n \in \mathbb{N}\right\} \cup \left\{\frac{2}{3} + \frac{1}{n} : n \in \mathbb{N}\right\} \cup \left\{1 + \frac{1}{n} : n \in \mathbb{N}\right\}$$

### ¿Cuáles son los puntos límite?

Para cada familia $\{c + 1/n : n \in \mathbb{N}\}$ con $c \in \{1/3, 2/3, 1\}$:

- La sucesión $c + 1/n \to c$ cuando $n \to \infty$.
- Toda vecindad de $c$ contiene infinitos puntos de la familia.
- $c$ es punto límite de $E$.
- Los puntos $c + 1/n$ son **aislados** — no son puntos límite de $E$ entre sí.

Los únicos puntos límite son exactamente $\{1/3, 2/3, 1\}$.

$E$ está acotado (todos los elementos pertenecen a $(1/3, 2]$). $\blacksquare$

### Generalización

Para $k$ puntos límite: toma $k$ sucesiones $\{c_i + 1/n\}$ con centros $c_i$ distintos.

---

## Ejercicio 6

> **Enunciado:** Si $E'$ es el conjunto de todos los puntos límite de $E$, demuestra que $E'$ es cerrado. Demuestra también que $E$ y $\bar{E}$ tienen los mismos puntos límite.

### Parte 1 — $E'$ es cerrado

Debemos probar que $E'$ contiene todos sus puntos límite. Sea $x$ un punto límite de $E'$.

Tomemos cualquier $r > 0$. En $N_r(x)$ existe un punto $y \in E'$ con $y \neq x$.

Como $y \in E'$, $y$ es punto límite de $E$. Toda vecindad de $y$ contiene un punto de $E$.

Sea $h = r - d(x, y) > 0$. La vecindad $N_h(y)$ contiene un punto $z \in E$ con $z \neq y$.

Por desigualdad triangular:

$$d(x, z) \leq d(x, y) + d(y, z) < d(x, y) + h = r$$

Entonces $z \in N_r(x)$ y $z \in E$. Verificar que $z \neq x$: si $z = x$, entonces $x \in E$, y como $y \in E'$ con $y \neq x$, ya que $y \in N_r(x)$, en todo caso $N_r(x)$ contiene puntos de $E$ distintos de $x$.

En cualquier caso, $N_r(x)$ contiene puntos de $E$ distintos de $x$, para todo $r > 0$.

Por lo tanto $x \in E'$, y $E'$ es cerrado. $\blacksquare$

### Parte 2 — $E$ y $\bar{E} = E \cup E'$ tienen los mismos puntos límite

Sea $x$ punto límite de $\bar{E}$. Queremos ver que $x$ es punto límite de $E$.

Para todo $r > 0$, existe $y \in \bar{E}$, $y \neq x$, con $y \in N_r(x)$.

**Caso 1:** $y \in E$. Entonces $N_r(x)$ contiene $y \in E$ con $y \neq x$.

**Caso 2:** $y \in E'$ pero $y \notin E$. Como $y$ es punto límite de $E$, en $N_h(y)$ (con $h = r - d(x,y)$) hay un $z \in E$, $z \neq y$, y por triangular $z \in N_r(x)$.

En ambos casos, $N_r(x)$ contiene puntos de $E$ distintos de $x$. Luego $x \in E'$.

La inclusión $E' \subset (\bar{E})'$ es obvia. Por lo tanto $(E)' = (\bar{E})'$. $\blacksquare$

---

## Ejercicio 8

> **Enunciado:** ¿Es cada punto de cada conjunto abierto $E \subset \mathbb{R}^2$ un punto límite de $E$? Responder la misma pregunta para conjuntos cerrados en $\mathbb{R}^2$.

### Abiertos: Sí

Si $E$ es abierto y $p \in E$, existe $r > 0$ tal que $N_r(p) \subset E$. Toda vecindad $N_\varepsilon(p)$ (con $\varepsilon \leq r$) contiene infinitos puntos de $N_r(p) \subset E$ distintos de $p$ (en $\mathbb{R}^2$ toda bola es infinita). Luego $p$ es punto límite de $E$. $\blacksquare$

### Cerrados: No necesariamente

**Contraejemplo:** $E = \{p\}$ (un solo punto). $E$ es cerrado (toda sucesión convergente en $E$ está en $E$). Pero $p$ no es punto límite de $E$ — su vecindad $N_r(p)$ no contiene ningún punto de $E$ distinto de $p$.

Los puntos de un cerrado que no son puntos límite se llaman **puntos aislados**.

---

## Ejercicio 9

> **Enunciado:** Sea $E^\circ$ el conjunto de todos los puntos interiores de $E$ (el interior de $E$).
>
> (a) Demuestra que $E^\circ$ es siempre abierto.
> (b) Demuestra que $E$ es abierto si y solo si $E^\circ = E$.
> (c) Si $G \subset E$ y $G$ es abierto, demuestra que $G \subset E^\circ$.
> (d) Demuestra que el complemento de $E^\circ$ es la cerradura del complemento de $E$.

### (a) $E^\circ$ es abierto

Sea $p \in E^\circ$. Existe $r > 0$ con $N_r(p) \subset E$.

Para cualquier $q \in N_r(p)$, sea $h = r - d(p,q) > 0$. Entonces $N_h(q) \subset N_r(p) \subset E$, así que $q \in E^\circ$.

Luego $N_r(p) \subset E^\circ$, es decir $p$ es interior a $E^\circ$. Como esto vale para todo $p \in E^\circ$, $E^\circ$ es abierto. $\blacksquare$

### (b) $E$ abierto $\iff$ $E^\circ = E$

**($\Rightarrow$)** Si $E$ es abierto, todo $p \in E$ es interior a $E$, luego $E \subset E^\circ$. Siempre $E^\circ \subset E$ por definición. Luego $E^\circ = E$.

**($\Leftarrow$)** Si $E^\circ = E$, entonces $E = E^\circ$ es abierto por (a). $\blacksquare$

### (c) $G \subset E$, $G$ abierto $\Rightarrow$ $G \subset E^\circ$

Sea $p \in G$. Como $G$ es abierto, existe $r > 0$ con $N_r(p) \subset G \subset E$. Luego $p \in E^\circ$.

Por tanto $G \subset E^\circ$. $\blacksquare$

**Conclusión:** $E^\circ$ es el **mayor abierto contenido en $E$**.

### (d) $(E^\circ)^c = \overline{E^c}$

Sea $p \in (E^\circ)^c$. Entonces $p \notin E^\circ$: ninguna vecindad de $p$ está contenida en $E$.

Esto significa que toda vecindad $N_r(p)$ contiene puntos de $E^c$. Hay dos subcasos:

- Si $p \in E^c$: $p \in \overline{E^c}$ trivialmente.
- Si $p \in E$: toda vecindad de $p$ contiene puntos de $E^c$ distintos de $p$, luego $p$ es punto límite de $E^c$, y $p \in \overline{E^c}$.

En ambos casos $p \in \overline{E^c}$. La inclusión inversa es análoga. $\blacksquare$

---

## Ejercicio 12

> **Enunciado:** Si $K \subset \mathbb{R}^1$ consta de $0$ y los números $1/n$ para $n = 1, 2, 3, \ldots$, demuestra que $K$ es compacto directamente de la definición.

### $K = \{0, 1, 1/2, 1/3, 1/4, \ldots\}$

Para probar compacidad desde la definición debemos mostrar: **toda cubierta abierta de $K$ tiene una subcubierta finita**.

Sea $\{G_\alpha\}$ una cubierta abierta arbitraria de $K$.

**Paso 1:** El $0 \in K$ debe estar cubierto. Existe $G_{\alpha_0}$ con $0 \in G_{\alpha_0}$. Como $G_{\alpha_0}$ es abierto, existe $r > 0$ con $(-r, r) \subset G_{\alpha_0}$.

**Paso 2:** Solo hay un número finito de enteros $n$ con $1/n \geq r$ (equivalentemente, $n \leq 1/r$). Sean $n_1 = 1, n_2 = 2, \ldots, n_M = \lfloor 1/r \rfloor$ esos índices.

**Paso 3:** Cada punto $1/n_j$ (para $j = 1, \ldots, M$) está en algún $G_{\alpha_j}$ de la cubierta.

**Conclusión:** La colección finita $\{G_{\alpha_0}, G_{\alpha_1}, \ldots, G_{\alpha_M}\}$ cubre a $K$:
- $G_{\alpha_0}$ cubre $\{0\} \cup \{1/n : n > 1/r\}$ (todos los "pequeños").
- $G_{\alpha_1}, \ldots, G_{\alpha_M}$ cubren los finitos "grandes".

Como toda cubierta abierta tiene una subcubierta finita, $K$ es compacto. $\blacksquare$

### ¿Por qué el $0$ es indispensable?

Sin el $0$, el conjunto $\{1/n : n \in \mathbb{N}\}$ no es compacto. La cubierta $\{(1/(n+1), 1) : n \in \mathbb{N}\}$ cubre cada $1/n$ pero no tiene subcubierta finita — cada abierto tapa solo un punto.

El $0$ es el **único punto límite** de $K$. Rudin usa este ejemplo para ilustrar que un compacto debe contener todos sus puntos límite.

---

## Ejercicio 16

> **Enunciado:** Considera $\mathbb{Q}$ con $d(p,q) = |p-q|$ como espacio métrico. Sea $E = \{p \in \mathbb{Q} : 2 < p^2 < 3\}$. Muestra que $E$ es cerrado y acotado en $\mathbb{Q}$, pero que $E$ no es compacto. ¿Es $E$ abierto en $\mathbb{Q}$?

### Acotado

$p^2 < 3$ implica $|p| < \sqrt{3} < 2$. Todos los elementos de $E$ cumplen $|p| < 2$, así que $E \subset (-2,2)$. $E$ es acotado. $\blacksquare$

### Cerrado en $\mathbb{Q}$

El complemento de $E$ en $\mathbb{Q}$ es:

$$E^c = \{p \in \mathbb{Q} : p^2 \leq 2\} \cup \{p \in \mathbb{Q} : p^2 \geq 3\}$$

Un punto límite de $E^c$ (en $\mathbb{Q}$) también cumple $p^2 \leq 2$ o $p^2 \geq 3$ (pues $\sqrt{2}$ y $\sqrt{3}$ no están en $\mathbb{Q}$). Luego $E^c$ es cerrado, y $E$ es abierto... wait.

Replanteemos: $E = \{p \in \mathbb{Q} : \sqrt{2} < p < \sqrt{3}\}$.

$E$ es **abierto** en $\mathbb{Q}$: para cada $p \in E$, sea $r = \min(p - \sqrt{2}, \sqrt{3} - p) > 0$ (positivo porque $p \neq \sqrt{2}, \sqrt{3} \in \mathbb{Q}$ — o mejor dicho, $\sqrt{2} \notin \mathbb{Q}$ y $\sqrt{3} \notin \mathbb{Q}$, así que la distancia de $p$ a estos puntos no puede ser cero en $\mathbb{Q}$). La vecindad $N_r(p) \cap \mathbb{Q} \subset E$.

$E$ también es **cerrado** en $\mathbb{Q}$: los únicos posibles puntos límite de $E$ en $\mathbb{Q}$ son aquellos cuadraduras con $p^2 = 2$ o $p^2 = 3$, pero esos no existen en $\mathbb{Q}$. Todos los puntos límite de $E$ (en $\mathbb{Q}$) pertenecen a $E$.

### No compacto

La cubierta $\{(\sqrt{2} + 1/n, \sqrt{3}) \cap \mathbb{Q} : n = 1, 2, 3, \ldots\}$ cubre $E$ pero no tiene subcubierta finita (ningún número finito de estos intervalos cubre toda $E$).

### Conclusión — Por qué importa

Este ejercicio muestra que **en $\mathbb{Q}$, el Teorema de Heine-Borel falla**: ser cerrado y acotado no implica compacto. Heine-Borel vale solo en $\mathbb{R}^k$ (espacio completo). Los "huecos" de $\mathbb{Q}$ en los irracionales $\sqrt{2}$ y $\sqrt{3}$ son precisamente la causa.

### Analogía — Mercados discontinuos

En un mercado de precios discretos (como $\mathbb{Q}$), cerrado y acotado no garantiza que un proceso de precios alcance su supremo. Es el mismo problema: el supremo podría ser irracional ($\sqrt{3}$ aquí). La completitud de $\mathbb{R}$ es la propiedad que garantiza que los precios alcancen sus extremos en problemas de optimización. $\blacksquare$

---

## Ejercicio 17

> **Enunciado:** Sea $E$ el conjunto de todos los $x \in [0,1]$ cuya expansión decimal contiene únicamente los dígitos 4 y 7. ¿Es numerable $E$? ¿Es denso en $[0,1]$? ¿Es compacto? ¿Es perfecto?

### ¿Numerable? No — es **no numerable**

Cada elemento de $E$ es una sucesión infinita de decisiones binarias (4 ó 7 en cada decimal). Hay $2^{\aleph_0} = |\mathbb{R}|$ tales sucesiones. Por el argumento diagonal de Cantor, no es numerable. $\blacksquare$

### ¿Denso en $[0,1]$? No

El intervalo $(0.5, 0.6)$ no contiene ningún elemento de $E$ (los elementos de $E$ tienen primer decimal 4 ó 7, nunca 5). $E$ no es denso. $\blacksquare$

### ¿Compacto? Sí

$E \subset [0,1]$ es acotado. Solo falta ver que $E$ es cerrado.

Supón que $x_n \in E$ y $x_n \to x$. Para cada posición decimal $k$, el $k$-ésimo dígito de $x_n$ es 4 ó 7 para todo $n$. En el límite, el $k$-ésimo dígito de $x$ también es 4 ó 7 (a menos que haya carry, pero con solo 4 y 7 no hay carry). Luego $x \in E$.

$E$ es cerrado y acotado en $\mathbb{R}$, luego compacto por Heine-Borel. $\blacksquare$

### ¿Perfecto? Sí

$E$ es compacto. Falta ver que $E$ no tiene puntos aislados, es decir, que todo punto de $E$ es punto límite de $E$.

Sea $x \in E$ con expansión $x = 0.d_1 d_2 d_3 \ldots$ donde cada $d_k \in \{4, 7\}$.

Define $x_n$ cambiando el $n$-ésimo dígito de $x$: si $d_n = 4$ pon 7, si $d_n = 7$ pon 4. Entonces $x_n \in E$ y $|x_n - x| = |d_n^{(x_n)} - d_n^{(x)}| / 10^n = 3/10^n \to 0$.

Por lo tanto $x$ es punto límite de $\{x_n\}_{n \geq 1} \subset E$. $E$ es perfecto. $\blacksquare$

### Conexión con el Conjunto de Cantor

$E$ es homeomorfo al Conjunto de Cantor: ambos son compactos perfectos no numerables sin puntos interiores. La construcción con dígitos 4 y 7 es una versión "decimal" del Conjunto de Cantor ternario (con dígitos 0 y 2 en base 3).

---

## Resumen — Propiedades topológicas clave

| Concepto | Definición clave | Ejemplo en $\mathbb{R}$ |
|----------|-----------------|------------------------|
| Abierto | Todo punto es interior | $(a, b)$ |
| Cerrado | Contiene todos sus puntos límite | $[a, b]$ |
| Compacto | Toda cubierta abierta tiene subcubierta finita | $[a, b]$ ✓, $(a,b)$ ✗ |
| Perfecto | Cerrado + sin puntos aislados | Conjunto de Cantor |
| Conexo | No se puede partir en dos abiertos disjuntos | Intervalos en $\mathbb{R}$ |
| Denso | Cada punto del espacio es punto límite del conjunto | $\mathbb{Q}$ en $\mathbb{R}$ |

### Teorema de Heine-Borel (Rudin Teo. 2.41)

> En $\mathbb{R}^k$: $E$ es compacto $\iff$ $E$ es cerrado y acotado.

**¡Esto falla en $\mathbb{Q}$!** (Ejercicio 16 lo ilustra.)

---

## Ejercicios de práctica

- [ ] **P1.** Demuestra que la unión finita de compactos es compacta. ¿Vale para unión infinita?
- [ ] **P2.** Demuestra que la intersección arbitraria de compactos es compacta.
- [ ] **P3.** Da un ejemplo de un conjunto cerrado en $\mathbb{R}$ que no sea compacto.
- [ ] **P4.** ¿Es $\{0\} \cup \{1/n\}$ perfecto? Justifica.
- [ ] **P5.** Demuestra que todo conjunto finito de puntos en $\mathbb{R}^k$ es compacto.
- [ ] **P6 (Trading).** Sea $E$ el conjunto de todos los cierres diarios del NAS100 en un año dado. ¿Qué propiedades topológicas tiene $E$? ¿Es compacto? ¿Es cerrado? ¿Tiene puntos límite?
