---
tags: [analisis, rudin, cap4, funciones, continuidad, limite]
refs: [Rudin Cap. 2 (Def. 2.1–2.2) · Cap. 4 (Secs. 4.1–4.14)]
---

# Sesión — Función, Función Inversa y Continuidad

> Prerequisito: [[Sesion-01-Numeros-Reales]] · [[Sesion-02-Campo-Real]] · [[Ejercicios-Cap2-Soluciones]]
> Lee en Reading View: `Ctrl + E`

---

## 1. Función — Definición Formal (Rudin Def. 2.1)

### Definición

Dados dos conjuntos $A$ y $B$, una **función** (o aplicación o mapeo) $f: A \to B$ es una regla que asigna a cada $x \in A$ exactamente un elemento $f(x) \in B$.

- $A$ = **dominio** de $f$
- $B$ = **codominio** de $f$
- $f(A) = \{f(x) : x \in A\}$ = **rango** (o imagen) de $f$

### Precisión importante

$f(A) \subset B$ pero no necesariamente $f(A) = B$. El rango puede ser estrictamente menor que el codominio.

**Ejemplo:** $f: \mathbb{R} \to \mathbb{R}$, $f(x) = x^2$. El codominio es $\mathbb{R}$ pero el rango es $[0, +\infty)$. Los negativos nunca son imagen de ningún real.

### Inyectividad y Sobreyectividad

| Tipo | Condición | Significado |
|------|-----------|-------------|
| **Inyectiva** (1-1) | $f(x_1) = f(x_2) \Rightarrow x_1 = x_2$ | Cada elemento del rango tiene exactamente una preimagen |
| **Sobreyectiva** (sobre) | $\forall\, y \in B,\ \exists\, x \in A : f(x) = y$ | Rango $= B$; todo elemento de $B$ es alcanzado |
| **Biyectiva** | Inyectiva **y** sobreyectiva | Correspondencia 1-1 exacta entre $A$ y $B$ |

---

## 2. Función Inversa

### Definición

Si $f: A \to B$ es **biyectiva**, existe la función inversa $f^{-1}: B \to A$ definida por:

$$f^{-1}(y) = x \iff f(x) = y$$

Por biyectividad, ese $x$ existe (sobreyectiva) y es único (inyectiva).

### Propiedades

$$f^{-1}(f(x)) = x \quad \forall\, x \in A$$
$$f(f^{-1}(y)) = y \quad \forall\, y \in B$$

### Ejemplo — $f(x) = 2x + 3$

$f: \mathbb{R} \to \mathbb{R}$ es biyectiva. La inversa: despeja $x$ de $y = 2x + 3$:

$$f^{-1}(y) = \frac{y - 3}{2}$$

Verificación: $f^{-1}(f(x)) = f^{-1}(2x+3) = \frac{(2x+3)-3}{2} = x$ ✓

### Ejemplo — $f(x) = x^2$ no tiene inversa global

$f: \mathbb{R} \to \mathbb{R}$ no es inyectiva ($f(2) = f(-2) = 4$). No existe $f^{-1}: \mathbb{R} \to \mathbb{R}$.

Sin embargo, **restringiendo** el dominio: $f: [0,+\infty) \to [0,+\infty)$ es biyectiva, y su inversa es $f^{-1}(y) = \sqrt{y}$.

Esto es exactamente lo que garantiza el Teorema 1.21 de Rudin (existencia de raíces $n$-ésimas).

### Analogía — Trading

Una función de señal de un EA: $f(\text{precio}) = \text{señal}$ (BUY/SELL/HOLD). Si dos precios distintos siempre dan señales distintas, $f$ es inyectiva — las señales son informativas. Si $f$ no es inyectiva (muchos precios dan la misma señal), hay pérdida de información.

La función inversa en ese contexto sería: dado que vi la señal, ¿de qué precio vino? Solo funciona si $f$ es biyectiva.

---

## 3. Límite de una Función (Rudin Def. 4.1)

### Definición $\varepsilon$-$\delta$

Sean $X$ e $Y$ espacios métricos, $E \subset X$, $f: E \to Y$, y $p$ un punto límite de $E$. Escribimos:

$$\lim_{x \to p} f(x) = q$$

si para todo $\varepsilon > 0$ existe $\delta > 0$ tal que:

$$x \in E,\quad 0 < d_X(x, p) < \delta \quad \Rightarrow \quad d_Y(f(x), q) < \varepsilon$$

### Observaciones clave de Rudin

1. $p$ debe ser **punto límite** de $E$ — para que tenga sentido aproximarse a $p$.
2. $p$ **no necesita pertenecer a $E$** — ni siquiera el dominio de $f$.
3. Aunque $p \in E$, puede ocurrir $f(p) \neq \lim_{x\to p} f(x)$.

### Equivalencia con sucesiones (Rudin Teo. 4.2)

$$\lim_{x \to p} f(x) = q \iff \lim_{n \to \infty} f(p_n) = q \text{ para toda sucesión } p_n \to p \text{ en } E, p_n \neq p$$

Esta equivalencia es poderosa: **reduce el límite de función a límite de sucesión**, permitiendo usar todo el arsenal del Cap. 3.

### Ejemplo — $\lim_{x \to 0} \frac{\sin x}{x} = 1$

No se puede evaluar directamente ($f(0) = 0/0$). Pero para cualquier sucesión $x_n \to 0$ con $x_n \neq 0$, se puede demostrar que $\frac{\sin x_n}{x_n} \to 1$.

---

## 4. Álgebra de Límites de Funciones (Rudin Teo. 4.4)

Si $\lim_{x \to p} f(x) = A$ y $\lim_{x \to p} g(x) = B$:

$$\lim_{x\to p}(f + g)(x) = A + B$$
$$\lim_{x\to p}(fg)(x) = AB$$
$$\lim_{x\to p}\frac{f}{g}(x) = \frac{A}{B} \quad \text{(si } B \neq 0\text{)}$$

**Demostración directa** desde el Teorema 4.2 y el álgebra de límites de sucesiones (Teo. 3.3).

---

## 5. Función Continua (Rudin Def. 4.5)

### Definición

$f: E \to Y$ es **continua en $p \in E$** si para todo $\varepsilon > 0$ existe $\delta > 0$ tal que:

$$x \in E,\quad d_X(x, p) < \delta \quad \Rightarrow \quad d_Y(f(x), f(p)) < \varepsilon$$

Diferencia con el límite: aquí $p \in E$ obligatoriamente y la condición incluye $x = p$ (sin el $0 <$).

### Equivalencia con límite (Rudin Teo. 4.6)

Si $p$ es punto límite de $E$:

$$f \text{ es continua en } p \iff \lim_{x \to p} f(x) = f(p)$$

En lenguaje informal: **la función llega a donde debe llegar**. El límite no solo existe sino que coincide con el valor de la función.

### Tres condiciones equivalentes para continuidad en $p$

1. Para todo $\varepsilon > 0$ existe $\delta > 0$ con la propiedad $\varepsilon$-$\delta$.
2. Para toda sucesión $x_n \to p$ en $E$: $f(x_n) \to f(p)$.
3. Para cada vecindad $V$ de $f(p)$ existe una vecindad $U$ de $p$ con $f(U \cap E) \subset V$.

Las tres son equivalentes — úsalas según cuál convenga en cada demostración.

---

## 6. Composición de Funciones Continuas (Rudin Teo. 4.7)

> **Teorema:** Si $f: E \subset X \to Y$ es continua en $p$ y $g: f(E) \to Z$ es continua en $f(p)$, entonces $h = g \circ f: E \to Z$ es continua en $p$.

**Demostración (cadena de $\varepsilon$-$\delta$):**

Dado $\varepsilon > 0$:
- $g$ continua en $f(p)$: $\exists\, \eta > 0$ tal que $d_Y(y, f(p)) < \eta \Rightarrow d_Z(g(y), g(f(p))) < \varepsilon$.
- $f$ continua en $p$: $\exists\, \delta > 0$ tal que $d_X(x,p) < \delta \Rightarrow d_Y(f(x), f(p)) < \eta$.
- Conclusión: $d_X(x,p) < \delta \Rightarrow d_Z(h(x), h(p)) < \varepsilon$. $\blacksquare$

### Consecuencia práctica

Las funciones continuas se pueden combinar libremente: suma, producto, cociente (si denominador $\neq 0$), composición — el resultado siempre es continuo.

Todo polinomio $P(x) = a_n x^n + \cdots + a_0$ es continuo en $\mathbb{R}$ (Rudin Ej. 4.11).

Toda función racional $P(x)/Q(x)$ es continua donde $Q(x) \neq 0$.

---

## 7. Caracterización Topológica de la Continuidad (Rudin Teo. 4.8)

> **Teorema:** $f: X \to Y$ es continua $\iff$ para todo abierto $V \subset Y$, la preimagen $f^{-1}(V)$ es abierto en $X$.
>
> **Corolario:** $f$ es continua $\iff$ para todo cerrado $C \subset Y$, la preimagen $f^{-1}(C)$ es cerrado en $X$.

Esta es la **definición topológica de continuidad** — la más elegante y la que se generaliza a espacios donde no hay métrica.

### ¿Cómo conecta con $\varepsilon$-$\delta$?

La vecindad $\varepsilon$-ball alrededor de $f(p)$ es un abierto $V$ en $Y$. La condición $\delta$ dice que existe una bola alrededor de $p$ contenida en $f^{-1}(V)$, es decir que $p$ es interior a $f^{-1}(V)$. Como esto vale para todo $p$, $f^{-1}(V)$ es abierto. Son exactamente la misma propiedad en dos lenguajes.

### Aplicación — Conjunto cero de una función continua

Si $f: X \to \mathbb{R}$ es continua, entonces $Z(f) = \{p \in X : f(p) = 0\}$ es **cerrado**.

**Demostración:** $Z(f) = f^{-1}(\{0\})$. El conjunto $\{0\}$ es cerrado en $\mathbb{R}$. Por el corolario, $f^{-1}(\{0\})$ es cerrado. $\blacksquare$

---

## 8. Continuidad y Compacticidad (Rudin Teo. 4.14)

> **Teorema:** Si $f: X \to Y$ es continua y $X$ es compacto, entonces $f(X)$ es compacto.

**Consecuencias inmediatas:**

1. **Teorema del valor extremo:** Si $f: X \to \mathbb{R}$ es continua y $X$ compacto, entonces $f$ alcanza su máximo y mínimo en $X$.

2. **Acotación:** $f$ es acotada en $X$.

### Demostración del teorema del valor extremo

$f(X)$ es compacto en $\mathbb{R}$ (por Teo. 4.14). Todo compacto en $\mathbb{R}$ es cerrado y acotado (Heine-Borel). En particular, $\sup f(X)$ es alcanzado (el supremo de un cerrado acotado pertenece al conjunto). $\blacksquare$

### Analogía — Trading

El precio de una opción europea $f(S_T)$ donde $S_T$ es el precio del activo al vencimiento. Si el espacio de trayectorias de precios es compacto (por ejemplo, precios en un intervalo $[S_{\min}, S_{\max}]$), la función payoff continua alcanza su máximo y mínimo — los payoffs extremos son alcanzables.

En la práctica, el mercado no es compacto ($S_T$ puede ir a $0$ o $+\infty$), pero en modelos de backtesting con datos históricos sí lo es.

---

## 9. Resumen — Jerarquía de Conceptos

```
FUNCIÓN f: A → B
       ↓
Inyectiva + Sobreyectiva = Biyectiva → Existe f⁻¹
       ↓
LÍMITE lim f(x) = q cuando x→p
  (p no necesita estar en el dominio)
       ↓
CONTINUA en p: lim_{x→p} f(x) = f(p)
  (p debe estar en el dominio)
       ↓
Caracterización topológica: preimagen de abiertos es abierta
       ↓
CONTINUA EN COMPACTO: imagen es compacta → alcanza max y min
```

---

## Ejercicios

- [ ] **E1.** Sea $f(x) = x^3 - 3x$. Demuestra que $f: \mathbb{R} \to \mathbb{R}$ no es inyectiva. ¿En qué subintervalo es inyectiva?
- [ ] **E2.** Usa la definición $\varepsilon$-$\delta$ para demostrar que $f(x) = 3x - 1$ es continua en todo $x_0 \in \mathbb{R}$.
- [ ] **E3.** Demuestra que $f(x) = |x|$ es continua en $\mathbb{R}$ pero no diferenciable en $x = 0$.
- [ ] **E4.** Sea $f(x) = \begin{cases} 1 & x \in \mathbb{Q} \\ 0 & x \notin \mathbb{Q} \end{cases}$ (función de Dirichlet). Demuestra que $f$ no es continua en ningún punto.
- [ ] **E5.** Si $f: [a,b] \to \mathbb{R}$ es continua y $f(a) < 0 < f(b)$, demuestra que existe $c \in (a,b)$ con $f(c) = 0$. *(Este es el Teorema del Valor Intermedio — usa el Teo. 4.8 o la conexidad de $[a,b]$.)*
- [ ] **E6 (Trading).** Sea $P: \mathbb{R}_{>0} \to \mathbb{R}$ el precio de una opción call como función del precio del subyacente $S$. Si $P$ es continua y el mercado solo puede cotizar en $[S_{\min}, S_{\max}]$ (compacto), demuestra que el precio de la opción está acotado y alcanza su máximo.
