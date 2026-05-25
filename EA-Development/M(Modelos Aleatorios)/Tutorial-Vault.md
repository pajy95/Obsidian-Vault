---
tags: [tutorial, obsidian]
---

# Tutorial — Cómo usar este vault para estudiar

> Lee esta nota en **Reading View**: presiona `Ctrl + E`

---

## Parte 1 — Navegación básica

### La estructura del vault

```
M(Modelos Aleatorios)/
├── Dashboard.md        ← tu panel de control (empieza aquí cada sesión)
├── Temario.md          ← lista de todos los temas con checkboxes
├── Tutorial-Vault.md   ← este archivo
├── Libros/
│   └── rudin.pdf
├── Analisis I/
│   ├── Sesion-01-Numeros-Reales.md   ← primera sesión (ya completa)
│   ├── 01-Funciones.md
│   ├── 02-Sucesiones.md
│   └── ...
└── Probabilidad/
    ├── P01-Conjuntos.md
    └── P02-Probabilidad-Discreta.md
```

### Cómo abrir una nota

- **Click** en cualquier archivo del panel izquierdo
- **`Ctrl + O`** → búsqueda rápida de notas por nombre
- **`[[doble corchete]]`** dentro de una nota → link clicable a otra nota

---

## Parte 2 — Reading View (ver fórmulas matemáticas)

Este es el paso más importante. Las fórmulas como `$\sup E$` se ven así en modo edición:

```
$\sup E = \alpha$
```

Pero en Reading View se renderizan como matemáticas reales.

### Cómo activar Reading View

| Método | Acción |
|--------|--------|
| Teclado | `Ctrl + E` |
| Ícono | Libro abierto arriba a la derecha de la nota |
| Permanente | Click derecho en pestaña → "Open as reading view" |

### Tipos de fórmulas

| Sintaxis | Tipo | Ejemplo |
|----------|------|---------|
| `$...$` | Inline (dentro del texto) | El supremo $\sup E$ es único |
| `$$...$$` | Bloque (centrado, grande) | $$\alpha = \sup E$$ |

---

## Parte 3 — El Dashboard

Abre [[Dashboard]] en Reading View. Verás:

**Barra de progreso**
```
█████░░░░░░░░░░░░░░░ 10%  (2/18 ejercicios)
```
Se actualiza automáticamente cuando marcas ejercicios.

**Listas de tareas vivas** — Dataview escanea todas las notas y agrupa los ejercicios pendientes. No necesitas actualizar nada manualmente.

---

## Parte 4 — Marcar ejercicios como completados

En cualquier nota, los ejercicios se ven así en modo edición:

```markdown
- [ ] E1. Demostrar que sup E = 1
- [ ] E2. Sea E el conjunto de precios...
```

Para marcar como completado:
1. En **Reading View**: click directo sobre el checkbox ☑
2. En **Edit View**: cambia `[ ]` por `[x]`

El Dashboard actualiza el conteo automáticamente.

---

## Parte 5 — Atajos de teclado esenciales

| Atajo | Acción |
|-------|--------|
| `Ctrl + E` | Alternar Edit / Reading View |
| `Ctrl + O` | Búsqueda rápida de notas |
| `Ctrl + P` | Paleta de comandos (todo lo que Obsidian puede hacer) |
| `Ctrl + Click` | Abrir link en nueva pestaña |
| `Ctrl + \` | Dividir pantalla (dos notas lado a lado) |
| `Ctrl + G` | Graph view — mapa visual de todas las notas |

---

## Parte 6 — Flujo de estudio recomendado

```
INICIO DE SESIÓN
      ↓
Abrir Dashboard → ver qué temas faltan
      ↓
Abrir la nota del tema (ej: Sesion-01-Numeros-Reales)
      ↓
Ctrl+E → Reading View → leer con fórmulas renderizadas
      ↓
Preguntar dudas en Claude Code (chat de la derecha)
      ↓
Claude actualiza/crea notas con la explicación
      ↓
Volver a la nota en Obsidian (se actualiza automáticamente)
      ↓
Intentar ejercicios → marcar checkbox al completar
      ↓
Dashboard refleja el progreso
```

---

## Parte 7 — Graph View

Presiona `Ctrl + G` para ver el mapa de conocimiento.

Cada nota es un nodo. Los links `[[entre notas]]` son las conexiones. Conforme avances en el curso, el grafo crece y puedes ver cómo conectan los conceptos entre sí.

Útil para detectar temas aislados que aún no has conectado con el resto.

---

## Parte 8 — Split View (recomendado para estudiar)

Puedes tener **dos notas abiertas al mismo tiempo**:

1. Abre la sesión de Rudin (`Sesion-01-Numeros-Reales`)
2. `Ctrl + \` para dividir la pantalla
3. En el panel derecho abre el Dashboard o una nota de ejercicios

Así tienes teoría a la izquierda y ejercicios a la derecha.

---

## Resumen rápido

```
Ctrl+E          → ver fórmulas matemáticas
Ctrl+O          → buscar cualquier nota
Ctrl+G          → mapa visual del conocimiento
Click checkbox  → marcar ejercicio como hecho
[[nombre]]      → navegar entre notas
Dashboard.md    → tu panel de control
```
