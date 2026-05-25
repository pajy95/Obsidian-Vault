---
tags: [analisis, rudin, cap3, series, convergencia, criterios]
refs: [Rudin Cap. 3 — Secs. 3.21–3.28]
---

# Sesión — Series de Números Reales

> Prerequisito: [[02-Sucesiones]] · [[03-Convergencia]]
> Lee en Reading View: `Ctrl + E`

---

## 1. De Sucesiones a Series

### ¿Qué es una serie?

Dada una sucesión $\{a_n\}$, la **serie** asociada es el intento de sumar todos sus términos:

$$\sum_{n=1}^{\infty} a_n = a_1 + a_2 + a_3 + \cdots$$

Este símbolo es solo notación — no significa que "sumamos infinitos números de golpe". Lo que hacemos es:

**Definición (Rudin Def. 3.21):** Definir las **sumas parciales**:

$$S_N = \sum_{n=1}^{N} a_n = a_1 + a_2 + \cdots + a_N$$

La serie $\sum a_n$ **converge** si la sucesión $\{S_N\}$ converge. Su suma es $S = \lim_{N \to \infty} S_N$.

Si $\{S_N\}$ diverge, la serie **diverge**.

### Mensaje clave

Una serie es una **sucesión de sumas parciales**. Todo lo que sabemos de convergencia de sucesiones aplica directamente a series.

---

## 2. Criterio de Cauchy para Series (Rudin Teo. 3.22)

$$\sum a_n \text{ converge} \iff \forall\, \varepsilon > 0,\ \exists\, N : m > n > N \Rightarrow \left|\sum_{k=n+1}^{m} a_k\right| < \varepsilon$$

### Condición necesaria: $a_n \to 0$ (Rudin Teo. 3.23)

> Si $\sum a_n$ converge, entonces $a_n \to 0$.

**Demostración:** Tomando $m = n$ en el criterio de Cauchy: para $\varepsilon > 0$, existe $N$ con $n > N \Rightarrow |a_n| < \varepsilon$. $\blacksquare$

### ¡El recíproco es FALSO!

La **serie armónica** $\sum_{n=1}^{\infty} \frac{1}{n}$ tiene $\frac{1}{n} \to 0$, pero **diverge**.

**Demostración de la divergencia armónica:**

$$S_{2^k} = 1 + \frac{1}{2} + \underbrace{\left(\frac{1}{3}+\frac{1}{4}\right)}_{\geq 1/2} + \underbrace{\left(\frac{1}{5}+\frac{1}{6}+\frac{1}{7}+\frac{1}{8}\right)}_{\geq 1/2} + \cdots \geq 1 + \frac{k}{2}$$

Las sumas parciales crecen sin cota. $\blacksquare$

### Analogía — Costos acumulados

Si el spread de cada trade es $1/n$ pips (decreciendo), pero haces trades $n = 1, 2, 3, \ldots$, el costo total diverge a infinito aunque el costo por trade se acerque a cero. Este es exactamente el argumento de la serie armónica: la disminución individual no garantiza suma finita.

---

## 3. Series de Términos No Negativos (Rudin Teo. 3.24)

> Una serie con $a_n \geq 0$ converge $\iff$ sus sumas parciales están acotadas.

Esto se deduce directamente del Teorema de Convergencia Monótona: $\{S_N\}$ es creciente (porque $a_n \geq 0$), así que converge $\iff$ está acotada.

---

## 4. Serie Geométrica (Rudin Teo. 3.26)

Para $|x| < 1$:

$$\sum_{n=0}^{\infty} x^n = \frac{1}{1-x}$$

Para $|x| \geq 1$: diverge.

**Demostración:** La suma parcial es $S_N = \frac{1 - x^{N+1}}{1-x}$. Si $|x| < 1$: $x^{N+1} \to 0$, luego $S_N \to \frac{1}{1-x}$. $\blacksquare$

### Ejemplos numéricos

| $x$ | Serie | Suma |
|-----|-------|------|
| $1/2$ | $1 + 1/2 + 1/4 + 1/8 + \cdots$ | $2$ |
| $2/3$ | $1 + 2/3 + 4/9 + \cdots$ | $3$ |
| $-1/2$ | $1 - 1/2 + 1/4 - 1/8 + \cdots$ | $2/3$ |

### Analogía — Interés compuesto infinito

Si recibes $1$ peso hoy, $x$ pesos mañana, $x^2$ pasado, etc., el valor presente total (con tasa de descuento implícita) es $\frac{1}{1-x}$. Esto es la base de la fórmula de valor presente de una perpetuidad en finanzas.

---

## 5. Criterio de Comparación (Rudin Teo. 3.25)

> **(a)** Si $|a_n| \leq c_n$ para $n > N_0$ y $\sum c_n$ converge, entonces $\sum a_n$ converge.
>
> **(b)** Si $a_n \geq d_n > 0$ para $n > N_0$ y $\sum d_n$ diverge, entonces $\sum a_n$ diverge.

### Estrategia de uso

- Para probar **convergencia**: acotar por arriba con una serie conocida que converge (geométrica, $p$-serie con $p > 1$).
- Para probar **divergencia**: acotar por abajo con una serie conocida que diverge (armónica, $p$-serie con $p \leq 1$).

### Ejemplo — $\sum \frac{1}{n^2 + n}$

$$\frac{1}{n^2 + n} < \frac{1}{n^2}$$

Como $\sum \frac{1}{n^2}$ converge ($p$-serie con $p = 2 > 1$), por comparación $\sum \frac{1}{n^2+n}$ converge.

---

## 6. La $p$-Serie (Rudin Teo. 3.28)

$$\sum_{n=1}^{\infty} \frac{1}{n^p} \begin{cases} \text{converge} & \text{si } p > 1 \\ \text{diverge} & \text{si } p \leq 1 \end{cases}$$

### Demostración via Teorema de Condensación (Rudin Teo. 3.27)

Rudin usa un resultado elegante: si $a_n$ es decreciente y no negativa, la serie $\sum a_n$ converge $\iff$ la serie "condensada" $\sum 2^k a_{2^k}$ converge.

Para $a_n = 1/n^p$: la serie condensada es $\sum 2^k \cdot \frac{1}{(2^k)^p} = \sum 2^{k(1-p)}$, que es geométrica con razón $2^{1-p}$, convergente $\iff$ $2^{1-p} < 1 \iff p > 1$. $\blacksquare$

### Tabla de referencia

| $p$ | $\sum 1/n^p$ | Motivo |
|-----|-------------|--------|
| $1/2$ | Diverge | $1/n^{1/2}$ decrece pero muy lento |
| $1$ | Diverge | Serie armónica |
| $2$ | Converge ($= \pi^2/6$) | Suma exacta por Euler |
| $3$ | Converge | Valor no conocido en forma cerrada simple |
| $\infty$ | Converge ($\to 0$) | Converge trivialmente |

---

## 7. Criterio de la Razón — D'Alembert (Rudin Teo. 3.34)

$$L = \lim_{n \to \infty} \left|\frac{a_{n+1}}{a_n}\right| \begin{cases} < 1 & \Rightarrow \sum a_n \text{ converge absolutamente} \\ > 1 & \Rightarrow \sum a_n \text{ diverge} \\ = 1 & \text{inconcluso} \end{cases}$$

### Demostración (caso $L < 1$)

Si $L < r < 1$, existe $N$ con $n > N \Rightarrow |a_{n+1}/a_n| < r$. Entonces:

$$|a_{N+k}| \leq |a_N| \cdot r^k$$

Comparando con la geométrica $|a_N| \sum r^k$ (que converge pues $r < 1$), la serie converge. $\blacksquare$

### Ejemplo — $\sum \frac{n^2}{2^n}$

$$\frac{a_{n+1}}{a_n} = \frac{(n+1)^2}{2^{n+1}} \cdot \frac{2^n}{n^2} = \frac{(n+1)^2}{2n^2} \to \frac{1}{2} < 1$$

La serie converge.

### Cuando $L = 1$ — criterio inconcluso

- $\sum 1/n$: razón $\to 1$, diverge.
- $\sum 1/n^2$: razón $\to 1$, converge.

El criterio de la razón no distingue cuando $L = 1$. Hay que usar otro método.

---

## 8. Criterio de la Raíz — Cauchy (Rudin Teo. 3.33)

$$L = \limsup_{n \to \infty} \sqrt[n]{|a_n|} \begin{cases} < 1 & \Rightarrow \sum a_n \text{ converge absolutamente} \\ > 1 & \Rightarrow \sum a_n \text{ diverge} \end{cases}$$

El criterio de la raíz es **más fuerte** que el de la razón: siempre que el de la razón funciona, el de la raíz también; hay casos donde la raíz funciona y la razón no.

---

## 9. Convergencia Absoluta vs. Condicional

### Convergencia absoluta

$\sum a_n$ **converge absolutamente** si $\sum |a_n|$ converge.

Convergencia absoluta $\Rightarrow$ convergencia (pero no al revés).

### Convergencia condicional

$\sum a_n$ converge pero $\sum |a_n|$ diverge.

**Ejemplo clásico:** $\sum_{n=1}^{\infty} \frac{(-1)^{n+1}}{n} = 1 - \frac{1}{2} + \frac{1}{3} - \frac{1}{4} + \cdots = \ln 2$

Esta serie converge (por el criterio de Leibniz para series alternantes), pero $\sum 1/n$ diverge.

### Teorema de Riemann (rearranjos)

Una serie condicionalmente convergente puede **reorganizarse** para converger a cualquier valor real, o incluso divergir. Las series absolutamente convergentes tienen suma independiente del orden de los términos.

---

## 10. Series de Potencias — Introducción (Rudin Teo. 3.38)

Una **serie de potencias** tiene la forma:

$$\sum_{n=0}^{\infty} c_n z^n = c_0 + c_1 z + c_2 z^2 + \cdots$$

El **radio de convergencia** $R$ se define por:

$$\frac{1}{R} = \limsup_{n \to \infty} \sqrt[n]{|c_n|}$$

La serie converge absolutamente para $|z| < R$ y diverge para $|z| > R$.

### Analogía — Modelos de volatilidad

Las expansiones en series de potencias aparecen en la valoración de derivados: el precio de una opción se puede expandir en potencias del tiempo al vencimiento, la tasa de interés, etc. El radio de convergencia determina el rango de validez del modelo.

---

## 11. Resumen de Criterios

| Criterio | Condición de convergencia | Limitación |
|----------|--------------------------|------------|
| Cauchy | $\sum a_n$ es de Cauchy | Difícil de aplicar directamente |
| Comparación | $\|a_n\| \leq c_n$, $\sum c_n$ converge | Necesita serie de comparación |
| $p$-Serie | $p > 1$ | Solo para $\sum 1/n^p$ |
| Razón | $L = \lim\|a_{n+1}/a_n\| < 1$ | Falla cuando $L = 1$ |
| Raíz | $L = \limsup \sqrt[n]{\|a_n\|} < 1$ | Más fuerte que razón |
| Leibniz | Serie alternante con $a_n \searrow 0$ | Solo alternantes |

---

## Ejercicios

- [ ] **E1.** Demuestra que $\sum_{n=1}^{\infty} \frac{1}{n(n+1)}$ converge y calcula su suma exacta. *(Pista: $\frac{1}{n(n+1)} = \frac{1}{n} - \frac{1}{n+1}$ — serie telescópica.)*
- [ ] **E2.** Determina si $\sum_{n=1}^{\infty} \frac{n!}{n^n}$ converge o diverge. *(Usa el criterio de la razón.)*
- [ ] **E3.** Determina si $\sum_{n=2}^{\infty} \frac{1}{n \ln n}$ converge o diverge. *(Teorema de condensación.)*
- [ ] **E4.** Demuestra que $\sum_{n=1}^{\infty} \frac{(-1)^{n+1}}{n}$ converge pero no absolutamente.
- [ ] **E5 (Trading).** El P&L esperado del trade $n$ de un EA es $a_n = \frac{(-1)^{n+1}}{n}$ USD. ¿El P&L total $\sum a_n$ converge? Si reorganizas los trades (primero todas las ganancias, luego todas las pérdidas), ¿cambia la suma? *(Aquí entra el Teorema de Riemann sobre rearranjos.)*
- [ ] **E6.** Determina el radio de convergencia de $\sum_{n=0}^{\infty} \frac{z^n}{n!}$. *(Respuesta: $R = +\infty$ — esta es la serie de $e^z$.)*
