---
tags: [analisis, rudin, cap6, integral, riemann, riemann-stieltjes, particiones]
refs: [Rudin Cap. 6 — Secs. 6.1–6.22; Secs. 6.25–6.33 (TFC)]
---

# Sesión — La Integral de Riemann-Stieltjes

> Prerequisito: [[01-Funciones]] · [[02-Sucesiones]] · [[03-Convergencia]]
> Lee en Reading View: `Ctrl + E`

---

## 1. ¿Por qué hay que construir la integral?

Intuitivamente, $\int_a^b f(x)\,dx$ es el "área bajo la curva". Pero esa intuición no alcanza para demostrar nada con rigor. ¿Qué sucede cuando $f$ tiene discontinuidades? ¿Cuándo $f$ es monótona pero no continua? ¿Siempre existe el área?

Rudin construye la integral **desde cero** mediante sumas de Darboux: aplastamos la función desde arriba y desde abajo con rectángulos y pedimos que ambas aproximaciones coincidan.

### La generalización de Stieltjes

Rudin presenta directamente la integral de **Riemann-Stieltjes**, que tiene la forma $\int_a^b f\,d\alpha$. La integral de Riemann clásica es el caso particular $\alpha(x) = x$.

La integral de Stieltjes permite integrar con respecto a una función de distribución $\alpha$ en lugar de la longitud del intervalo — esto conecta directamente con la teoría de probabilidad y las distribuciones de retornos en finanzas.

---

## 2. Particiones y Sumas de Darboux (Rudin Def. 6.1)

### Definición de partición

Una **partición** $P$ del intervalo $[a,b]$ es un conjunto finito de puntos:

$$P = \{x_0, x_1, \ldots, x_n\} \quad \text{con } a = x_0 < x_1 < \cdots < x_n = b$$

Denotamos $\Delta x_i = x_i - x_{i-1}$ el **ancho** del $i$-ésimo subintervalo.

### Sumas de Darboux

Sea $f$ acotada en $[a,b]$. Para cada subintervalo $[x_{i-1}, x_i]$, definimos:

$$M_i = \sup_{x \in [x_{i-1}, x_i]} f(x) \qquad m_i = \inf_{x \in [x_{i-1}, x_i]} f(x)$$

La **suma superior** y **suma inferior** de Darboux son:

$$U(P, f) = \sum_{i=1}^{n} M_i \,\Delta x_i \qquad L(P, f) = \sum_{i=1}^{n} m_i \,\Delta x_i$$

Siempre vale $L(P,f) \leq U(P,f)$, porque $m_i \leq M_i$ para cada $i$.

### Visualización

```
f(x)
 |       ___
 |   ___/   \___
 |  /           \___
 |_/                 \
 +---+---+---+---+---+-- x
 x₀  x₁  x₂  x₃  x₄  x₅

U(P,f): rectángulos que CUBREN la curva por arriba (Mᵢ)
L(P,f): rectángulos que QUEDAN por debajo (mᵢ)

Si U-L → 0 al refinar P, la integral "existe".
```

---

## 3. La Integral de Riemann-Stieltjes (Rudin Def. 6.2)

Sea $\alpha: [a,b] \to \mathbb{R}$ **monótona creciente**. Para cada subintervalo:

$$\Delta \alpha_i = \alpha(x_i) - \alpha(x_{i-1}) \geq 0$$

Las sumas de Darboux-Stieltjes son:

$$U(P, f, \alpha) = \sum_{i=1}^{n} M_i \,\Delta \alpha_i \qquad L(P, f, \alpha) = \sum_{i=1}^{n} m_i \,\Delta \alpha_i$$

**Definición:** La **integral superior** e **integral inferior** de Riemann-Stieltjes son:

$$\overline{\int_a^b} f\,d\alpha = \inf_P U(P, f, \alpha) \qquad \underline{\int_a^b} f\,d\alpha = \sup_P L(P, f, \alpha)$$

**$f$ es integrable Riemann-Stieltjes** respecto a $\alpha$, escrito $f \in \mathscr{R}(\alpha)$, si:

$$\overline{\int_a^b} f\,d\alpha = \underline{\int_a^b} f\,d\alpha$$

Este valor común es la **integral** $\displaystyle\int_a^b f\,d\alpha$.

### El caso clásico: $\alpha(x) = x$

Con $\alpha(x) = x$: $\Delta \alpha_i = \Delta x_i$. Las sumas de Stieltjes se reducen a las sumas de Riemann. La integral $\int_a^b f\,dx$ es la integral de Riemann estándar.

---

## 4. Refinamientos (Rudin Teo. 6.4)

### Definición de refinamiento

$P^*$ es un **refinamiento** de $P$ si $P \subset P^*$ — simplemente añadimos puntos a la partición.

### Teorema 6.4

> Si $P^*$ es refinamiento de $P$:
> $$L(P, f, \alpha) \leq L(P^*, f, \alpha) \qquad U(P^*, f, \alpha) \leq U(P, f, \alpha)$$

**En palabras:** Al agregar puntos a la partición, las sumas inferiores solo pueden crecer y las superiores solo pueden decrecer. Refinar la partición "aprieta" las sumas.

**Demostración (para una suma superior con un punto extra):**

Supongamos $P^* = P \cup \{x^*\}$ con $x_{i-1} < x^* < x_i$. El intervalo $[x_{i-1}, x_i]$ se divide en $[x_{i-1}, x^*]$ y $[x^*, x_i]$. Con:

$$M'  = \sup_{[x_{i-1}, x^*]} f \leq M_i, \qquad M'' = \sup_{[x^*, x_i]} f \leq M_i$$

La contribución del nuevo par de subintervalos a $U(P^*, f, \alpha)$ es:

$$M'(\alpha(x^*) - \alpha(x_{i-1})) + M''(\alpha(x_i) - \alpha(x^*))$$
$$\leq M_i(\alpha(x^*) - \alpha(x_{i-1})) + M_i(\alpha(x_i) - \alpha(x^*)) = M_i \Delta\alpha_i$$

Que era la contribución en $U(P, f, \alpha)$. Luego $U(P^*, f, \alpha) \leq U(P, f, \alpha)$. $\blacksquare$

---

## 5. La Integral Inferior ≤ La Integral Superior (Rudin Teo. 6.5)

> $$\underline{\int_a^b} f\,d\alpha \leq \overline{\int_a^b} f\,d\alpha$$

**Demostración:**

Sean $P_1$ y $P_2$ cualesquiera dos particiones. Sea $P^* = P_1 \cup P_2$ (su unión es refinamiento de ambas). Por el Teorema 6.4:

$$L(P_1, f, \alpha) \leq L(P^*, f, \alpha) \leq U(P^*, f, \alpha) \leq U(P_2, f, \alpha)$$

Esto dice: toda suma inferior es $\leq$ toda suma superior. Por tanto:

$$\sup_{P_1} L(P_1, f, \alpha) \leq \inf_{P_2} U(P_2, f, \alpha)$$

Es decir, $\underline{\int} f\,d\alpha \leq \overline{\int} f\,d\alpha$. $\blacksquare$

---

## 6. Criterio de Integrabilidad (Rudin Teo. 6.6)

Este es el **criterio operativo** para verificar integrabilidad sin calcular explícitamente $\overline{\int}$ y $\underline{\int}$.

> $f \in \mathscr{R}(\alpha)$ en $[a,b]$ si y solo si para todo $\varepsilon > 0$ existe una partición $P$ tal que:
>
> $$U(P, f, \alpha) - L(P, f, \alpha) < \varepsilon$$

**Demostración ($\Rightarrow$):**

Si $f \in \mathscr{R}(\alpha)$, entonces $\overline{\int} = \underline{\int} = I$. Para $\varepsilon > 0$:

- Existe $P_1$ con $U(P_1, f, \alpha) < I + \varepsilon/2$
- Existe $P_2$ con $L(P_2, f, \alpha) > I - \varepsilon/2$

Sea $P = P_1 \cup P_2$. Por los refinamientos:

$$U(P, f, \alpha) \leq U(P_1, f, \alpha) < I + \varepsilon/2$$
$$L(P, f, \alpha) \geq L(P_2, f, \alpha) > I - \varepsilon/2$$

Por tanto $U(P,f,\alpha) - L(P,f,\alpha) < \varepsilon$. $\blacksquare$

**Demostración ($\Leftarrow$):**

Si existe $P$ con $U(P,f,\alpha) - L(P,f,\alpha) < \varepsilon$, entonces:

$$0 \leq \overline{\int} f\,d\alpha - \underline{\int} f\,d\alpha \leq U(P,f,\alpha) - L(P,f,\alpha) < \varepsilon$$

Como esto vale para todo $\varepsilon > 0$: $\overline{\int} = \underline{\int}$. $\blacksquare$

---

## 7. Funciones Continuas son Integrables (Rudin Teo. 6.8)

> **Teorema:** Si $f$ es continua en $[a,b]$, entonces $f \in \mathscr{R}(\alpha)$ para toda $\alpha$ monótona creciente.

**Idea de la demostración:**

$[a,b]$ es compacto y $f$ continua $\Rightarrow$ $f$ es **uniformemente continua** (Rudin Teo. 4.19).

Dado $\varepsilon > 0$, existe $\delta > 0$ tal que $|x-y| < \delta \Rightarrow |f(x)-f(y)| < \varepsilon / (\alpha(b)-\alpha(a))$.

Elige $P$ con todos los $\Delta x_i < \delta$. En cada subintervalo:

$$M_i - m_i < \frac{\varepsilon}{\alpha(b) - \alpha(a)}$$

(por continuidad uniforme, el oscilamiento en cada intervalo pequeño es pequeño)

Entonces:

$$U(P,f,\alpha) - L(P,f,\alpha) = \sum_{i=1}^n (M_i - m_i)\Delta\alpha_i < \frac{\varepsilon}{\alpha(b)-\alpha(a)} \sum_{i=1}^n \Delta\alpha_i = \varepsilon$$

Por el Criterio 6.6: $f \in \mathscr{R}(\alpha)$. $\blacksquare$

---

## 8. Funciones Monótonas son Integrables (Rudin Teo. 6.9)

> **Teorema:** Si $f$ es monótona en $[a,b]$ y $\alpha$ es continua en $[a,b]$, entonces $f \in \mathscr{R}(\alpha)$.

**Idea de la demostración:**

Supongamos $f$ monótona creciente (el caso decreciente es análogo).

Como $\alpha$ es continua en $[a,b]$ compacto, es uniformemente continua. Dado $\varepsilon > 0$, podemos elegir $P$ tal que $\Delta\alpha_i < \varepsilon / (f(b)-f(a))$ para todo $i$.

En cada subintervalo $[x_{i-1}, x_i]$, como $f$ es creciente:

$$M_i = f(x_i), \qquad m_i = f(x_{i-1})$$

Entonces:

$$U(P,f,\alpha) - L(P,f,\alpha) = \sum_{i=1}^n (f(x_i) - f(x_{i-1}))\Delta\alpha_i$$
$$\leq \frac{\varepsilon}{f(b)-f(a)} \sum_{i=1}^n (f(x_i) - f(x_{i-1})) = \frac{\varepsilon}{f(b)-f(a)} (f(b)-f(a)) = \varepsilon$$

Por el Criterio 6.6: $f \in \mathscr{R}(\alpha)$. $\blacksquare$

### Consecuencia importante

Una función con **discontinuidades de salto** (escalonada) sigue siendo integrable si es monótona. Esto es más general que la continuidad.

---

## 9. Propiedades de la Integral (Rudin Teo. 6.12, 6.13)

Sean $f, g \in \mathscr{R}(\alpha)$ en $[a,b]$.

### Linealidad

$$\int_a^b (f + g)\,d\alpha = \int_a^b f\,d\alpha + \int_a^b g\,d\alpha$$

$$\int_a^b (c \cdot f)\,d\alpha = c \int_a^b f\,d\alpha \quad \forall\, c \in \mathbb{R}$$

### Aditividad del dominio

$$\int_a^b f\,d\alpha = \int_a^c f\,d\alpha + \int_c^b f\,d\alpha \quad \text{para } a < c < b$$

### Monotonía

$$f(x) \leq g(x)\ \forall\, x \in [a,b] \quad \Rightarrow \quad \int_a^b f\,d\alpha \leq \int_a^b g\,d\alpha$$

### Acotación

$$\left|\int_a^b f\,d\alpha\right| \leq \sup_{[a,b]} |f| \cdot [\alpha(b) - \alpha(a)]$$

**Demostración:** $-M \leq f(x) \leq M$ donde $M = \sup|f|$. Por monotonía:

$$-M[\alpha(b)-\alpha(a)] \leq \int_a^b f\,d\alpha \leq M[\alpha(b)-\alpha(a)]$$

$\blacksquare$

---

## 10. Integración por Partes (Rudin Teo. 6.22)

> Si $f \in \mathscr{R}(\alpha)$ en $[a,b]$, entonces $\alpha \in \mathscr{R}(f)$ y:
>
> $$\int_a^b f\,d\alpha + \int_a^b \alpha\,df = f(b)\alpha(b) - f(a)\alpha(a)$$

Esta es la **fórmula de integración por partes** para integrales de Stieltjes. En el caso clásico $f,g$ diferenciables: $\int f\,g' = fg\big|_a^b - \int f'\,g$.

---

## 11. El Teorema Fundamental del Cálculo (Rudin Teo. 6.33)

El TFC conecta diferenciación e integración — son operaciones inversas.

### Parte I — La integral acumula, la derivada recupera

> Si $f \in \mathscr{R}$ en $[a,b]$ y $F(x) = \int_a^x f(t)\,dt$, entonces $F$ es continua en $[a,b]$.
>
> Más aún, si $f$ es continua en $x_0 \in [a,b]$, entonces $F$ es diferenciable en $x_0$ y $F'(x_0) = f(x_0)$.

**Demostración de $F'(x_0) = f(x_0)$:**

Para $h$ pequeño:

$$\frac{F(x_0 + h) - F(x_0)}{h} = \frac{1}{h} \int_{x_0}^{x_0+h} f(t)\,dt$$

Como $f$ es continua en $x_0$: para todo $\varepsilon > 0$ existe $\delta > 0$ con $|t - x_0| < \delta \Rightarrow |f(t) - f(x_0)| < \varepsilon$.

Para $|h| < \delta$:

$$\left|\frac{F(x_0+h)-F(x_0)}{h} - f(x_0)\right| = \left|\frac{1}{h}\int_{x_0}^{x_0+h}(f(t)-f(x_0))\,dt\right| \leq \frac{1}{|h|} \cdot \varepsilon |h| = \varepsilon$$

$\blacksquare$

### Parte II — Primitivas y el cálculo de integrales

> Si $f \in \mathscr{R}$ en $[a,b]$ y $F$ es primitiva de $f$ (es decir $F' = f$):
>
> $$\int_a^b f(x)\,dx = F(b) - F(a)$$

Esta es la herramienta de cálculo práctica: encontrar $F$ tal que $F' = f$ y evaluar en los extremos.

### Analogía — Velocity y posición

Si $f(t)$ es la velocidad de un objeto en el tiempo $t$, entonces $F(t) = \int_0^t f(s)\,ds$ es su posición. El TFC Parte I dice: la derivada de la posición acumulada es la velocidad instantánea. El TFC Parte II dice: el desplazamiento total entre $a$ y $b$ es $F(b) - F(a)$.

---

## 12. Conexión con Probabilidad y el Caso de Stieltjes

La integral de Stieltjes $\int f\,d\alpha$ es natural en probabilidad:

- $\alpha(x) = F_X(x)$: función de distribución acumulada de una variable aleatoria $X$
- $\int_{-\infty}^{\infty} x\,dF_X(x)$: **valor esperado** $\mathbb{E}[X]$

La notación unifica el caso discreto (sumas ponderadas) y continuo (integral ordinaria) en un solo marco.

Para una variable discreta con masa en puntos $x_1, x_2, \ldots$:

$$\int f\,dF_X = \sum_k f(x_k) P(X = x_k)$$

Para una variable continua con densidad $p$:

$$\int f\,dF_X = \int f(x) p(x)\,dx$$

---

## Analogías — Trading y Finanzas

### Analogía 1 — Área bajo la curva de equity

La equity acumulada de un EA es $E(t) = \int_0^t r(s)\,ds$ donde $r(s)$ es el retorno instantáneo.

El TFC dice: $E'(t) = r(t)$ — la velocidad de crecimiento de la equity en cada momento es el retorno instantáneo. Las sumas de Darboux son exactamente lo que hacemos al calcular la equity en barras discretas: sumamos retornos ponderados por el tamaño de cada intervalo.

Si el proceso de retornos $r$ es solo **monótono** en períodos (como puede ocurrir en tendencias fuertes), el Teo. 6.9 garantiza que la integral existe aunque $r$ no sea continua.

### Analogía 2 — VaR como integral de pérdidas

El Value at Risk (VaR) al nivel $\alpha$ es el cuantil de la distribución de pérdidas:

$$\text{VaR}_\alpha = \inf\{l : P(L > l) \leq 1-\alpha\}$$

El Expected Shortfall (ES o CVaR) es:

$$\text{ES}_\alpha = \frac{1}{1-\alpha}\int_\alpha^1 \text{VaR}_u\,du$$

Esto es precisamente una integral de Riemann de la función $u \mapsto \text{VaR}_u$. El criterio 6.6 garantiza que esta integral existe siempre que la función de cuantiles sea acotada y casi en todos lados continua.

### Analogía 3 — Integral de Stieltjes como promedio ponderado

Si $\alpha(x)$ es una función escalonada que salta en $x_1, x_2, \ldots, x_n$ con saltos $w_1, w_2, \ldots, w_n$:

$$\int_a^b f\,d\alpha = \sum_{k=1}^n f(x_k) w_k$$

Esto es exactamente un **promedio ponderado** de $f$ en los puntos $x_k$. Si los puntos son fechas de trades y $w_k$ son tamaños de posición, la integral de Stieltjes da el P&L total ponderado.

---

## 13. Resumen — Jerarquía de Resultados

```
FUNCIÓN ACOTADA f EN [a,b]
        ↓
   Sumas de Darboux: L(P,f) ≤ U(P,f)
        ↓
   Refinar partición: L↑, U↓   ← Teo. 6.4
        ↓
   Integral inferior ≤ Integral superior   ← Teo. 6.5
        ↓
   ¿Coinciden? → f es INTEGRABLE
        ↓
Criterio operativo:  ∀ε>0 ∃P: U(P,f)-L(P,f)<ε   ← Teo. 6.6
        ↓
Condiciones suficientes:
   f CONTINUA en [a,b]    → f ∈ ℛ(α)   ← Teo. 6.8
   f MONÓTONA en [a,b]    → f ∈ ℛ(α)   ← Teo. 6.9
        ↓
Propiedades: Linealidad, Aditividad, Monotonía, Acotación
        ↓
Teorema Fundamental del Cálculo
   F(x) = ∫ₐˣ f → F'(x₀) = f(x₀) si f continua en x₀
   ∫ₐᵇ f = F(b) - F(a) si F' = f
```

---

## Tabla de referencia — Clases de funciones integrables

| Función $f$ | Condición | ¿Integrable? | Motivo |
|-------------|-----------|--------------|--------|
| Continua en $[a,b]$ | — | Sí | Teo. 6.8 |
| Monótona en $[a,b]$, $\alpha$ continua | — | Sí | Teo. 6.9 |
| Acotada, con finitas discontinuidades | — | Sí | Corolario de 6.6 |
| Función de Dirichlet ($\mathbb{1}_\mathbb{Q}$) | — | No (Riemann) | Oscilación irreducible |
| No acotada en $[a,b]$ | — | No (Darboux) | $M_i = +\infty$ |

> **Nota:** La función de Dirichlet ($f=1$ en $\mathbb{Q}$, $f=0$ en irracionales) no es Riemann-integrable en ningún intervalo. Sus sumas superiores siempre son $1$ y las inferiores siempre son $0$, independientemente de la partición. Esto motiva la integral de Lebesgue.

---

## Ejercicios

- [ ] **E1.** Sea $f(x) = c$ (constante) en $[a,b]$. Demuestra desde la definición que $\int_a^b c\,dx = c(b-a)$.
- [ ] **E2.** Sea $f(x) = x$ en $[0,1]$. Usando particiones uniformes $P_n = \{0, 1/n, 2/n, \ldots, 1\}$, calcula $U(P_n, f)$ y $L(P_n, f)$ y demuestra que ambas convergen a $1/2$.
- [ ] **E3.** Sea $f: [0,1] \to \mathbb{R}$ definida por $f(x) = 0$ si $x \neq 1/2$ y $f(1/2) = 1$. Demuestra que $f \in \mathscr{R}$ y calcula $\int_0^1 f\,dx$. *(Una sola discontinuidad no destruye la integrabilidad.)*
- [ ] **E4.** Demuestra que si $f \in \mathscr{R}(\alpha)$ en $[a,b]$ entonces $|f| \in \mathscr{R}(\alpha)$ y $\left|\int_a^b f\,d\alpha\right| \leq \int_a^b |f|\,d\alpha$.
- [ ] **E5.** Sea $F(x) = \int_0^x t^2\,dt$. Calcula $F(x)$ explícitamente y verifica que $F'(x) = x^2$. *(Aplicación directa del TFC.)*
- [ ] **E6 (Stieltjes).** Sea $\alpha$ la función escalonada $\alpha(x) = 0$ para $x < 1/2$ y $\alpha(x) = 1$ para $x \geq 1/2$. Calcula $\int_0^1 f\,d\alpha$ para $f$ continua en $[0,1]$. *(Respuesta: $f(1/2)$ — la integral de Stieltjes con escalón es evaluación puntual.)*
- [ ] **E7 (Trading).** El retorno diario de un EA en el día $t$ es $r(t)$ con $|r(t)| \leq M$ para todo $t \in [0, T]$. Si $r$ es monótona en cada mes, ¿puedes garantizar que $\int_0^T r(t)\,dt$ existe? ¿Qué resultado de Rudin aplica? Estima la cota $\left|\int_0^T r(t)\,dt\right|$.
