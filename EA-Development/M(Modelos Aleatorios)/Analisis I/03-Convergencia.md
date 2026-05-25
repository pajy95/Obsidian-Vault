---
tags: [analisis, rudin, cap3, convergencia, cauchy, series]
refs: [Rudin Cap. 3 — Secs. 3.1–3.12]
---

# Sesión — Convergencia de Sucesiones

> Prerequisito: [[02-Sucesiones]]
> Lee en Reading View: `Ctrl + E`

---

## 1. La definición $\varepsilon$-$N$ en detalle

### Definición (Rudin Def. 3.1)

$$\lim_{n \to \infty} a_n = L \iff \forall\, \varepsilon > 0,\quad \exists\, N \in \mathbb{N} : n > N \Rightarrow |a_n - L| < \varepsilon$$

### Cómo leer esto

La definición es un **juego entre dos jugadores**:

1. **Tu adversario** elige un $\varepsilon > 0$ arbitrariamente pequeño — el margen de error que exige.
2. **Tú** debes responder con un $N$ tal que a partir del término $N+1$, todos los términos están dentro del margen $\varepsilon$.

Si puedes responder para **cualquier** $\varepsilon$ que él elija, la sucesión converge.

### Ejemplo completo — $a_n = \frac{1}{n} \to 0$

**Afirmación:** $\lim_{n \to \infty} \frac{1}{n} = 0$.

**Demostración:** Sea $\varepsilon > 0$ dado. Por la Propiedad Arquimediana (Teo. 1.20a), existe $N \in \mathbb{N}$ con $N > 1/\varepsilon$.

Entonces para $n > N$:

$$\left|\frac{1}{n} - 0\right| = \frac{1}{n} < \frac{1}{N} < \varepsilon \quad \blacksquare$$

**Notar:** el $N$ que elegimos depende de $\varepsilon$. Para $\varepsilon = 0.01$ tomo $N = 100$. Para $\varepsilon = 0.001$ tomo $N = 1000$. Eso es exactamente lo que la definición pide.

---

### Ejemplo completo — $a_n = \frac{2n+1}{n} \to 2$

**Afirmación:** $\lim_{n \to \infty} \frac{2n+1}{n} = 2$.

**Demostración:** Calcula el error:

$$\left|\frac{2n+1}{n} - 2\right| = \left|\frac{2n+1 - 2n}{n}\right| = \frac{1}{n}$$

Sea $\varepsilon > 0$. Toma $N > 1/\varepsilon$. Entonces $n > N \Rightarrow \frac{1}{n} < \varepsilon$. $\blacksquare$

---

## 2. Convergencia no implica velocidad fija

Dos sucesiones pueden converger al mismo límite a velocidades muy distintas:

| Sucesión | Límite | Error en $n=100$ | Error en $n=1000$ |
|----------|--------|-------------------|-------------------|
| $1/n$ | $0$ | $0.01$ | $0.001$ |
| $1/n^2$ | $0$ | $0.0001$ | $0.000001$ |
| $1/\ln n$ | $0$ | $\approx 0.217$ | $\approx 0.145$ |

La sucesión $1/\ln n$ converge **extremadamente lento**. Esto importa en la práctica: una sucesión puede converger "en teoría" pero tardar millones de términos en acercarse.

---

## 3. Teorema del Emparedado (Sandwich)

> **Teorema:** Si $a_n \leq b_n \leq c_n$ para todo $n$ suficientemente grande, y si $a_n \to L$ y $c_n \to L$, entonces $b_n \to L$.

### Demostración

Sea $\varepsilon > 0$. Existen $N_1, N_2$ con:

- $n > N_1 \Rightarrow |a_n - L| < \varepsilon \Rightarrow L - \varepsilon < a_n < L + \varepsilon$
- $n > N_2 \Rightarrow |c_n - L| < \varepsilon \Rightarrow L - \varepsilon < c_n < L + \varepsilon$

Para $n > N = \max(N_1, N_2)$:

$$L - \varepsilon < a_n \leq b_n \leq c_n < L + \varepsilon$$

Luego $|b_n - L| < \varepsilon$. $\blacksquare$

### Aplicación clásica

¿Cuánto vale $\lim_{n \to \infty} \frac{\sin n}{n}$?

Como $-1 \leq \sin n \leq 1$ para todo $n$:

$$-\frac{1}{n} \leq \frac{\sin n}{n} \leq \frac{1}{n}$$

Como $-1/n \to 0$ y $1/n \to 0$, por el emparedado: $\frac{\sin n}{n} \to 0$.

---

## 4. Sucesiones Divergentes — Tipos

### Divergencia a $+\infty$

$s_n \to +\infty$ si para todo $M \in \mathbb{R}$, existe $N$ con $n > N \Rightarrow s_n > M$.

Ejemplo: $s_n = n^2$. Para cualquier $M$, toma $N > \sqrt{M}$.

### Divergencia oscilante

Ejemplo: $s_n = (-1)^n$. La sucesión rebota entre $-1$ y $+1$. No diverge a infinito, pero tampoco converge. Tiene $\limsup = 1$, $\liminf = -1$.

### Cómo demostrar que $a_n$ NO converge

Si sospechas que $\{a_n\}$ no converge, demuestra que $\limsup \neq \liminf$, o exhibe dos subsucesiones con límites distintos.

---

## 5. Criterio de Cauchy — Convergencia sin Conocer el Límite

### Problema práctico

A veces sabes que una sucesión "debería converger" (se va estabilizando) pero no sabes a qué valor exactamente. El criterio de Cauchy resuelve esto.

### Definición de Sucesión de Cauchy (Rudin Def. 3.8)

$$\forall\, \varepsilon > 0,\quad \exists\, N : m, n > N \Rightarrow |a_m - a_n| < \varepsilon$$

Los términos de la sucesión se acercan entre sí, sin referencia a ningún límite.

### Teorema de Cauchy en $\mathbb{R}$ (Rudin Teo. 3.11c)

$$\{a_n\} \text{ converge en } \mathbb{R} \iff \{a_n\} \text{ es de Cauchy}$$

### Demostración $(\Rightarrow)$

Si $a_n \to L$, dado $\varepsilon > 0$ existe $N$ con $n > N \Rightarrow |a_n - L| < \varepsilon/2$.

Para $m, n > N$:

$$|a_m - a_n| \leq |a_m - L| + |L - a_n| < \frac{\varepsilon}{2} + \frac{\varepsilon}{2} = \varepsilon \quad \blacksquare$$

### Por qué falla en $\mathbb{Q}$

La sucesión $3,\ 3.1,\ 3.14,\ 3.141,\ 3.1415,\ldots$ (aproximaciones decimales de $\pi$) es de Cauchy en $\mathbb{Q}$. Pero su límite es $\pi \notin \mathbb{Q}$. En $\mathbb{Q}$ la sucesión de Cauchy **no converge** — porque $\mathbb{Q}$ no es completo. En $\mathbb{R}$ sí converge.

---

## 6. Convergencia y Álgebra — Resumen Completo

Sean $a_n \to A$ y $b_n \to B$. Entonces:

$$\lim(a_n \pm b_n) = A \pm B$$
$$\lim(a_n \cdot b_n) = A \cdot B$$
$$\lim\frac{a_n}{b_n} = \frac{A}{B} \quad (\text{si } B \neq 0 \text{ y } b_n \neq 0 \text{ para todo } n)$$
$$\lim|a_n| = |A|$$

Y para funciones continuas $f$: si $a_n \to A$ y $f$ es continua en $A$, entonces $f(a_n) \to f(A)$.

### Aplicación — Límite de expresiones racionales

$$\lim_{n \to \infty} \frac{3n^2 - 2n + 1}{5n^2 + 4} = \lim_{n \to \infty} \frac{3 - 2/n + 1/n^2}{5 + 4/n^2} = \frac{3 - 0 + 0}{5 + 0} = \frac{3}{5}$$

Dividir numerador y denominador por $n^2$ (el término dominante), luego aplicar álgebra de límites.

---

## 7. Convergencia en $\mathbb{R}^k$ — Componente a Componente (Rudin Teo. 3.4)

Para vectores $\mathbf{x}_n = (x_{1,n}, \ldots, x_{k,n}) \in \mathbb{R}^k$:

$$\mathbf{x}_n \to \mathbf{x} = (x_1, \ldots, x_k) \iff x_{j,n} \to x_j \text{ para cada } j = 1, \ldots, k$$

Convergencia en $\mathbb{R}^k$ es exactamente convergencia coordenada a coordenada.

### Analogía — Portfolio multidimensional

Un portfolio de $k$ activos es un vector de posiciones. Que el portfolio "converja a un estado estacionario" es equivalente a que cada posición individual converja por separado.

---

## 8. Resumen de Criterios de Convergencia

| Criterio | Condición | Aplicabilidad |
|----------|-----------|---------------|
| Definición $\varepsilon$-$N$ | Encontrar $N$ en función de $\varepsilon$ | Siempre, pero puede ser difícil |
| Monotonicidad + acotación | Sucesión monótona y acotada | Solo sucesiones monótonas |
| Teorema emparedado | Acotar entre dos sucesiones convergentes | Cuando se puede acotar bien |
| Criterio de Cauchy | Probar que términos se acercan entre sí | Cuando no se conoce el límite |
| Álgebra de límites | Reducir a límites conocidos | Expresiones algebraicas |

---

## Ejercicios

- [ ] **E1.** Demuestra que $\lim_{n\to\infty} \frac{n}{n+1} = 1$ usando la definición $\varepsilon$-$N$.
- [ ] **E2.** Demuestra que $\lim_{n\to\infty} \frac{n^2}{2n^2 + 3n - 1} = \frac{1}{2}$.
- [ ] **E3.** Muestra que la sucesión $a_n = \cos(n\pi)$ diverge. Identifica $\limsup$ y $\liminf$.
- [ ] **E4.** Sea $a_1 = 1$ y $a_{n+1} = \frac{1}{2}\left(a_n + \frac{2}{a_n}\right)$. Demuestra que $\{a_n\}$ converge y encuentra el límite. *(Pista: es el método de Newton para $\sqrt{2}$.)*
- [ ] **E5 (Cauchy).** Demuestra que $a_n = \sum_{k=1}^{n} \frac{(-1)^k}{k}$ es de Cauchy sin calcular su límite.
- [ ] **E6 (Trading).** Los cierres diarios del NAS100 forman la sucesión $\{p_n\}$. Sea $M_n = \frac{1}{n}\sum_{k=1}^n p_k$ la media móvil simple. Si $p_n \to L$, demuestra que $M_n \to L$. *(Pista: para $\varepsilon$ dado, separa los primeros $N$ términos de los restantes.)*
