---
tags: [analisis, rudin, cap3, sucesiones, monotona, limsup, liminf]
refs: [Rudin Cap. 3 — Secs. 3.1–3.17]
---

# Sesión — Sucesiones Monótonas, Supremo e Ínfimo

> Prerequisito: [[Sesion-01-Numeros-Reales]] · [[Sesion-02-Campo-Real]]
> Lee en Reading View: `Ctrl + E`

---

## 1. ¿Por qué estudiar sucesiones?

Una **sucesión** es la estructura mínima para hablar de "proceso que avanza". Todo en análisis — límites, continuidad, derivadas, integrales — se puede reducir a sucesiones. El libro de Rudin las introduce en el Cap. 3 como puente entre la topología del Cap. 2 y el análisis del Cap. 4 en adelante.

En trading: cada precio de cierre es un término de una sucesión. La pregunta "¿converge la media móvil?" es exactamente la misma que "¿converge esta sucesión?".

---

## 2. Definición de Sucesión Convergente (Rudin Def. 3.1)

Sea $X$ un espacio métrico con distancia $d$. Se dice que la sucesión $\{p_n\}$ en $X$ **converge** si existe un punto $p \in X$ tal que:

$$\forall\, \varepsilon > 0,\quad \exists\, N \in \mathbb{N} : n > N \Rightarrow d(p_n, p) < \varepsilon$$

En este caso escribimos $p_n \to p$ o $\lim_{n \to \infty} p_n = p$.

Si no converge, **diverge**.

### Comentario crítico de Rudin

La convergencia depende del espacio $X$ en que vive la sucesión. Ejemplo: la sucesión $\{1/n\}$:
- Converge a $0$ en $\mathbb{R}^1$ (porque $0 \in \mathbb{R}$).
- **No converge** en $(0, +\infty)$ — porque $0$ no pertenece a ese espacio, y no hay ningún punto de $(0,+\infty)$ al que tiendan.

Este matiz es fundamental: cuando dices "converge", siempre debes especificar "¿en qué espacio?".

---

## 3. Propiedades de Sucesiones Convergentes (Rudin Teo. 3.2)

Sea $\{p_n\}$ una sucesión en el espacio métrico $X$.

| Propiedad | Enunciado |
|-----------|-----------|
| **Caracterización vecinal** | $p_n \to p \iff$ toda vecindad de $p$ contiene todos los $p_n$ salvo finitos |
| **Unicidad del límite** | Si $p_n \to p$ y $p_n \to p'$, entonces $p = p'$ |
| **Acotación** | Si $\{p_n\}$ converge, entonces es acotada |
| **Punto límite** | Si $p$ es punto límite de $E \subset X$, existe una sucesión en $E$ que converge a $p$ |

### Demostración de unicidad

Sean $p \neq p'$ dos límites candidatos con $d(p, p') = \delta > 0$. Toma $\varepsilon = \delta/2$. Existen $N_1, N_2$ con:

$$n > N_1 \Rightarrow d(p_n, p) < \frac{\delta}{2}, \qquad n > N_2 \Rightarrow d(p_n, p') < \frac{\delta}{2}$$

Para $n > \max(N_1, N_2)$, por desigualdad triangular:

$$\delta = d(p, p') \leq d(p, p_n) + d(p_n, p') < \frac{\delta}{2} + \frac{\delta}{2} = \delta$$

Contradicción. Por tanto $p = p'$. $\blacksquare$

---

## 4. Álgebra de Límites (Rudin Teo. 3.3)

Si $s_n \to s$ y $t_n \to t$ (sucesiones complejas), entonces:

$$\lim_{n\to\infty}(s_n + t_n) = s + t$$
$$\lim_{n\to\infty} s_n t_n = s \cdot t$$
$$\lim_{n\to\infty} \frac{s_n}{t_n} = \frac{s}{t} \quad \text{(si } t \neq 0 \text{ y } t_n \neq 0 \text{ para todo } n\text{)}$$

### Idea de la demostración del producto

Usa la identidad algebraica:

$$s_n t_n - st = (s_n - s)(t_n - t) + s(t_n - t) + t(s_n - s)$$

Cada término tiende a cero: los tres juntos también. La identidad "descompone el error del producto en errores individuales".

### Analogía — Retorno compuesto

Si $s_n \to s$ (precio bid) y $t_n \to t$ (precio ask), el spread $t_n - s_n \to t - s$. Si un EA compra a ask y vende a bid, el costo por trade converge al spread asintótico — esto es la regla del límite de la diferencia.

---

## 5. Sucesiones Monótonas (Rudin Def. 3.13 y Teo. 3.14)

### Definición

Una sucesión $\{s_n\}$ de números reales es:

- **Monótona creciente** si $s_n \leq s_{n+1}$ para todo $n$
- **Monótona decreciente** si $s_n \geq s_{n+1}$ para todo $n$

### Teorema de Convergencia Monótona (Rudin Teo. 3.14)

> **Una sucesión monótona converge si y solo si es acotada.**
>
> Si crece y está acotada superiormente: $\lim s_n = \sup\{s_n : n \in \mathbb{N}\}$
>
> Si decrece y está acotada inferiormente: $\lim s_n = \inf\{s_n : n \in \mathbb{N}\}$

### Demostración (caso creciente)

Sea $E = \{s_n : n \in \mathbb{N}\}$ el rango. Como $\{s_n\}$ es acotada, $E$ está acotado. Sea $s = \sup E$ (existe por el axioma de completitud de $\mathbb{R}$).

Para todo $\varepsilon > 0$: existe $N$ tal que $s - \varepsilon < s_N \leq s$ (pues $s - \varepsilon$ no puede ser cota superior).

Como la sucesión es creciente: $n > N \Rightarrow s_n \geq s_N > s - \varepsilon$.

Además $s_n \leq s$ para todo $n$. Por tanto:

$$s - \varepsilon < s_n \leq s \quad \Rightarrow \quad |s_n - s| < \varepsilon$$

para todo $n > N$. Luego $s_n \to s$. $\blacksquare$

### ¿Por qué este teorema es poderoso?

Porque **no necesitas conocer el límite para probar que existe**. Solo necesitas:
1. La sucesión es monótona (fácil de verificar)
2. La sucesión es acotada (fácil de verificar)
→ Conclusión: el límite existe y es el supremo/ínfimo.

### Analogía — Equity de un EA long-only con stop

Sea $s_n$ = equity del EA después de $n$ trades, con la restricción de que solo abre largos y tiene un stop loss en $s_n \geq s_0 - \text{MaxDD}$. Si el sistema tiene positive expected value, $\{s_n\}$ puede no ser monótona, pero si consideramos la media móvil de $s_n$: si crece consistentemente (como debería un EA viable) y está acotada por el capital máximo del prop firm, el teorema garantiza convergencia.

---

## 6. Límite Superior e Inferior (Rudin Def. 3.16 y Teo. 3.17)

### ¿Por qué se necesitan?

Las sucesiones que no convergen pero tampoco divergen "salvajemente" tienen comportamiento oscilatorio. Los límites superior e inferior capturan los extremos de esa oscilación.

### Definición

Sea $\{s_n\}$ una sucesión de números reales. Sea $E$ el conjunto de todos los posibles límites subsecuenciales (incluyendo $\pm\infty$). Define:

$$\limsup_{n\to\infty} s_n = s^* = \sup E$$
$$\liminf_{n\to\infty} s_n = s_* = \inf E$$

### Propiedades (Rudin Teo. 3.17)

$s^*$ es el **mayor límite subsecuencial**. Tiene dos propiedades caracterizadoras:

**(a)** $s^* \in E$ — es alcanzado por alguna subsucesión.

**(b)** Si $x > s^*$, existe $N$ tal que $n > N \Rightarrow s_n < x$ — eventualmente la sucesión queda por debajo de cualquier número mayor que $s^*$.

Y $s^*$ es el único número con ambas propiedades.

### Ejemplo (Rudin Ej. 3.18a)

Sea $\{s_n\}$ una enumeración de todos los racionales $\mathbb{Q}$. Todo real es límite subsecuencial de $\{s_n\}$ (por densidad de $\mathbb{Q}$). Por tanto:

$$\limsup s_n = +\infty, \qquad \liminf s_n = -\infty$$

### Relación con convergencia

$$\lim_{n\to\infty} s_n = L \iff \limsup s_n = \liminf s_n = L$$

Una sucesión converge exactamente cuando sus oscilaciones "colapsan" a un solo valor.

### Visualización

```
Sucesión oscilante:
  s_n = (-1)^n + 1/n

  n=1: -1 + 1     =  0
  n=2:  1 + 1/2   =  1.5
  n=3: -1 + 1/3   = -0.67
  n=4:  1 + 1/4   =  1.25
  ...

  limsup = 1   (límite de la subsucesión de pares)
  liminf = -1  (límite de la subsucesión de impares)
  No converge (limsup ≠ liminf)
```

---

## 7. Sucesiones de Cauchy (Rudin Def. 3.8 y Teo. 3.11)

### Definición

$\{p_n\}$ es de **Cauchy** si:

$$\forall\, \varepsilon > 0,\quad \exists\, N : m, n > N \Rightarrow d(p_m, p_n) < \varepsilon$$

La diferencia con convergencia: en Cauchy no se menciona el límite. Solo se pide que los términos de la sucesión se acerquen entre sí.

### Teorema (Rudin Teo. 3.11)

| Espacio | Resultado |
|---------|-----------|
| Cualquier espacio métrico | Toda sucesión convergente es de Cauchy |
| Espacio métrico compacto | Toda Cauchy converge |
| $\mathbb{R}^k$ | Toda Cauchy converge (**criterio de Cauchy**) |

### Espacio completo (Rudin Def. 3.12)

Un espacio métrico $X$ es **completo** si toda sucesión de Cauchy en $X$ converge en $X$.

$\mathbb{R}^k$ es completo. $\mathbb{Q}$ **no es completo** — la sucesión $3, 3.1, 3.14, 3.141, 3.1415, \ldots$ es de Cauchy en $\mathbb{Q}$ pero converge a $\pi \notin \mathbb{Q}$.

### Analogía — Backtesting

Un sistema cuyas equity curves en distintas ventanas OOS convergen entre sí (diferencias pequeñas) es como una sucesión de Cauchy: señala que el comportamiento es estable y que existe un "valor verdadero" al que están convergiendo, aunque no conozcas exactamente ese valor.

---

## 8. Subsucesiones y Bolzano-Weierstrass (Rudin Teo. 3.6)

### Definición de subsucesión

Si $n_1 < n_2 < n_3 < \cdots$ son enteros positivos, $\{p_{n_k}\}$ es una **subsucesión** de $\{p_n\}$.

### Teorema de Bolzano-Weierstrass

> **Toda sucesión acotada en $\mathbb{R}^k$ contiene una subsucesión convergente.**

Este resultado es la base de muchas demostraciones de existencia en análisis. No dice que la sucesión converge — dice que **algo dentro de ella** converge.

### Analogía — Señales de trading

Un conjunto de $N$ señales de un EA que no convergen globalmente (ej. mercado en rango caótico) siempre contiene un subconjunto de señales con comportamiento consistente (subsucesión convergente). Bolzano-Weierstrass garantiza que en datos acotados siempre hay patrones extraíbles — la base teórica del aprendizaje automático en finanzas.

---

## 9. Resumen Visual

```
Sucesiones en ℝ:

MONÓTONA + ACOTADA
       ↓
    CONVERGE
  (límite = sup o inf)

ACOTADA (no monótona)
       ↓
  Subsucesión convergente   ← Bolzano-Weierstrass
  limsup y liminf existen

CAUCHY en ℝᵏ
       ↓
    CONVERGE   ← completitud de ℝ

CONVERGE
       ↓
  Cauchy + Acotada + limsup = liminf = límite
```

---

## Ejercicios

- [ ] **E1.** Demuestra que si $a_n \to L$ entonces $|a_n| \to |L|$. ¿Vale el recíproco?
- [ ] **E2.** Sea $a_n = \left(1 + \frac{1}{n}\right)^n$. Demuestra que $\{a_n\}$ es creciente. *(El límite es $e$, pero no hace falta probarlo aquí.)*
- [ ] **E3.** Calcula $\limsup$ y $\liminf$ de $s_n = \frac{(-1)^n \cdot n}{n+1}$.
- [ ] **E4 (Trading).** Sea $r_n$ el retorno del día $n$ de tu EA. Define $S_n = r_1 + r_2 + \cdots + r_n$ (equity acumulada). Si $S_n$ es monótona creciente y acotada superiormente por el límite del prop firm ($+10\%$ de profit target), ¿qué garantiza el Teorema 3.14?
- [ ] **E5.** Demuestra que la sucesión $s_n = \sum_{k=1}^{n} \frac{1}{k^2}$ es monótona creciente y acotada superiormente. *(No hace falta calcular el límite.)*
