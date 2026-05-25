---
tags: [analisis, rudin, cap1, numeros-reales, supremo, infimo]
refs: [Rudin Cap. 1 — Secs. 1.1 a 1.11]
---
%%  %%
# Sesión 01 — Los Números Reales
### Rudin, Capítulo 1 · Secciones 1.1 a 1.11

> **Cómo usar esta nota:** Lee en Reading View (`Ctrl+E`). Las fórmulas se renderizan. Cuando termines una sección, cierra la nota e intenta explicarla de memoria antes de continuar.

---

## Parte 1 — ¿Por qué necesitamos los números reales?

Antes de definir nada, Rudin plantea una pregunta que parece simple:

> *¿Existe un número racional $p$ tal que $p^2 = 2$?*

La respuesta es **no**. Y eso es un problema enorme para las matemáticas.

### ¿Qué son los números racionales?

Un número racional es cualquier número que se puede escribir como fracción $\dfrac{m}{n}$, donde $m$ y $n$ son enteros y $n \neq 0$.

Ejemplos:
$$\frac{1}{2} = 0.5 \qquad \frac{1}{3} = 0.333\ldots \qquad \frac{22}{7} \approx 3.1428\ldots \qquad \frac{-5}{3} = -1.666\ldots$$

Los racionales parecen "completos" porque entre cualquier par de ellos siempre hay otro: si $r < s$, entonces $\dfrac{r+s}{2}$ también es racional y está entre ellos. Esto se llama **densidad**: los racionales son densos en la recta numérica.

Pero a pesar de esta densidad, los racionales tienen **huecos** — posiciones en la recta numérica que ningún racional ocupa. $\sqrt{2}$ es uno de esos huecos.

---

### Demostración: $\sqrt{2}$ no es racional (Rudin, Sec. 1.1)

**Estrategia:** demostración por contradicción. Suponemos que sí existe un racional $p$ con $p^2 = 2$, y llegamos a un absurdo.

**Paso 1:** Si $p^2 = 2$ y $p$ es racional, podemos escribir $p = \dfrac{m}{n}$ donde $m$ y $n$ son enteros **sin factor común** (fracción ya reducida). Esto siempre es posible: cualquier fracción se puede reducir.

**Paso 2:** Sustituimos en $p^2 = 2$:
$$\left(\frac{m}{n}\right)^2 = 2 \implies \frac{m^2}{n^2} = 2 \implies m^2 = 2n^2$$

**Paso 3:** La ecuación $m^2 = 2n^2$ dice que $m^2$ es par (es el doble de algo).

Ahora usamos un hecho básico: **si $m^2$ es par, entonces $m$ es par.**

¿Por qué? Porque si $m$ fuera impar, digamos $m = 2k+1$, entonces $m^2 = (2k+1)^2 = 4k^2 + 4k + 1$, que es impar. Contradicción. Entonces $m$ es par.

**Paso 4:** Como $m$ es par, existe un entero $k$ tal que $m = 2k$. Sustituimos:
$$(2k)^2 = 2n^2 \implies 4k^2 = 2n^2 \implies n^2 = 2k^2$$

Ahora $n^2$ es par, y por el mismo argumento del paso 3, $n$ también es par.

**Paso 5 — El absurdo:** Llegamos a que $m$ es par **y** $n$ es par. Pero habíamos dicho que $m/n$ ya estaba reducida, es decir, que $m$ y $n$ no tienen factor común. Si ambos son pares, ambos son divisibles por 2, lo que contradice que la fracción estaba reducida.

**Conclusión:** La suposición inicial es falsa. No existe ningún racional $p$ con $p^2 = 2$.

$$\sqrt{2} \notin \mathbb{Q}$$

---

### El hueco: visualizando el problema (Rudin, Sec. 1.1 cont.)

Para entender mejor el problema, Rudin define dos conjuntos:

$$A = \{p \in \mathbb{Q} : p > 0 \text{ y } p^2 < 2\} \qquad B = \{p \in \mathbb{Q} : p > 0 \text{ y } p^2 > 2\}$$

$A$ son todos los racionales positivos "por debajo de $\sqrt{2}$", y $B$ los que están "por encima".

Lo llamativo es que:
- $A$ no tiene **máximo**: para cada $p \in A$, existe $q \in A$ con $q > p$. Siempre hay un racional más grande que sigue estando en $A$.
- $B$ no tiene **mínimo**: para cada $p \in B$, existe $q \in B$ con $q < p$.

Esto significa que $A$ y $B$ se "acercan" mutuamente sin llegar a tocarse. El punto donde se "tocarían" — el valor $\sqrt{2}$ — no existe en $\mathbb{Q}$. Es el **hueco**.

> **Analogía — Trading:**
> Imagina que el precio "verdadero" de un activo es $\sqrt{2}$ = 1.41421356...
> El order book solo puede cotizar precios racionales (2 o 4 decimales):
> $$1.41,\quad 1.414,\quad 1.4142,\quad 1.41421,\quad \ldots$$
> Cada precio se acerca más, pero ninguno es exactamente $\sqrt{2}$. El precio real existe en $\mathbb{R}$, no en $\mathbb{Q}$.

> **Analogía — Electricidad:**
> El valor RMS de una corriente de 1 amperio pico es $\dfrac{1}{\sqrt{2}} \approx 0.707$ A. Este valor no es racional. Cualquier multímetro lo aproxima con decimales finitos, pero el valor exacto vive en $\mathbb{R}$.

---

### ¿Qué hace Rudin con esto?

Rudin concluye (Sec. 1.2):

> *"El sistema de los números reales llena estas lagunas."*

El resto del capítulo construye ese sistema con precisión. Pero antes necesita definir la estructura matemática que lo sostiene: los **conjuntos ordenados**.

---

## Parte 2 — Conjuntos Ordenados

### Notación de conjuntos (Rudin, Sec. 1.3)

Antes de hablar de orden, Rudin fija la notación de conjuntos:

- $x \in A$ significa que $x$ es elemento de $A$
- $x \notin A$ significa que $x$ no es elemento de $A$
- $A \subset B$ significa que todo elemento de $A$ es también elemento de $B$ ($A$ es subconjunto de $B$)
- $A = B$ significa que $A \subset B$ y $B \subset A$ (tienen exactamente los mismos elementos)

El conjunto $\mathbb{Q}$ denota a todos los números racionales.

---

### ¿Qué es un orden? (Rudin, Def. 1.5)

Un **orden** en un conjunto $S$ es una relación "$<$" que satisface exactamente dos propiedades:

**Propiedad 1 — Tricotomía:**
Para cualesquiera $x, y \in S$, exactamente una de las siguientes es verdadera:
$$x < y \qquad \text{o} \qquad x = y \qquad \text{o} \qquad y < x$$

No puede darse ninguna de las otras combinaciones: no puede ser que $x < y$ y también $y < x$, ni que ninguna se cumpla.

**Propiedad 2 — Transitividad:**
Si $x < y$ e $y < z$, entonces $x < z$.

Eso es todo. Un orden es simplemente una forma consistente de comparar elementos.

**Notación adicional:**
- "$y > x$" es lo mismo que "$x < y$" (solo se da vuelta)
- "$x \leq y$" significa "$x < y$ o $x = y$"

**Definición 1.6:** Un *conjunto ordenado* es un conjunto $S$ en el que se ha definido un orden.

> **Ejemplo de Rudin:** $\mathbb{Q}$ es un conjunto ordenado. La relación de orden es: $r < s$ si $s - r$ es un número racional positivo. Este orden satisface la tricotomía (dados dos racionales distintos, siempre uno es mayor) y la transitividad (si $r < s$ y $s < t$, entonces $r < t$).

> **Analogía — Order Book:**
> El conjunto de precios en un libro de órdenes es un conjunto ordenado.
> - Tricotomía: dados dos precios distintos, uno es mayor al otro. No hay ambigüedad.
> - Transitividad: si el bid de AAPL < bid de MSFT < bid de NVDA, entonces bid de AAPL < bid de NVDA.

---

## Parte 3 — Cotas, Supremo e Ínfimo

Esta es la parte más importante del capítulo. Estos conceptos aparecen en prácticamente todo el análisis.

### Cota superior (Rudin, Def. 1.7)

Sea $S$ un conjunto ordenado y $E \subset S$ un subconjunto.

Decimos que $E$ está **acotado superiormente** si existe un elemento $\beta \in S$ tal que:
$$x \leq \beta \quad \text{para todo } x \in E$$

A ese $\beta$ se le llama **cota superior** de $E$.

**Puntos importantes:**
- La cota superior $\beta$ **no tiene que pertenecer** a $E$. Solo tiene que estar en $S$.
- Si $\beta$ es cota superior, también lo son $\beta + 1$, $\beta + 100$, $\beta + 1000000$... Hay infinitas cotas superiores.
- La definición de cota inferior es análoga, pero con $\geq$ en lugar de $\leq$.

> **Ejemplo concreto:**
> Sea $E = \{1, 2, 3, 4, 5\}$. Cotas superiores: $5, 6, 7, 100, \ldots$ — infinitas.
> Cotas inferiores: $1, 0, -1, -100, \ldots$ — también infinitas.

---

### Supremo — la mínima cota superior (Rudin, Def. 1.8)

Como hay infinitas cotas superiores, la pregunta natural es: ¿cuál es la **más pequeña** de todas?

Sea $E \subset S$ acotado superiormente. Se dice que $\alpha \in S$ es el **supremo** de $E$ (o mínima cota superior) si se cumplen **ambas** condiciones:

**(i)** $\alpha$ es cota superior de $E$:
$$x \leq \alpha \quad \text{para todo } x \in E$$

**(ii)** Ningún número menor que $\alpha$ es cota superior de $E$:
$$\text{Si } \gamma < \alpha, \text{ entonces } \gamma \text{ no es cota superior de } E$$

La condición (ii) se puede leer de otra forma: si $\gamma < \alpha$, entonces existe algún $x \in E$ con $x > \gamma$. Es decir, $\alpha$ es "apretado" — no se puede bajar sin dejar de ser cota.

Se escribe: $\alpha = \sup E$

**¿Qué dice la condición (ii) en términos prácticos?**

Dado cualquier $\varepsilon > 0$ (por pequeño que sea), siempre existe algún elemento de $E$ que supera $\alpha - \varepsilon$:
$$\forall\, \varepsilon > 0,\quad \exists\, x \in E : x > \alpha - \varepsilon$$

Esto captura la idea de que el supremo es "alcanzado" por el conjunto, en el sentido de que el conjunto se le acerca arbitrariamente, aunque no necesariamente lo toque.

**El ínfimo** ($\inf E$) es análogo: la mayor de todas las cotas inferiores.

---

### Ejemplos de Rudin (Sec. 1.9) — Tres casos clave

**Caso (a) — Supremo que no existe en $\mathbb{Q}$:**

Retomando los conjuntos $A$ y $B$ de antes:
$$A = \{p \in \mathbb{Q} : p^2 < 2\} \qquad B = \{p \in \mathbb{Q} : p^2 > 2\}$$

- $A$ está acotado superiormente. De hecho, cualquier elemento de $B$ es cota superior de $A$.
- Pero $A$ **no tiene supremo en $\mathbb{Q}$**, porque $\sqrt{2} \notin \mathbb{Q}$.
- Igualmente, $B$ no tiene ínfimo en $\mathbb{Q}$.

Este es el hueco: en $\mathbb{Q}$, hay conjuntos acotados que no tienen supremo.

---

**Caso (b) — El supremo puede o no pertenecer al conjunto:**

Rudin da dos conjuntos con el mismo supremo:

$$E_1 = \{r \in \mathbb{Q} : r < 0\} \qquad E_2 = \{r \in \mathbb{Q} : r \leq 0\}$$

Para ambos conjuntos:
$$\sup E_1 = \sup E_2 = 0$$

Pero $0 \notin E_1$ (porque $E_1$ tiene solo números estrictamente negativos), y $0 \in E_2$ (porque $E_2$ incluye el cero).

> **Conclusión de Rudin:** El supremo puede o no pertenecer al conjunto. No hay regla fija.

> **Analogía — Velas en trading:**
> Sea $E_1$ = todos los precios negociados en una sesión **estrictamente por debajo** del High.
> Sea $E_2$ = todos los precios negociados **incluyendo** el High.
>
> En ambos casos $\sup = \text{High}$, pero solo en $E_2$ el High pertenece al conjunto.

---

**Caso (c) — El clásico de Rudin:**

Sea $E = \left\{\dfrac{1}{n} : n = 1, 2, 3, \ldots\right\} = \left\{1,\ \frac{1}{2},\ \frac{1}{3},\ \frac{1}{4},\ \ldots\right\}$

- $\sup E = 1$, y $1 \in E$ (es el primer elemento, con $n=1$)
- $\inf E = 0$, y $0 \notin E$ (ningún $\frac{1}{n}$ es cero, pero la sucesión se acerca arbitrariamente a cero)

Este ejemplo es fundamental porque muestra que el ínfimo puede "ser alcanzado en el límite" sin pertenecer al conjunto.

> **Analogía — Electricidad:**
> Sea $V(t) = \dfrac{1}{t}$ voltios para $t = 1, 2, 3, \ldots$ segundos (tensión que decae).
> El voltaje nunca llega a cero, pero se acerca indefinidamente. $\inf = 0 \notin E$.

---

## Parte 4 — La Propiedad que Distingue a $\mathbb{R}$

### La propiedad de la mínima cota superior (Rudin, Def. 1.10)

Esta es **la** definición más importante del capítulo. Todo el análisis depende de ella.

> Un conjunto ordenado $S$ tiene la **propiedad de la mínima cota superior** si:
> Para todo $E \subset S$ con $E \neq \emptyset$ y $E$ acotado superiormente, se tiene que $\sup E$ **existe en $S$**.

En otras palabras: en $S$, todo subconjunto no vacío y acotado superiormente tiene supremo — y ese supremo está dentro de $S$, no "fuera" de él.

**¿Por qué $\mathbb{Q}$ NO tiene esta propiedad?**

El ejemplo 1.9(a) lo muestra directamente:
- $A = \{p \in \mathbb{Q} : p^2 < 2\}$ es no vacío (por ejemplo, $1 \in A$) ✓
- $A$ está acotado superiormente (por ejemplo, $2$ es cota superior) ✓
- Pero $\sup A = \sqrt{2}$, y $\sqrt{2} \notin \mathbb{Q}$ ✗

El supremo existe en $\mathbb{R}$, pero no en $\mathbb{Q}$. Los racionales tienen el hueco.

**$\mathbb{R}$ SÍ tiene esta propiedad** — esto es el **Axioma de Completitud** de los reales, y es la diferencia fundamental entre $\mathbb{Q}$ y $\mathbb{R}$.

> **Analogía — Modelos de precios continuos:**
> Black-Scholes y todos los modelos de precios continuos trabajan en $\mathbb{R}$ precisamente por esto: en $\mathbb{R}$, cualquier conjunto de precios acotado tiene un máximo "verdadero", no solo una aproximación. Sin completitud, los límites de sucesiones de precios podrían no existir dentro del sistema.

---

## Parte 5 — El Teorema 1.11: Sup e Inf se implican mutuamente

Rudin demuestra algo elegante: en un conjunto ordenado con la propiedad de la mínima cota superior, **también existen todos los ínfimos**.

> **Teorema 1.11:** Sea $S$ un conjunto ordenado con la propiedad de la mínima cota superior. Si $B \subset S$ es no vacío y acotado inferiormente, entonces $\inf B$ existe en $S$.

**Demostración (siguiendo a Rudin):**

Sea $L$ = conjunto de todas las cotas inferiores de $B$.

*Paso 1:* Como $B$ está acotado inferiormente, $L$ no es vacío.

*Paso 2:* Todo elemento de $B$ es cota superior de $L$. ¿Por qué? Porque si $y \in L$, entonces $y \leq x$ para todo $x \in B$ — así que cada $x \in B$ supera a todo elemento de $L$. Por tanto $L$ está acotado superiormente.

*Paso 3:* Como $S$ tiene la propiedad de la mínima cota superior y $L$ es no vacío y acotado superiormente, existe $\alpha = \sup L$ en $S$.

*Paso 4:* Rudin demuestra que $\alpha = \inf B$:
- $\alpha$ es cota inferior de $B$ (porque $\alpha \leq x$ para todo $x \in B$)
- Ningún $\beta > \alpha$ es cota inferior de $B$ (porque $\alpha$ es la mayor de las cotas inferiores de $B$)

**Conclusión:** En $\mathbb{R}$, no necesitas dos axiomas separados — con garantizar que existen todos los supremos, los ínfimos vienen solos.

---

## Resumen completo de la Sesión 01

| Concepto | ¿Qué es? | Detalle crítico |
|----------|----------|-----------------|
| Número racional | $p = m/n$, enteros $m, n$ | $\sqrt{2}$ no es racional |
| Conjunto ordenado | Tiene relación $<$ con tricotomía y transitividad | $\mathbb{Q}$ y $\mathbb{R}$ son ejemplos |
| Cota superior de $E$ | Cualquier $\beta$ con $x \leq \beta$ para todo $x \in E$ | Siempre hay infinitas |
| $\sup E$ | La **menor** cota superior | Puede o no pertenecer a $E$ |
| $\inf E$ | La **mayor** cota inferior | Puede o no pertenecer a $E$ |
| Completitud de $\mathbb{R}$ | Todo subconjunto no vacío y acotado tiene $\sup$ en $\mathbb{R}$ | $\mathbb{Q}$ no lo tiene — ahí está el hueco |
| Teorema 1.11 | Si existen todos los $\sup$, también existen todos los $\inf$ | Un solo axioma alcanza |

---

## Preguntas de autocomprobación

Antes de pasar a los ejercicios, cierra la nota e intenta responder estas preguntas de memoria:

1. ¿Por qué $\sqrt{2}$ no es racional? (da los pasos de la demostración)
2. ¿Cuáles son las dos propiedades que debe tener un orden?
3. ¿Qué diferencia hay entre una cota superior y el supremo?
4. ¿Puede el supremo no pertenecer al conjunto? Da un ejemplo.
5. ¿Por qué $\mathbb{Q}$ no tiene la propiedad de la mínima cota superior?

---

## Ejercicios

- [ ] **E1 (Rudin 1.9c).** Sea $E = \{1/n : n = 1, 2, 3, \ldots\}$. Demuestra formalmente que $\sup E = 1$ (y que $1 \in E$) e $\inf E = 0$ (y que $0 \notin E$). Para el ínfimo: demuestra que $0$ es cota inferior, y que ningún número positivo puede serlo.
- [ ] **E2 (Rudin Ej. 1).** Si $r$ es racional con $r \neq 0$ y $x$ es irracional, demuestra que $r + x$ y $r \cdot x$ son irracionales. *(Pista: usa contradicción — supón que son racionales y llega a un absurdo.)*

- [ ] **E3 (Rudin Ej. 2).** Demuestra que no existe ningún racional cuyo cuadrado sea 12. *(La demostración es análoga a la de $\sqrt{2}$.)*

- [ ] **E4 (Rudin Ej. 4).** Sea $E$ un subconjunto no vacío de un conjunto ordenado. Si $\alpha$ es cota inferior de $E$ y $\beta$ es cota superior de $E$, demuestra que $\alpha \leq \beta$.

- [ ] **E5 (Rudin Ej. 5 — Fundamental).** Sea $A$ un conjunto de números reales no vacío y acotado inferiormente. Si $-A = \{-x : x \in A\}$, demuestra que:
$$\inf A = -\sup(-A)$$
*(Este resultado se usa constantemente. La idea: las cotas inferiores de $A$ son los negativos de las cotas superiores de $-A$.)*

- [ ] **E6 (Trading).** Sea $E$ el conjunto de todos los precios de cierre de NAS100 durante el último mes. ¿Tiene $E$ un supremo? ¿Un ínfimo? ¿Pertenecen a $E$? ¿Cambiaría algo si en vez de precios de cierre usaras todos los ticks del mes?
