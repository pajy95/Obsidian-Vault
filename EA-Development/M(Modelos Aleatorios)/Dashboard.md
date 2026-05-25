---
tags: [dashboard, maestria]
---

# Dashboard — Modelos Aleatorios

## Progreso por materia

```dataviewjs
const analisis = dv.pages('"M(Modelos Aleatorios)/Analisis I"');
const prob = dv.pages('"M(Modelos Aleatorios)/Probabilidad"');

let totalTasks = 0, doneTasks = 0;

for (let p of [...analisis, ...prob]) {
  let tasks = p.file.tasks;
  totalTasks += tasks.length;
  doneTasks += tasks.filter(t => t.completed).length;
}

const pct = totalTasks > 0 ? Math.round((doneTasks / totalTasks) * 100) : 0;
const bar = "█".repeat(Math.round(pct / 5)) + "░".repeat(20 - Math.round(pct / 5));

dv.paragraph(`**Progreso total:** ${bar} ${pct}% (${doneTasks}/${totalTasks} ejercicios)`);
```

---

## Ejercicios pendientes — Análisis I

```dataview
TASK
FROM "M(Modelos Aleatorios)/Analisis I"
WHERE !completed
SORT file.name ASC
```

## Ejercicios pendientes — Probabilidad

```dataview
TASK
FROM "M(Modelos Aleatorios)/Probabilidad"
WHERE !completed
SORT file.name ASC
```

---

## Ejercicios completados

```dataview
TASK
FROM "M(Modelos Aleatorios)"
WHERE completed
SORT completion DESC
```

---

## Notas por materia

```dataview
TABLE refs AS "Referencia", tags AS "Tags"
FROM "M(Modelos Aleatorios)"
WHERE file.name != "Dashboard" AND file.name != "Temario" AND file.name != "README"
SORT file.folder ASC, file.name ASC
```

---

## Sesiones de estudio

```dataview
TABLE file.mtime AS "Última edición"
FROM "M(Modelos Aleatorios)/Analisis I" OR "M(Modelos Aleatorios)/Probabilidad"
WHERE contains(file.name, "Sesion")
SORT file.mtime DESC
```
