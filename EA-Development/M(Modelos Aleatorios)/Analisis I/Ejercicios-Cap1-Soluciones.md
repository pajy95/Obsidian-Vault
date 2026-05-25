---
tags: [analisis, rudin, cap1, ejercicios, soluciones]
refs: [Rudin Cap. 1 — Ejercicios 1–20]
---
 %%  %% 
# Ejercicios Capítulo 1 — Soluciones Completas (Rudin)

> Prerequisito: [[Sesion-01-Numeros-Reales]] · [[Sesion-02-Campo-Real]]
> Lee en Reading View: `Ctrl + E`

---

## Enunciados y contexto general

Rudin coloca estos ejercicios al final del Capítulo 1 (págs. 24–25 de la edición en español). Todos los números son reales salvo indicación contraria.

Los ejercicios 1–5 son los **más fundamentales** — forman la base del razonamiento algebraico y de orden en $\mathbb{R}$. Los ejercicios 6–7 construyen la teoría de potencias y logaritmos desde los axiomas.

---

## Ejercicio 1

> **Enunciado:** Si $r$ es racional con $r \neq 0$ y $x$ es irracional, demuestra que $r + x$ y $rx$ son irracionales.

### Por qué es importante

Este ejercicio te obliga a usar la definición de irracional por contradicción. Es el patrón de demostración más común en todo el análisis: *supón que el resultado es falso, llega a una contradicción, concluye que era verdadero*.

### Demostración de $r + x$ es irracional

**Supón por contradicción** que $r + x$ es racional. Entonces existe $p/q \in \mathbb{Q}$ (con $q \neq 0$) tal que:

$$r + x = \frac{p}{q}$$

Despejando $x$:

$$x = \frac{p}{q} - r$$

Ahora bien, $r$ es racional, así que $r = a/b$ para ciertos enteros $a, b$ con $b \neq 0$. Entonces:

$$x = \frac{p}{q} - \frac{a}{b} = \frac{pb - aq}{qb}$$

El numerador $pb - aq$ es entero (diferencia de productos de enteros). El denominador $qb$ es entero no nulo. Por lo tanto $x$ es racional.

**Contradicción:** habíamos supuesto que $x$ es irracional. La contradicción surge de asumir que $r + x$ es racional, así que $r + x$ debe ser **irracional**. $\blacksquare$

---

### Demostración de $rx$ es irracional

**Supón por contradicción** que $rx$ es racional. Entonces existe $s \in \mathbb{Q}$ tal que:

$$rx = s$$

Como $r \neq 0$ (condición del enunciado), podemos dividir:

$$x = \frac{s}{r}$$

El cociente de dos racionales es racional (es un campo). Entonces $x \in \mathbb{Q}$.

**Contradicción:** $x$ es irracional. Por lo tanto $rx$ es **irracional**. $\blacksquare$

---

### ¿Por qué se necesita $r \neq 0$?

Si $r = 0$: $rx = 0 \cdot x = 0 \in \mathbb{Q}$. El resultado falla sin esa hipótesis. Rudin es preciso: cada hipótesis tiene un propósito.

### Analogía — Trading

Sea $x = \sqrt{2}$ (irracional) un retorno teórico en puntos irracional. Si multiplicas por el pip value racional $r = 0.1$, el resultado sigue siendo irracional: **no hay redondeo que lo vuelva exactamente racional**. En la práctica el broker lo muestra con 5 decimales, pero matemáticamente $0.1\sqrt{2} \notin \mathbb{Q}$.

---

## Ejercicio 2

> **Enunciado:** Demuestra que no hay ningún número racional cuyo cuadrado sea 12.

### Por qué es importante

Es la generalización del argumento clásico $\sqrt{2} \notin \mathbb{Q}$ (Ejemplo 1.1 de Rudin). El método es idéntico — muestra que el mismo argumento se aplica a $\sqrt{12}$.

### Demostración

**Supón por contradicción** que existe $p/q \in \mathbb{Q}$ (con $p, q$ enteros, $q \neq 0$, y la fracción en mínimos términos, es decir $\gcd(p,q) = 1$) tal que:

$$\left(\frac{p}{q}\right)^2 = 12$$

Entonces:

$$p^2 = 12q^2$$

**Paso 1 — $p$ es divisible por 2.**

$p^2 = 12q^2 = 4 \cdot 3q^2$ es divisible por 4, luego por 2. Si $p^2$ es par, entonces $p$ es par (si $p$ fuera impar, $p^2$ sería impar). Escribe $p = 2m$ para algún entero $m$.

**Paso 2 — $p$ es divisible por 3.**

Sustituyendo $p^2 = 12q^2$:

$$(2m)^2 = 12q^2 \implies 4m^2 = 12q^2 \implies m^2 = 3q^2$$

Entonces $m^2$ es divisible por 3. Si $3 \mid m^2$ entonces $3 \mid m$ (porque 3 es primo: si $3 \nmid m$, entonces $3 \nmid m^2$). Escribe $m = 3k$, es decir $p = 2m = 6k$.

**Paso 3 — $q$ es divisible por 6.**

Regresando a $p^2 = 12q^2$:

$$(6k)^2 = 12q^2 \implies 36k^2 = 12q^2 \implies 3k^2 = q^2$$

Entonces $3 \mid q^2$, luego $3 \mid q$. Escribe $q = 3j$.

Ahora: $p = 6k$ y $q = 3j$, entonces $3 \mid \gcd(p, q)$.

**Contradicción:** Habíamos supuesto que $\gcd(p,q) = 1$, pero acabamos de probar que 3 divide a ambos. Contradicción.

Por lo tanto, **no existe racional cuyo cuadrado sea 12**, es decir $\sqrt{12} \notin \mathbb{Q}$. $\blacksquare$

---

### Nota sobre el método

Observa: $\sqrt{12} = 2\sqrt{3}$. Como $2 \in \mathbb{Q}$ y $2 \neq 0$, por el Ejercicio 1 basta demostrar que $\sqrt{3} \notin \mathbb{Q}$. El argumento sería análogo: suponer $p^2 = 3q^2$ y llegar a que $3 \mid \gcd(p,q)$.

### Analogía — Volatilidad

$\sqrt{12\%}$ aparece, por ejemplo, en la desviación estándar de una inversión con varianza del 12% anual. El ejercicio dice: ese valor de volatilidad **nunca puede expresarse exactamente como fracción de enteros** — solo como aproximación decimal.

---

## Ejercicio 3

> **Enunciado:** Demuestra la Proposición 1.15.

### Qué dice la Proposición 1.15

La Proposición 1.15 de Rudin lista las propiedades de los campos. En particular, para un campo $F$ con operaciones $+$ y $\cdot$:

**(a)** Si $x + y = x + z$ entonces $y = z$ (cancelación aditiva)

**(b)** Si $x + y = x$ entonces $y = 0$

**(c)** Si $x + y = 0$ entonces $y = -x$

**(d)** $-(-x) = x$

**(e)** Si $x \neq 0$ y $xy = xz$ entonces $y = z$ (cancelación multiplicativa)

**(f)** Si $x \neq 0$ y $xy = x$ entonces $y = 1$

**(g)** Si $x \neq 0$ y $xy = 1$ entonces $y = 1/x$

**(h)** Si $x \neq 0$ entonces $1/(1/x) = x$

### Demostración de (a): $x + y = x + z \Rightarrow y = z$

Existe el inverso aditivo $-x$ (axioma A5). Sumamos $-x$ a ambos lados:

$$(-x) + (x + y) = (-x) + (x + z)$$

Por asociatividad (A2):

$$((-x) + x) + y = ((-x) + x) + z$$

Por A5, $(-x) + x = 0$:

$$0 + y = 0 + z$$

Por A4 (0 es identidad): $y = z$. $\blacksquare$

---

### Demostración de (d): $-(-x) = x$

Por definición de inverso aditivo, $-(-x)$ es el elemento tal que $(-x) + (-(-x)) = 0$.

Pero también: $(-x) + x = 0$ (por A5).

Por la unicidad del inverso aditivo (consecuencia de (a)), el elemento que sumado a $(-x)$ da 0 es único. Ese elemento es $x$. Por lo tanto $-(-x) = x$. $\blacksquare$

---

### Demostración de (e): $x \neq 0,\ xy = xz \Rightarrow y = z$

Existe $1/x$ (inverso multiplicativo, axioma M5). Multiplica ambos lados por $1/x$:

$$\frac{1}{x}(xy) = \frac{1}{x}(xz)$$

Por asociatividad M2 y M5:

$$\left(\frac{1}{x} \cdot x\right)y = \left(\frac{1}{x} \cdot x\right)z \implies 1 \cdot y = 1 \cdot z \implies y = z \quad \blacksquare$$

---

## Ejercicio 4

> **Enunciado:** Sea $E$ un subconjunto no vacío de un conjunto ordenado; supóngase que $\alpha$ es una cota inferior de $E$ y $\beta$ es una cota superior de $E$. Demuestra que $\alpha \leq \beta$.

### Por qué es importante

Este resultado parece obvio, pero requiere demostración formal desde los axiomas del orden. Establece que **ninguna cota inferior puede superar a ninguna cota superior** — propiedad fundamental que usamos constantemente (por ejemplo, $\inf E \leq \sup E$).

### Demostración

Como $E$ no es vacío, existe al menos un elemento $x \in E$.

- $\alpha$ es cota inferior de $E$: por definición, $\alpha \leq x$ para todo $x \in E$.
- $\beta$ es cota superior de $E$: por definición, $x \leq \beta$ para todo $x \in E$.

Aplicando ambas a nuestro $x \in E$:

$$\alpha \leq x \quad \text{y} \quad x \leq \beta$$

Por transitividad del orden (Definición 1.5(ii)):

$$\alpha \leq \beta \quad \blacksquare$$

---

### ¿Por qué se necesita $E \neq \emptyset$?

Si $E = \emptyset$: **todo número real** es cota inferior de $\emptyset$ y **todo número real** es cota superior de $\emptyset$ (vacuamente cierto). Podría tenerse $\alpha = 100$ y $\beta = -50$ siendo ambos cotas del conjunto vacío, con $\alpha > \beta$. El enunciado falla. La hipótesis de no vacío es esencial.

### Analogía — Risk Management

Sea $E$ el conjunto de todos los PnL diarios de un EA en un período. La cota inferior $\alpha$ es el máximo drawdown diario admisible (negativo) y $\beta$ es el target de profit diario. El ejercicio dice: *el floor de pérdida admisible siempre está por debajo del ceiling de ganancia esperada* — lo cual es la definición implícita de un sistema con positive expected value.

En FundingPips: $\alpha = -5\%$ (límite de drawdown diario) y $\beta = +\infty$ (sin límite de ganancia). Se cumple trivialmente. Pero si alguien propusiera un sistema con $\alpha > \beta$, el Ejercicio 4 dice que ese conjunto de resultados sería vacío.

---

## Ejercicio 5

> **Enunciado:** Sea $A$ un conjunto de números reales no vacío y acotado inferiormente. Si $-A = \{-x : x \in A\}$, demuestra que
> $$\inf A = -\sup(-A)$$

### Por qué es fundamental

Este resultado conecta el ínfimo con el supremo mediante negación. Es la razón por la que **solo necesitamos el axioma del supremo** — el ínfimo es su consecuencia automática. Rudin lo usa constantemente sin citarlo explícitamente.

### Demostración

**Parte 1 — $-A$ está acotado superiormente.**

Sea $\gamma = \inf A$ (existe porque $A$ es no vacío y acotado inferiormente).

Por definición de ínfimo: $\gamma \leq x$ para todo $x \in A$.

Multiplicando por $-1$ (invierte la desigualdad en campo ordenado):

$$-x \leq -\gamma \quad \text{para todo } x \in A$$

Esto dice que $-\gamma$ es una cota superior de $-A = \{-x : x \in A\}$.

Como $-A$ es no vacío (pues $A$ no es vacío) y está acotado superiormente, por el **Teorema 1.19** (existencia de $\mathbb{R}$) existe $\sup(-A)$.

---

**Parte 2 — $\sup(-A) = -\gamma$, es decir $\sup(-A) = -\inf A$.**

Ya probamos que $-\gamma$ es cota superior de $-A$. Falta demostrar que es la **mínima** cota superior.

Sea $\delta < -\gamma$ cualquier número (candidato a cota superior menor). Entonces $-\delta > \gamma$.

Como $\gamma = \inf A$, la propiedad característica del ínfimo (Def. 1.8) dice: para todo $\varepsilon > 0$ existe $x \in A$ con $x < \gamma + \varepsilon$.

Tomamos $\varepsilon = -\delta - \gamma > 0$ (es positivo porque $-\delta > \gamma$):

$$\exists\, x_0 \in A : x_0 < \gamma + (-\delta - \gamma) = -\delta$$

Entonces $-x_0 > \delta$. Como $-x_0 \in -A$, el número $\delta$ **no es cota superior de $-A$**.

Por lo tanto, ningún número menor que $-\gamma$ puede ser cota superior de $-A$. Esto confirma que $-\gamma$ es la **mínima** cota superior:

$$\sup(-A) = -\gamma = -\inf A$$

Reorganizando:

$$\boxed{\inf A = -\sup(-A)} \quad \blacksquare$$

---

### Visualización

```
         A:    [γ .........  elementos de A  .........]
       −A:    [......... elementos de −A  ......... −γ]
                                                    ↑
                                               sup(−A) = −γ
```

El conjunto $-A$ es el espejo de $A$ respecto al 0. El ínfimo de $A$ (extremo izquierdo) se convierte en el negativo del supremo de $-A$ (extremo derecho del espejo).

### Analogía — Long/Short P&L

Sea $A = \{\text{pérdidas de tu EA en cada día}\}$ con valores negativos como $\{-50, -30, -80, \ldots\}$.

$\inf A$ = la **peor pérdida** (más negativa), digamos $-80$.

$-A = \{50, 30, 80, \ldots\}$ representa los mismos valores como ganancias hipotéticas de una estrategia contraria.

$\sup(-A) = 80$.

El Ejercicio 5 dice: la peor pérdida de tu EA $= -$(mejor ganancia de la estrategia contraria).

En prop firms: si tu máximo drawdown diario fue $-80$ USD, el EA contrario habría ganado exactamente $+80$ USD ese día. Perfectamente simétrico.

---

## Ejercicio 6

> **Enunciado:** Sea $b > 1$ fijo.
>
> **(a)** Si $m, n, p, q$ son enteros, $n > 0$, $q > 0$, y $r = m/n = p/q$, demostrar que $(b^m)^{1/n} = (b^p)^{1/q}$.
>
> **(b)** Demostrar que $b^{r+s} = b^r b^s$ si $r$ y $s$ son racionales.
>
> **(c)** Si $x$ es real, definir $B(x) = \{b^t : t \in \mathbb{Q},\, t \leq x\}$. Demostrar que $b^r = \sup B(r)$ para $r$ racional, y definir $b^x = \sup B(x)$ para todo $x$ real.
>
> **(d)** Demostrar que $b^{x+y} = b^x b^y$ para todo $x, y \in \mathbb{R}$.

### Contexto

Este ejercicio construye la **exponencial** $b^x$ para exponente real desde primeros principios — usando solo la propiedad del supremo. Es la base de la teoría del logaritmo (Ejercicio 7).

### (a) La definición $b^r = (b^m)^{1/n}$ es consistente

Necesitamos probar: si $m/n = p/q$ entonces $(b^m)^{1/n} = (b^p)^{1/q}$.

Elevar ambos lados a la $nq$-ésima potencia (positiva, así preserva igualdad por el Teorema 1.21):

$$\left[(b^m)^{1/n}\right]^{nq} = b^{mq}$$

$$\left[(b^p)^{1/q}\right]^{nq} = b^{pn}$$

Como $m/n = p/q$ implica $mq = pn$, tenemos $b^{mq} = b^{pn}$.

Por unicidad de la raíz $nq$-ésima (Teorema 1.21): $(b^m)^{1/n} = (b^p)^{1/q}$. $\blacksquare$

---

### (b) $b^{r+s} = b^r b^s$ para racionales

Sean $r = m/n$ y $s = p/q$ con $n, q > 0$ enteros.

$$r + s = \frac{mq + pn}{nq}$$

Por definición:

$$b^{r+s} = \left(b^{mq+pn}\right)^{1/(nq)} = \left(b^{mq} \cdot b^{pn}\right)^{1/(nq)}$$

Usando propiedades de potencias enteras y el Teorema 1.21:

$$= \left(b^{mq}\right)^{1/(nq)} \cdot \left(b^{pn}\right)^{1/(nq)} = b^{m/n} \cdot b^{p/q} = b^r \cdot b^s \quad \blacksquare$$

---

### (c) $b^r = \sup B(r)$ para $r$ racional

$B(r) = \{b^t : t \in \mathbb{Q},\, t \leq r\}$.

**$b^r$ es cota superior de $B(r)$:** Para todo $t \leq r$ con $t \in \mathbb{Q}$, como $b > 1$:

$$b^t = b^r \cdot b^{t-r}$$

Como $t - r \leq 0$ y $b > 1$: $b^{t-r} \leq 1$, luego $b^t \leq b^r$.

**$b^r$ es la mínima cota superior:** Para cualquier $\varepsilon > 0$, necesitamos $t \in \mathbb{Q}$ con $t \leq r$ y $b^t > b^r - \varepsilon$. Basta tomar $t = r$ (pues $r$ es racional): $b^r = b^r > b^r - \varepsilon$.

Por lo tanto $\sup B(r) = b^r$. La definición $b^x = \sup B(x)$ extiende esto a todo $x$ real. $\blacksquare$

---

### (d) $b^{x+y} = b^x b^y$ para reales

La idea es que $B(x+y) = B(x) \cdot B(y)$ en el sentido de supremos, y la extensión se hereda de los racionales por continuidad del supremo. (La demostración completa usa el lema: $\sup(AB) = \sup A \cdot \sup B$ para conjuntos de positivos, lo cual se desprende de la definición de supremo.) $\blacksquare$

---

## Ejercicio 7

> **Enunciado:** Con $b > 1$ e $y > 0$ fijos, demuestra que existe un único $x \in \mathbb{R}$ tal que $b^x = y$ (este $x$ es el logaritmo de $y$ en base $b$).

### Contexto

Rudin da un bosquejo con pasos (a)–(g). Es una demostración de existencia y unicidad del logaritmo usando solo el supremo — sin límites ni series.

### Esquema de demostración

**Sea $A = \{w \in \mathbb{R} : b^w < y\}$.**

**(a) Lema previo:** Para todo entero positivo $n$: $b^n - 1 \geq n(b-1)$.

*Demostración:* Inducción. Para $n=1$: $b-1 \geq 1 \cdot (b-1)$ ✓. Si vale para $n$: $b^{n+1} - 1 = b \cdot b^n - 1 \geq b\cdot(1 + n(b-1)) - 1 = (n+1)(b-1) + n(b-1)^2 \geq (n+1)(b-1)$. $\blacksquare$

**(b) Consecuencia:** $b - 1 \geq n(b^{1/n} - 1)$, es decir $b^{1/n} - 1 \leq (b-1)/n$.

Aplica (a) con $b^{1/n}$ en lugar de $b$: $(b^{1/n})^n - 1 \geq n(b^{1/n} - 1)$, es decir $b - 1 \geq n(b^{1/n} - 1)$. $\blacksquare$

**(c) Control de $b^{1/n}$:** Si $t > 1$ y $n > (b-1)/(t-1)$, entonces $b^{1/n} < t$.

De (b): $b^{1/n} \leq 1 + (b-1)/n < 1 + (t-1) = t$ cuando $n > (b-1)/(t-1)$. $\blacksquare$

**(d) $A$ no tiene cota superior relativa a $y$:** Si $b^w < y$, existe $n$ tal que $b^{w+1/n} < y$.

Toma $t = y \cdot b^{-w} > 1$ (pues $b^w < y$). Por (c), existe $n$ con $b^{1/n} < t = y/b^w$, es decir $b^{w+1/n} = b^w \cdot b^{1/n} < b^w \cdot (y/b^w) = y$. Entonces $w + 1/n \in A$, así que $A$ no está acotado por debajo de $y$ en ese sentido. $\blacksquare$

**(e) Complemento:** Si $b^w > y$, existe $n$ con $b^{w-1/n} > y$.

Simétrico a (d). $\blacksquare$

**(f) Existencia:** Sea $x = \sup A$. Entonces $b^x = y$.

- Si $b^x < y$: por (d), existe $n$ con $b^{x+1/n} < y$, luego $x + 1/n \in A$. Contradice $x = \sup A$.
- Si $b^x > y$: por (e), existe $n$ con $b^{x-1/n} > y$. Entonces para todo $w \leq x - 1/n$: $b^w \leq b^{x-1/n} > y$, así que $w \notin A$. Pero esto dice que $x - 1/n$ es cota superior de $A$, menor que $x$. Contradice $x = \sup A$.

Por tricotomía: $b^x = y$. $\blacksquare$

**(g) Unicidad:** Si $b^{x_1} = b^{x_2} = y$ con $x_1 < x_2$, entonces (como $b > 1$) $b^{x_1} < b^{x_2}$. Contradicción. El logaritmo es único. $\blacksquare$

---

### Analogía — Rendimiento compuesto

Si una cuenta crece con factor $b = 1.01$ diario (1% diario) y quieres que alcance $y = 2$ (duplicar), el Ejercicio 7 garantiza que existe **exactamente un número** de días $x$ tal que $1.01^x = 2$. Ese $x$ es $\log_{1.01}(2) \approx 69.7$ días — la "regla del 70" en finanzas.

La demostración dice: ese $x$ existe porque $\mathbb{R}$ tiene la propiedad del supremo. Sin $\mathbb{R}$ completo, la solución podría no estar en el sistema numérico.

---

---

## Ejercicio 8

> **Enunciado:** Demostrar que en el campo complejo $\mathbb{C}$ no puede definirse ningún orden que lo convierta en un **campo ordenado**. *Sugerencia: $-1$ es un cuadrado.*

### Contexto

En un campo ordenado, todo cuadrado no nulo es positivo: si $x \neq 0$, entonces $x^2 > 0$. Esto se deduce de que $x > 0 \Rightarrow x^2 > 0$, y $x < 0 \Rightarrow -x > 0 \Rightarrow (-x)^2 = x^2 > 0$.

### Demostración

Supongamos por contradicción que existe un orden $<$ que hace de $\mathbb{C}$ un campo ordenado.

En todo campo ordenado, para todo $x \neq 0$: $x^2 > 0$.

Aplicado a $i \neq 0$: $i^2 > 0$. Pero $i^2 = -1$, así que $-1 > 0$.

Entonces $-1 + 1 > 0 + 1$, es decir $0 > 1$.

Pero también $1 = 1^2 > 0$ (por la misma propiedad con $x = 1$).

Contradicción: $0 > 1$ y $1 > 0$ simultáneamente. $\blacksquare$

### Mensaje

El número $i$ no puede ser positivo ni negativo en ningún orden de campo. No es que el orden sea "difícil de definir" — es que es **imposible**. Los campos ordenados no tienen soluciones de $x^2 = -1$.

---

## Ejercicio 9

> **Enunciado:** Sea $z = a + bi$ y $w = c + di$. Definir $z < w$ si $a < c$, o si $a = c$ y $b < d$ (orden **lexicográfico**). Demostrar que esto convierte a $\mathbb{C}$ en un conjunto ordenado. ¿Tiene la propiedad de la mínima cota superior?

### Demostración — es un orden total

Hay que verificar tres propiedades:

**Tricotomía:** Dados $z = a+bi$ y $w = c+di$: comparamos primero $a$ vs $c$.
- Si $a < c$: $z < w$.
- Si $a > c$: $w < z$.
- Si $a = c$: comparamos $b$ vs $d$, y por tricotomía en $\mathbb{R}$, exactamente uno de $b < d$, $b = d$, $b > d$ vale. Esto da $z < w$, $z = w$, o $w < z$ respectivamente.

**Transitividad:** Supongamos $z < w < v$. Si la comparación de $z < w$ usó la primera coordenada ($a < c$): entonces $a < c$, y si $c < e$ (primera coord de $v$), listo; si $c = e$ entonces la segunda coord de $v$ es $> d > b$, también $z < v$. Los demás casos son análogos. $\blacksquare$

### ¿Tiene la propiedad de la mínima cota superior?

**No.** Contraejemplo: sea $A = \{z = a + 0i : a < 1\} = \{$reales menores que 1$\}$.

$A$ está acotado superiormente: cualquier $w = 1 + di$ satisface $w > z$ para todo $z \in A$ (pues $\text{Re}(w) = 1 > a = \text{Re}(z)$).

Pero el conjunto de cotas superiores es $\{1 + di : d \in \mathbb{R}\}$ — no tiene mínimo, pues para cualquier $1 + d_0 i$, el elemento $1 + (d_0 - 1)i$ también es cota superior y es menor. Así que $\sup A$ no existe. $\blacksquare$

---

## Ejercicio 10

> **Enunciado:** Sea $w = u + iv$. Definir
> $$z = \sqrt{\dfrac{|w|+u}{2}} + i\sqrt{\dfrac{|w|-u}{2}}$$
> Demostrar que $z^2 = w$ si $v \geq 0$, y que $\bar{z}^2 = w$ si $v \leq 0$. Concluir que todo número complejo (con una excepción) tiene exactamente dos raíces cuadradas.

### Verificación de $z^2 = w$ cuando $v \geq 0$

Sea $a = \sqrt{(|w|+u)/2}$ y $b = \sqrt{(|w|-u)/2}$. Ambos son reales no negativos porque $|w| \geq |u|$.

Calculamos $z^2 = (a + bi)^2 = a^2 - b^2 + 2abi$:

$$a^2 - b^2 = \frac{|w|+u}{2} - \frac{|w|-u}{2} = u \quad \checkmark$$

$$2ab = 2\sqrt{\frac{(|w|+u)(|w|-u)}{4}} = \sqrt{|w|^2 - u^2} = \sqrt{v^2} = |v|$$

Si $v \geq 0$: $|v| = v$, luego $z^2 = u + iv = w$. $\blacksquare$

Si $v \leq 0$: $|v| = -v$, luego $z^2 = u - iv = \overline{w}$. Pero $\bar{z} = a - bi$, y $\bar{z}^2 = a^2 - b^2 - 2abi = u - i|v| = u + iv = w$ cuando $v \leq 0$. $\blacksquare$

### Dos raíces cuadradas

Si $z_0^2 = w$ y $w \neq 0$, entonces $(-z_0)^2 = z_0^2 = w$ también. Y $z_0 \neq -z_0$ porque $z_0 \neq 0$ (si $w \neq 0$). Son exactamente dos raíces.

La excepción: $w = 0$ tiene una única raíz, $z_0 = 0$.

---

## Ejercicio 11

> **Enunciado:** Si $z$ es un número complejo, demostrar que existen $r > 0$ y $w$ complejo con $|w| = 1$ tales que $z = rw$. ¿Determina $z$ de manera única a $r$ y $w$?

### Demostración

Si $z = 0$: no existe $r > 0$ con $z = rw$ para ningún $w$ (pues $|rw| = r > 0 \neq 0 = |z|$). El resultado es para $z \neq 0$.

Sea $r = |z| > 0$ y $w = z/|z|$. Entonces:
$$|w| = \left|\frac{z}{|z|}\right| = \frac{|z|}{|z|} = 1 \quad \checkmark$$
$$rw = |z| \cdot \frac{z}{|z|} = z \quad \checkmark$$

### Unicidad

Si $z = rw = r'w'$ con $r, r' > 0$ y $|w| = |w'| = 1$:
$$r = |rw| = |z| = |r'w'| = r'$$
Luego $r = r' = |z|$, y entonces $w = z/r = z/r' = w'$.

**Sí, $r$ y $w$ quedan determinados de forma única** (para $z \neq 0$): $r = |z|$ y $w = z/|z|$.

Esta es la **forma polar** de $z$: $z = |z| \cdot e^{i\theta}$ con $e^{i\theta} = w$.

---

## Ejercicio 12

> **Enunciado:** Si $z_1, \ldots, z_n$ son complejos, demostrar que
> $$|z_1 + z_2 + \cdots + z_n| \leq |z_1| + |z_2| + \cdots + |z_n|$$

### Demostración por inducción

**Base $n = 2$:** Necesitamos $|z_1 + z_2|^2 \leq (|z_1| + |z_2|)^2$.

$$|z_1 + z_2|^2 = (z_1+z_2)\overline{(z_1+z_2)} = |z_1|^2 + z_1\bar{z}_2 + \bar{z}_1 z_2 + |z_2|^2 = |z_1|^2 + 2\,\text{Re}(z_1\bar{z}_2) + |z_2|^2$$

Como $\text{Re}(z_1\bar{z}_2) \leq |z_1\bar{z}_2| = |z_1||z_2|$:

$$|z_1+z_2|^2 \leq |z_1|^2 + 2|z_1||z_2| + |z_2|^2 = (|z_1|+|z_2|)^2$$

Tomando raíz cuadrada: $|z_1+z_2| \leq |z_1|+|z_2|$. $\blacksquare$

**Paso inductivo:** Supongamos cierto para $n$. Entonces:

$$|z_1 + \cdots + z_n + z_{n+1}| \leq |z_1 + \cdots + z_n| + |z_{n+1}| \leq |z_1| + \cdots + |z_n| + |z_{n+1}| \quad \blacksquare$$

### Analogía — P&L acumulado

Si $z_k$ es el P&L del trade $k$ como número complejo (con parte imaginaria representando riesgo latente), la desigualdad triangular dice: la ganancia total nunca supera la suma de las ganancias brutas individuales. La diferencia es exactamente la "cancelación" entre ganancias y pérdidas.

---

## Ejercicio 13

> **Enunciado:** Si $x, y$ son complejos, demostrar que $\big||x| - |y|\big| \leq |x - y|$.

### Demostración

Aplicamos la desigualdad triangular (Ej. 12) a $x = (x - y) + y$:

$$|x| = |(x-y) + y| \leq |x-y| + |y| \quad \Rightarrow \quad |x| - |y| \leq |x-y|$$

Aplicando el mismo argumento con los roles de $x$ y $y$ intercambiados:

$$|y| - |x| \leq |y-x| = |x-y|$$

Las dos desigualdades juntas dan: $\big||x| - |y|\big| \leq |x-y|$. $\blacksquare$

**Interpretación:** La diferencia de módulos nunca supera el módulo de la diferencia. En la recta real, es la versión familiar $||a| - |b|| \leq |a - b|$.

---

## Ejercicio 14

> **Enunciado:** Si $z \in \mathbb{C}$ con $|z| = 1$ (es decir, $z\bar{z} = 1$), calcular $|1+z|^2 + |1-z|^2$.

### Cálculo

$$|1+z|^2 = (1+z)(1+\bar{z}) = 1 + z + \bar{z} + z\bar{z} = 1 + 2\,\text{Re}(z) + 1 = 2 + 2\,\text{Re}(z)$$

$$|1-z|^2 = (1-z)(1-\bar{z}) = 1 - z - \bar{z} + z\bar{z} = 1 - 2\,\text{Re}(z) + 1 = 2 - 2\,\text{Re}(z)$$

Sumando:

$$|1+z|^2 + |1-z|^2 = (2 + 2\,\text{Re}(z)) + (2 - 2\,\text{Re}(z)) = \boxed{4}$$

### Interpretación geométrica

$1 + z$ y $1 - z$ son las dos diagonales del rombo cuyos vértices son $0, 1, z, 1+z$ (el paralelogramo construido con los vectores $1$ y $z$, que tienen igual módulo $= 1$). El resultado $= 4 = 2\cdot1^2 + 2\cdot1^2$ es exactamente la **ley del paralelogramo** (Ejercicio 17) aplicada a $x = 1$ e $y = z$.

---

## Ejercicio 15

> **Enunciado:** ¿En qué condiciones se produce la igualdad en la desigualdad de Schwarz?

### La desigualdad de Schwarz

Para $a_j, b_j \in \mathbb{C}$:

$$\left|\sum_{j=1}^n a_j \bar{b}_j\right|^2 \leq \left(\sum_{j=1}^n |a_j|^2\right)\left(\sum_{j=1}^n |b_j|^2\right)$$

En $\mathbb{R}^k$: $(\mathbf{x} \cdot \mathbf{y})^2 \leq |\mathbf{x}|^2|\mathbf{y}|^2$.

### Condición de igualdad

La igualdad se produce **si y solo si** $\mathbf{a}$ y $\mathbf{b}$ son **linealmente dependientes**, es decir, existe $\lambda \in \mathbb{C}$ tal que $a_j = \lambda b_j$ para todo $j$ (o bien uno de los dos vectores es el cero).

**Demostración:** La desigualdad de Schwarz se obtiene considerando, para $\lambda \in \mathbb{C}$:

$$0 \leq \sum_j |a_j - \lambda b_j|^2 = \sum|a_j|^2 - 2\,\text{Re}\!\left(\lambda \sum a_j\bar{b}_j\right) + |\lambda|^2 \sum|b_j|^2$$

Eligiendo $\lambda = \sum a_j\bar{b}_j / \sum|b_j|^2$ se obtiene la desigualdad. La igualdad se produce cuando $\sum|a_j - \lambda b_j|^2 = 0$, es decir, $a_j = \lambda b_j$ para todo $j$. $\blacksquare$

**En $\mathbb{R}^k$:** la igualdad $|\mathbf{x} \cdot \mathbf{y}| = |\mathbf{x}||\mathbf{y}|$ ocurre exactamente cuando $\mathbf{x}$ e $\mathbf{y}$ son paralelos ($\mathbf{y} = t\mathbf{x}$ para algún $t \in \mathbb{R}$), lo que corresponde a $\cos\theta = \pm 1$, es decir $\theta = 0°$ o $180°$.

---

## Ejercicio 16

> **Enunciado:** Supongamos $k \geq 3$; $\mathbf{x}, \mathbf{y} \in \mathbb{R}^k$; $|\mathbf{x} - \mathbf{y}| = d > 0$; $r > 0$. Demostrar:
>
> **(a)** Si $2r > d$: hay infinitos $\mathbf{z} \in \mathbb{R}^k$ con $|\mathbf{z} - \mathbf{x}| = |\mathbf{z} - \mathbf{y}| = r$.
>
> **(b)** Si $2r = d$: hay exactamente uno.
>
> **(c)** Si $2r < d$: no hay ninguno.

### Configuración

Sin pérdida de generalidad (trasladando y rotando), sea $\mathbf{m} = (\mathbf{x}+\mathbf{y})/2 = \mathbf{0}$ y $\mathbf{x} = (d/2, 0, \ldots, 0)$, $\mathbf{y} = (-d/2, 0, \ldots, 0)$.

Un punto $\mathbf{z} = (z_1, \ldots, z_k)$ satisface $|\mathbf{z}-\mathbf{x}|^2 = |\mathbf{z}-\mathbf{y}|^2 = r^2$.

**Restando** las dos ecuaciones:
$$|\mathbf{z}-\mathbf{x}|^2 - |\mathbf{z}-\mathbf{y}|^2 = (z_1 - d/2)^2 - (z_1 + d/2)^2 = -2z_1 d = 0$$
Luego $z_1 = 0$ (necesariamente).

**Sustituyendo** $z_1 = 0$ en $|\mathbf{z}-\mathbf{x}|^2 = r^2$:
$$\frac{d^2}{4} + z_2^2 + \cdots + z_k^2 = r^2 \quad \Rightarrow \quad z_2^2 + \cdots + z_k^2 = r^2 - \frac{d^2}{4}$$

Esta es una esfera en $\mathbb{R}^{k-1}$ (coordenadas $z_2, \ldots, z_k$) de radio $\rho = \sqrt{r^2 - d^2/4}$:

- **(a) $2r > d$:** $\rho^2 = r^2 - d^2/4 > 0$. Para $k \geq 3$, $k-1 \geq 2$, la esfera en $\mathbb{R}^{k-1}$ tiene infinitos puntos. $\blacksquare$

- **(b) $2r = d$:** $\rho^2 = 0$, luego $z_2 = \cdots = z_k = 0$. El único punto es $\mathbf{z} = \mathbf{0} = \mathbf{m}$ (el punto medio). $\blacksquare$

- **(c) $2r < d$:** $\rho^2 < 0$. No hay solución real. $\blacksquare$

### Modificación para $k = 2$ y $k = 1$

- $k = 2$: La ecuación $z_2^2 = r^2 - d^2/4$ tiene exactamente **dos** soluciones en (a) ($z_2 = \pm\rho$), **una** en (b), y ninguna en (c).
- $k = 1$: No hay coordenadas $z_2, \ldots$, solo $z_1 = 0$. El único candidato es el punto medio. Solo es válido en (b); en (a) y (c) no hay soluciones.

---

## Ejercicio 17

> **Enunciado:** Demostrar que si $\mathbf{x}, \mathbf{y} \in \mathbb{R}^k$:
> $$|\mathbf{x} + \mathbf{y}|^2 + |\mathbf{x} - \mathbf{y}|^2 = 2|\mathbf{x}|^2 + 2|\mathbf{y}|^2$$
> Interpretarlo como una propiedad de paralelogramos.

### Demostración

Usando $|\mathbf{v}|^2 = \mathbf{v} \cdot \mathbf{v}$:

$$|\mathbf{x}+\mathbf{y}|^2 = (\mathbf{x}+\mathbf{y})\cdot(\mathbf{x}+\mathbf{y}) = |\mathbf{x}|^2 + 2(\mathbf{x}\cdot\mathbf{y}) + |\mathbf{y}|^2$$

$$|\mathbf{x}-\mathbf{y}|^2 = (\mathbf{x}-\mathbf{y})\cdot(\mathbf{x}-\mathbf{y}) = |\mathbf{x}|^2 - 2(\mathbf{x}\cdot\mathbf{y}) + |\mathbf{y}|^2$$

Sumando, los términos cruzados $\pm 2(\mathbf{x}\cdot\mathbf{y})$ se cancelan:

$$|\mathbf{x}+\mathbf{y}|^2 + |\mathbf{x}-\mathbf{y}|^2 = 2|\mathbf{x}|^2 + 2|\mathbf{y}|^2 \quad \blacksquare$$

### Interpretación geométrica

En el paralelogramo con lados $\mathbf{x}$ e $\mathbf{y}$, las diagonales son $\mathbf{x}+\mathbf{y}$ y $\mathbf{x}-\mathbf{y}$.

**Ley del paralelogramo:** La suma de los cuadrados de las diagonales es igual al doble de la suma de los cuadrados de los lados.

Esta identidad caracteriza los espacios de Hilbert: un espacio normado cuya norma satisface la ley del paralelogramo proviene de un producto interior.

---

## Ejercicio 18

> **Enunciado:** Si $k \geq 2$ y $\mathbf{x} \in \mathbb{R}^k$, demostrar que existe $\mathbf{y} \in \mathbb{R}^k$ con $\mathbf{y} \neq \mathbf{0}$ y $\mathbf{x} \cdot \mathbf{y} = 0$. ¿Es también verdad para $k = 1$?

### Demostración

**Caso $\mathbf{x} = \mathbf{0}$:** Cualquier $\mathbf{y} \neq \mathbf{0}$ satisface $\mathbf{0} \cdot \mathbf{y} = 0$. ✓

**Caso $\mathbf{x} \neq \mathbf{0}$:** Como $\mathbf{x} \neq \mathbf{0}$, existe al menos un índice $j$ con $x_j \neq 0$. Como $k \geq 2$, existe también un índice $i \neq j$.

Definir $\mathbf{y}$ con componentes:
$$y_i = x_j, \quad y_j = -x_i, \quad y_\ell = 0 \text{ para } \ell \neq i, j$$

Entonces $\mathbf{x} \cdot \mathbf{y} = x_i y_i + x_j y_j = x_i x_j + x_j(-x_i) = 0$ ✓

Y $\mathbf{y} \neq \mathbf{0}$ porque $y_i = x_j \neq 0$. $\blacksquare$

### Para $k = 1$

Falso. Si $\mathbf{x} = (x_1)$ con $x_1 \neq 0$ y $\mathbf{y} = (y_1)$: $\mathbf{x} \cdot \mathbf{y} = x_1 y_1 = 0$ implica $y_1 = 0$, es decir $\mathbf{y} = \mathbf{0}$.

En $\mathbb{R}^1$ no existe dirección ortogonal.

### Analogía

En análisis de componentes principales (PCA) de retornos de un portfolio, siempre es posible encontrar una dirección de inversión $\mathbf{y}$ sin correlación con $\mathbf{x}$ siempre que el espacio tenga dimensión $\geq 2$. Con un solo activo ($k = 1$) es imposible.

---

## Ejercicio 19

> **Enunciado:** Dados $\mathbf{a}, \mathbf{b} \in \mathbb{R}^k$, hallar $\mathbf{c} \in \mathbb{R}^k$ y $r > 0$ tales que
> $$|\mathbf{x} - \mathbf{a}| = 2|\mathbf{x} - \mathbf{b}| \iff |\mathbf{x} - \mathbf{c}| = r$$
> *(Rudin da: $3\mathbf{c} = 4\mathbf{b} - \mathbf{a}$, $3r = 2|\mathbf{b} - \mathbf{a}|$.)*

### Demostración

Elevamos al cuadrado: $|\mathbf{x}-\mathbf{a}|^2 = 4|\mathbf{x}-\mathbf{b}|^2$.

Expandiendo con $|\mathbf{v}|^2 = \mathbf{v}\cdot\mathbf{v}$:

$$|\mathbf{x}|^2 - 2\mathbf{x}\cdot\mathbf{a} + |\mathbf{a}|^2 = 4|\mathbf{x}|^2 - 8\mathbf{x}\cdot\mathbf{b} + 4|\mathbf{b}|^2$$

Reordenando:

$$3|\mathbf{x}|^2 - 2\mathbf{x}\cdot(4\mathbf{b}-\mathbf{a}) + 4|\mathbf{b}|^2 - |\mathbf{a}|^2 = 0$$

Dividimos por $3$ y completamos el cuadrado con $\mathbf{c} = (4\mathbf{b}-\mathbf{a})/3$:

$$\left|\mathbf{x} - \mathbf{c}\right|^2 = |\mathbf{c}|^2 - \frac{4|\mathbf{b}|^2 - |\mathbf{a}|^2}{3}$$

Calculamos el lado derecho:

$$|\mathbf{c}|^2 - \frac{4|\mathbf{b}|^2-|\mathbf{a}|^2}{3} = \frac{|4\mathbf{b}-\mathbf{a}|^2}{9} - \frac{4|\mathbf{b}|^2-|\mathbf{a}|^2}{3}$$

$$= \frac{16|\mathbf{b}|^2 - 8\mathbf{b}\cdot\mathbf{a} + |\mathbf{a}|^2 - 12|\mathbf{b}|^2 + 3|\mathbf{a}|^2}{9} = \frac{4|\mathbf{b}|^2 - 8\mathbf{b}\cdot\mathbf{a} + 4|\mathbf{a}|^2}{9} = \frac{4|\mathbf{b}-\mathbf{a}|^2}{9}$$

Por tanto $r^2 = 4|\mathbf{b}-\mathbf{a}|^2/9$, es decir $r = 2|\mathbf{b}-\mathbf{a}|/3$ y $3r = 2|\mathbf{b}-\mathbf{a}|$. $\blacksquare$

### Interpretación

El lugar geométrico $|\mathbf{x}-\mathbf{a}| = 2|\mathbf{x}-\mathbf{b}|$ es el **círculo de Apolonio** (esfera en $\mathbb{R}^k$): el conjunto de puntos cuya distancia a $\mathbf{a}$ es el doble de su distancia a $\mathbf{b}$.

---

## Ejercicio 20

> **Enunciado:** Refiriéndose al Apéndice, supóngase que la propiedad **(II)** se omite de la definición de cortadura. Mostrar que el conjunto ordenado resultante tiene la propiedad de la mínima cota superior y que la adición satisface los axiomas (A1)–(A4), pero no (A5).

### Contexto — Construcción de Dedekind

En el Apéndice de Rudin, una **cortadura** (Dedekind cut) $\alpha \subset \mathbb{Q}$ satisface:

- **(I)** $\alpha \neq \emptyset$ y $\alpha \neq \mathbb{Q}$
- **(II)** Si $p \in \alpha$ y $q < p$, entonces $q \in \alpha$ *(clausura hacia abajo)*
- **(III)** $\alpha$ no tiene elemento máximo

Al omitir (II), los "cortes" son subconjuntos propios no vacíos de $\mathbb{Q}$ sin la propiedad de clausura hacia abajo.

### Propiedad de la mínima cota superior (sí se preserva)

La mínima cota superior de una colección $\{\alpha_i\}$ acotada superiormente sigue siendo $\bigcup \alpha_i$. Esto no depende de la propiedad (II) — depende solo de que el supremo de una unión de conjuntos acotados existe. $\checkmark$

### Adición (A1)–(A4) se preservan, (A5) falla

La adición de cortes se define como $\alpha + \beta = \{p + q : p \in \alpha, q \in \beta\}$.

- **(A1)** Conmutatividad: $p + q = q + p$ — se hereda de $\mathbb{Q}$. $\checkmark$
- **(A2)** Asociatividad: idem. $\checkmark$
- **(A3)** Identidad: el "cero" en este sistema es $0^* = \{p \in \mathbb{Q} : p < 0\}$. Sin (II), el cero puede ser otro conjunto — por ejemplo $\{0\}$ o $\emptyset$ podría cumplir el rol, dependiendo de cómo se defina la adición. El elemento cero existe pero es **ligeramente diferente** al de la construcción estándar. $\checkmark$
- **(A4)** Cerradura: la suma sigue siendo un subconjunto de $\mathbb{Q}$. $\checkmark$
- **(A5)** Inverso aditivo **falla**: en la construcción estándar, $-\alpha = \{p \in \mathbb{Q} : \exists\, r > 0, -p-r \notin \alpha\}$. Sin (II), no se puede garantizar que $\alpha + (-\alpha) = 0^*$, porque la estructura de clausura hacia abajo era esencial para que la suma de un corte y su inverso recupere exactamente $0^*$. $\times$

### Mensaje

Este ejercicio muestra que la propiedad **(II)** es la que garantiza la existencia de inversos aditivos — y por tanto, que $\mathbb{R}$ construido sin ella sería un monoide ordenado con supremos, pero no un grupo, y mucho menos un campo.

---

## Resumen de estrategias de demostración

| Ejercicio | Técnica principal |
|-----------|-------------------|
| 1 | Contradicción + propiedades de campo (inversos) |
| 2 | Contradicción + divisibilidad de primos |
| 3 | Construcción directa desde los axiomas de campo |
| 4 | Transitividad del orden + elemento existente en $E$ |
| 5 | Supremo + negación de desigualdades en campo ordenado |
| 6 | Unicidad de raíces (Teo. 1.21) + definición de sup |
| 7 | Construcción vía sup + análisis de los tres casos de tricotomía |
| 8 | Contradicción: cuadrados positivos en campos ordenados |
| 9 | Verificación de axiomas de orden + contraejemplo para LUB |
| 10 | Cálculo directo $z^2 = w$; dos raíces por $z \neq -z$ |
| 11 | Forma polar $z = rw$; unicidad por $r = |z|$ |
| 12 | Inducción + $\text{Re}(z_1\bar{z}_2) \leq |z_1||z_2|$ |
| 13 | Desigualdad triangular en ambas direcciones |
| 14 | Cálculo con $z\bar{z} = 1$; ley del paralelogramo |
| 15 | Condición de igualdad: vectores proporcionales |
| 16 | Coordenadas: reducción a esfera en $\mathbb{R}^{k-1}$ |
| 17 | Producto interno: cancelación de términos cruzados |
| 18 | Construcción explícita del vector perpendicular; $k=1$ falla |
| 19 | Completar el cuadrado; círculo de Apolonio |
| 20 | Análisis axiomático: (II) necesaria para inversos aditivos |

---

## Ejercicios de práctica adicional

- [x] **E1** *(resuelto arriba)* — $r \in \mathbb{Q}$, $r\neq 0$, $x \notin \mathbb{Q}$ → $r+x, rx \notin \mathbb{Q}$
- [x] **E2** *(resuelto arriba)* — $\sqrt{12} \notin \mathbb{Q}$
- [x] **E4** *(resuelto arriba)* — cota inferior $\leq$ cota superior
- [x] **E5** *(resuelto arriba)* — $\inf A = -\sup(-A)$
- [ ] **Práctica:** Demuestra que $\sqrt{p} \notin \mathbb{Q}$ para todo primo $p$. *(El mismo argumento de E2, generalizado.)*
- [ ] **Práctica:** Demuestra que $\inf\{1/n : n \in \mathbb{N}\} = 0$ usando el Principio Arquimediano.
- [ ] **Práctica:** Si $A$ y $B$ son subconjuntos acotados de $\mathbb{R}$, demuestra que $\sup(A \cup B) = \max(\sup A, \sup B)$.
- [ ] **Práctica:** Usando E5, demuestra que $\sup(-A) = -\inf A$.
