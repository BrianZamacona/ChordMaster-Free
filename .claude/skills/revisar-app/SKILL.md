---
name: revisar-app
description: Revisa una app de guitarra del teléfono a través de Enlace Móvil (computer use), anota qué ideas sirven para Learn & Strum y las deja en docs/revision_apps.md. Úsalo con el nombre de una app o de una familia del catálogo, por ejemplo "/revisar-app 85 metal guitar licks" o "/revisar-app familia jam".
---

# Revisar una app del teléfono

Workflow para aprovechar ideas de otras apps de guitarra en Learn & Strum, como se hizo con la
app de Gibson. Se toman **ideas** (qué módulos hay, cómo se practica, cómo se organiza, qué
mide), nunca **contenido**: los licks, las tablaturas, el audio, los textos, las imágenes y los
nombres de artistas de esas apps tienen dueño.

Argumento: `$ARGUMENTS` = el nombre de una app del catálogo, o `familia <id>` para revisar una
familia entera (ver `docs/revision_apps.md`). Sin argumento, sigue con la primera app
`pendiente` del catálogo, en el orden de las familias.

Todo lo que se escribe para el usuario va en español.

## 0. Antes de empezar

1. Lee `docs/revision_apps.md`: la familia de la app, su estado y lo que ya se anotó de las
   apps hermanas (no repitas una idea ya anotada: solo di qué cambia).
2. Lee en `CLAUDE.md` las secciones del área que toca la familia (Licks y riffs, Escalas,
   Círculo, Lecciones, Audio…), para saber qué ya existe y qué decisiones del usuario hay.
3. Carga el skill `anthropic-skills:computer-use` y pide acceso a **Enlace Móvil**
   (`request_access` con `["Enlace Móvil"]`). Si el teléfono no da permiso de mostrar la
   pantalla, pídele al usuario que lo acepte en el teléfono y espera; no sigas a ciegas.
4. Abre la app desde la lista de apps de Enlace Móvil. Si no está instalada, márcala
   `no instalada` en el catálogo y pasa a la siguiente.

## 1. Recorrer la app

Recorre cada pantalla a la que se llega sin pagar, sin iniciar sesión y sin aceptar nada en
nombre del usuario:
- **No compres, no te suscribas, no inicies sesión, no aceptes términos ni permisos y no
  toques anuncios.** Si algo está detrás de un pago o un registro, anota solo lo que se ve
  desde fuera (el nombre de la función y cómo se presenta) y sigue.
- No toques enlaces que salgan de la app.
- Capturas: solo en el scratchpad de la sesión, nunca en el repo (son de terceros).
- Usa `computer_batch` para recorrer listas (desplazar + captura) y `zoom` para leer texto.

En cada app anota:
1. **Módulos**: qué secciones tiene y cómo se navega entre ellas.
2. **Cómo se practica**: tempo, bucle, cuenta previa, lento/rápido, micrófono, metrónomo, pista
   de acompañamiento, repetir un tramo, marcar como aprendido.
3. **Notación**: tablatura, partitura, diagramas, digitaciones, técnicas que dibuja (bends,
   slides, tapping…), cómo marca el ritmo.
4. **Organización**: niveles, estilos, filtros, búsqueda, favoritos, progreso, rachas, logros.
5. **Audio**: qué suena (grabado o sintético), qué controla el usuario (tempo, mezcla, tono).
6. **Lo que hace mejor que nosotros**, y **lo que hacemos mejor**.

## 2. Comparar con Learn & Strum

Por cada idea, busca en el código si ya existe (`Grep` en `lib/` y `CLAUDE.md`) y clasifícala:
- `ya está`: existe igual o mejor. Di dónde (archivo o pantalla).
- `parcial`: existe pero le falta algo concreto. Di qué.
- `nueva`: no existe.

Y filtra cada idea `parcial` o `nueva` contra las reglas del proyecto:
- **Contenido**: se puede escribir una frase original que enseñe la misma técnica; nunca copiar
  un lick, una tablatura, un texto o una progresión reconocible. Sin artistas reales.
- **Fuentes de verdad**: los datos musicales salen de un generador o se componen con tests que
  verifican lo que afirman (`CLAUDE.md`, "Principio rector").
- **Decisiones vigentes**: solo sostenidos, afinación estándar por ahora, diseño vertical (nada
  de filas que se deslizan de lado), sin fotos ni imágenes de terceros, audio sintetizado
  (no hay archivos de audio).
- **Licencia y producto**: si la idea pide una decisión de producto, musical o de licencia, no
  la decidas: va a "Para decidir".

## 3. Anotarlo

En `docs/revision_apps.md`, en la sección de la familia:
1. Cambia el estado de la app (`pendiente` → `revisada`, `no instalada` o `de pago`) y la fecha.
2. Agrega su ficha con el formato de "Plantilla de ficha" (al final del documento): resumen en
   2–3 líneas y la tabla de ideas (idea, estado, dónde encaja, esfuerzo S/M/L, notas).
3. Si con ella se terminó la familia, escribe el **resumen de la familia**: las ideas que se
   repiten, ordenadas por valor para el usuario, y la lista "Para decidir".

No edites código en este workflow: solo el documento.

## 4. Cerrar

1. `git status`: solo debe cambiar `docs/revision_apps.md`.
2. Commit en español ("Revisión de apps: <app o familia>"), push, PR hacia `main` con Auto-fix
   (flujo de `CLAUDE.md`). El PR dice qué apps se revisaron y cuáles quedaron sin ver y por qué.
3. Al usuario: las 3–5 ideas con más valor de lo revisado y las decisiones que necesita tomar.
   Lo que el usuario apruebe se implementa después como una tarea normal (rama, tests, PR), no
   dentro de este workflow.
