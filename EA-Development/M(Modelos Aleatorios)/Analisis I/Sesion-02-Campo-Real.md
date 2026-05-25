---
tags: [analisis, rudin, cap1, campo-real, arquimediano]
refs: [Rudin Cap. 1 — Secs. 1.17 a 1.21]
---

# Sesión 02 — El Campo Real (Rudin Cap. 1 cont.)

> Prerequisito: [[Sesion-01-Numeros-Reales]]
> Lee en Reading View: `Ctrl + E`

---

## 1. Campo Ordenado (Rudin Def. 1.17)

Un **campo ordenado** es un campo $F$ que también es conjunto ordenado, con dos propiedades extra:

1. Si $y < z$ entonces $x + y < x + z$ (el orden es compatible con la suma)
2. Si $x > 0$ e $y > 0$ entonces $xy > 0$ (el producto de positivos es positivo)

$\mathbb{Q}$ es un campo ordenado. $\mathbb{R}$ también — y además tiene la propiedad de la mínima cota superior.

### Consecuencias inmediatas (Rudin Prop. 1.18)

En todo campo ordenado:

| Proposición | Fórmula |
|-------------|---------|
| Negativo de positivo | $x > 0 \Rightarrow -x < 0$ |
| Multiplicar por positivo preserva orden | $x > 0,\ y < z \Rightarrow xy < xz$ |
| Multiplicar por negativo invierte orden | $x < 0,\ y < z \Rightarrow xy > xz$ |
| Todo cuadrado es no negativo | $x \neq 0 \Rightarrow x^2 > 0$ |
| Recíprocos invierten orden | $0 < x < y \Rightarrow 0 < \tfrac{1}{y} < \tfrac{1}{x}$ |

### Analogía — Trading

La propiedad 1 (orden compatible con suma) es lo que hace que el P&L sea consistente:

Si tu balance $B_1 < B_2$, entonces después de sumar la misma ganancia $g$:
$$B_1 + g < B_2 + g$$

Sin esto, la comparación de balances no tendría sentido.

La propiedad del cuadrado ($x^2 > 0$) aparece en la **varianza**: siempre es positiva porque es promedio de cuadrados.

---

## 2. El Teorema de Existencia de $\mathbb{R}$ (Rudin Teo. 1.19)

> **Teorema 1.19:** Existe un campo ordenado $\mathbb{R}$ con la propiedad de la mínima cota superior. Además $\mathbb{Q} \subset \mathbb{R}$.

Rudin no demuestra esto aquí — la construcción formal (cortes de Dedekind) está en el Apéndice. Lo que importa es el **significado**: los reales existen, son un campo ordenado, y **todo subconjunto acotado tiene supremo**.

Este teorema es el fundamento de todo el análisis. Sin él, no podríamos hablar de límites, continuidad ni integral.

---

## 3. Propiedad Arquimediana y Densidad de $\mathbb{Q}$ (Rudin Teo. 1.20)

Este teorema tiene dos partes cruciales:

### Parte (a) — Propiedad Arquimediana

> Si $x \in \mathbb{R}$, $y \in \mathbb{R}$, $x > 0$, entonces existe un entero positivo $n$ tal que:
> $$nx > y$$

**En castellano:** no importa cuán grande sea $y$ ni cuán pequeño sea $x$ — siempre puedes sumar $x$ suficientes veces para superar $y$.

**Demostración (idea):** Supón que $nx \leq y$ para todo $n$. Entonces $y$ es cota superior del conjunto $\{nx : n \in \mathbb{N}\}$. Por la propiedad de $\mathbb{R}$, existe $\alpha = \sup\{nx\}$. Pero entonces $\alpha - x < \alpha$, así que existe $mx$ con $mx > \alpha - x$, lo que da $(m+1)x > \alpha$. Contradicción.

#### Analogía — Trading

El Principio Arquimediano dice que **no existen infinitesimales en $\mathbb{R}$**: ningún número positivo es tan pequeño que no pueda acumularse hasta superar cualquier límite.

En trading: el spread (por pequeño que sea) siempre puede acumularse en suficientes trades para destruir una cuenta. No hay "costo tan pequeño que sea irrelevante".

#### Analogía — Electricidad

Una resistencia de $0.001\ \Omega$ en un circuito: si aplicas suficiente corriente ($nx > y$), el voltaje en esa resistencia supera cualquier umbral. No existe resistencia "tan pequeña que no importe".

---

### Parte (b) — Densidad de $\mathbb{Q}$ en $\mathbb{R}$

> Si $x, y \in \mathbb{R}$ con $x < y$, entonces existe $p \in \mathbb{Q}$ tal que:
> $$x < p < y$$

**En castellano:** entre dos números reales cualesquiera siempre hay un racional.

**Demostración (esquema de Rudin):**
1. Como $y - x > 0$, por la propiedad arquimediana existe $n \in \mathbb{N}$ con $n(y-x) > 1$
2. Existe entero $m$ con $m-1 \leq nx < m$
3. Entonces $nx < m \leq 1 + nx < ny$
4. Dividiendo: $x < \dfrac{m}{n} < y$ ✓

#### Analogía — Precio de activos

Entre dos precios reales cualesquiera (por cercanos que estén), siempre existe un precio racional posible. Esto justifica que el order book con precios de 2 decimales "cubre" toda la recta real a efectos prácticos — nunca hay un gap sin precio racional posible.

---

## 4. Existencia de Raíces $n$-ésimas (Rudin Teo. 1.21)

> **Teorema 1.21:** Para todo $x > 0$ real y $n \geq 1$ entero, existe un único $y > 0$ real tal que $y^n = x$.
> Se escribe $y = \sqrt[n]{x} = x^{1/n}$.

**Idea de la demostración (usando sup):**

Sea $E = \{t > 0 : t^n < x\}$.

- $E$ no es vacío: $t = \frac{x}{1+x}$ cumple $t^n < t < x$ ✓
- $E$ está acotado superiormente: si $t > 1+x$ entonces $t^n > t > x$, así que $1+x$ es cota ✓
- Por Teo. 1.19: $y = \sup E$ existe en $\mathbb{R}$
- Rudin demuestra por contradicción que $y^n = x$ (ni $y^n < x$ ni $y^n > x$ son posibles)

### Analogía — Trading

El precio de ejercicio de una opción financiera: dado cualquier payoff positivo $x$, siempre existe un precio de activo $y$ (positivo real) tal que $y^n = x$ para cualquier estructura de power option con exponente $n$. Los reales garantizan que ese precio existe.

### Analogía — Electricidad

Dado un nivel de potencia $P = I^2 R$, siempre existe una corriente $I = \sqrt{P/R}$ real que lo produce. El Teorema 1.21 es la garantía matemática de que esa raíz cuadrada existe en $\mathbb{R}$.

---

## 5. Resumen del Capítulo 1

```
Racionales (ℚ)
  → Campo ordenado ✓
  → Tiene huecos (√2 ∉ ℚ) ✗
  → No tiene propiedad de mínima cota superior ✗

Reales (ℝ)
  → Campo ordenado ✓
  → Sin huecos ✓
  → Propiedad de mínima cota superior ✓  ← el axioma que hace funcionar el análisis
  → Propiedad arquimediana ✓             ← no hay infinitesimales
  → ℚ es denso en ℝ ✓                   ← entre dos reales siempre hay un racional
  → Raíces n-ésimas existen ✓
```

---

## Ejercicios

- [ ] **E1.** Usa la propiedad arquimediana para demostrar que $\inf\{1/n : n \in \mathbb{N}\} = 0$.
- [ ] **E2.** Encuentra un racional $p$ con $\sqrt{2} < p < \sqrt{3}$. ¿Cuántos existen?
- [ ] **E3. (Trading)** Sea $x = 0.0001$ (1 pip en EURUSD) e $y = 10{,}000$ (balance en USD). Encuentra el $n$ mínimo que garantiza $nx > y$. ¿Qué representa en términos de trades?
- [ ] **E4.** Demuestra que entre dos racionales siempre hay un irracional. *(Pista: usa $\sqrt{2}$)*
- [ ] **E5.** ¿Por qué $x^2 > 0$ para todo $x \neq 0$? ¿Qué implica eso sobre la varianza de cualquier conjunto de datos con al menos un valor distinto a la media?
