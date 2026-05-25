# Optimizar memoria y tokens con Claude Code

## 👤 Jose
Hola Claude, como bien sabes al parecer tenemos problemas con la memoria. Quiero que me ayudes a solventar este problema. Crees que si uso claude code desde una terminal de codigo(recomiendame una, la mejor), obsidian para organizar informacion y que puedas acceder a ella de manera local, puedas mejorar el consumo de tokens y mejorar la fluidez de trabajo.

## 🤖 Claude
 Hola Jose! Sí, el problema de memoria/contexto es real y frustrante cuando trabajas en proyectos largos como tus EAs.

Déjame ser honesto sobre lo que funciona y lo que no antes de recomendarte un stack.

## El problema real

El límite de contexto de Claude no es solo de "memoria entre sesiones" — es que cada conversación empieza desde cero, y proyectos complejos como tus EAs MQL4/5 consumen tokens rápidamente cuando tienes que re-explicar todo.

## ¿Claude Code + Obsidian resuelve esto?

**Parcialmente sí, con matices importantes:**

**Claude Code (terminal)** — sí te ayuda porque:
- Lee archivos directamente del filesystem, no necesitas pegar código
- Mantiene contexto del proyecto mientras la sesión está activa
- Opera sobre múltiples archivos a la vez
- **Terminal recomendada: Windows Terminal + WSL2** si estás en Windows, o simplemente la terminal nativa si usas Linux/Mac

**Obsidian como "memoria externa"** — esta es la parte más valiosa:
- Puedes crear un vault con documentos de contexto que Claude Code lee al inicio de cada sesión
- Un archivo `CONTEXT.md` con: estado actual del EA, decisiones tomadas, parámetros probados, resultados IS/OOS
- Funciona como tu "Prompt Maestro" pero vivo y actualizable

## Stack que te recomendaría

```
Obsidian Vault (tu cerebro externo)
├── /EAs/DonchianEA/CONTEXT.md      ← estado actual
├── /EAs/DonchianEA/RESULTADOS.md   ← backtests IS/OOS
├── /EAs/DonchianEA/DECISIONES.md   ← log de cambios
└── /methodology/PromptMaestro.md   ← tu workflow

Claude Code (lee estos archivos al inicio)
└── "Lee CONTEXT.md y continúa desde ahí"
```

## Lo que NO resuelve

- El límite de contexto *dentro* de una sesión larga sigue existiendo
- Claude Code no tiene memoria persistente entre sesiones tampoco — la diferencia es que tú le das el contexto leyendo archivos locales, más eficientemente que pegando texto

## Mi recomendación concreta

1. **Terminal**: Windows Terminal con WSL2 (si estás en Windows) — la mejor experiencia para Claude Code
2. **Obsidian**: crea un vault estructurado por proyecto con un `CONTEXT.md` estandarizado
3. **Workflow**: al inicio de cada sesión de Claude Code, un prompt corto: *"Lee los archivos en /ruta/DonchianEA/ y continúa el desarrollo"*

¿Quieres que te diseñe una plantilla de `CONTEXT.md` específica para tu metodología de desarrollo de EAs? Podría ser muy útil dado el nivel de detalle que manejas en tus proyectos.

