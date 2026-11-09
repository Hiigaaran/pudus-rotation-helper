# pudus-rotation-helper
Addon compatible con World of Warcraft: Forever que asiste visualmente con la rotación de habilidades configurada

Ayuda visual para la rotación de habilidades en **World of Warcraft: Forever**: una barra con las próximas habilidades de una rotación que configura el jugador y un resaltado del botón correspondiente, también en la interfaz beta de mando.

El addon solo muestra sugerencias; no lanza habilidades.

## Estructura

| Archivo | Qué hace |
| --- | --- |
| `PudusRotationHelper.toc` | Metadatos y orden de carga (Interface 16001, por verificar en el cliente final) |
| `Core/Rotation.lua` | Motor de rotación en Lua puro, testeable fuera del juego |
| `Core/Recorder.lua` | Grabador de secuencias pulsando habilidades |
| `Core/Import.lua` | Importar y exportar rotaciones en markdown |
| `UI/Manual.lua` | Manual de uso compartido y su sección en el panel |
| `UI/Options.lua` | Panel de opciones |
| `UI/Splash.lua` | Pantalla de bienvenida |
| `Core/EditorModel.lua` | Lógica del editor (agregar, quitar, reordenar, deshacer) |
| `UI/Editor.lua` | Ventana del editor para mando |
| `Bindings.xml` | Atajos asignables (grabar, deshacer) |
| `Core/Config.lua` | Rotaciones guardadas por clase y perfil |
| `UI/Bar.lua` | Barra movible con los próximos iconos |
| `UI/Highlight.lua` | Borde propio encima de los botones del siguiente hechizo |
| `Init.lua` | Eventos y comando `/prh` |
| `tests/` | Tests con busted |

## Uso

La forma principal de configurar la rotación es el **editor de rotación** (ver más abajo): eliges las habilidades desde tus barras con la cruceta y A, sin lanzarlas, y guardas con B.

Alternativa: grabar lanzando habilidades con el atajo "Grabar secuencia" o `/prh grabar`, y terminar con el mismo atajo o `/prh fin`. Al terminar se abre el editor para quitar lo que se pulsó por error antes de guardar.

## Manual de uso

Las instrucciones viven en `UI/Manual.lua` y se muestran en dos sitios con el mismo texto: lo esencial en la pantalla de bienvenida y el manual completo en Opciones > AddOns > Pudu's Rotation Helper > Manual de uso.

## Pantalla de bienvenida

Al iniciar sesión con un personaje aparece una pantalla con las instrucciones básicas. Se desactiva con su casilla "Mostrar al iniciar sesión" y se vuelve a abrir con `/prh ayuda` o desde el panel de opciones. La imagen está en `Media/splash.tga` (1024×512).

## Editor de rotación (mando)

Asigna "Abrir / cerrar editor de rotación" a una combinación del mando (por ejemplo LB+RB+Back) o usa `/prh editar`. El editor tiene dos columnas: tu rotación a la izquierda y las habilidades de tus barras a la derecha. Nada se lanza mientras está abierto.

| Botón | Qué hace |
| --- | --- |
| Cruceta arriba/abajo | Elegir (o mover el paso tomado) |
| Cruceta izquierda/derecha | Cambiar de columna |
| A | En Habilidades: agregar después del paso marcado. En Tu rotación: tomar/soltar para reordenar |
| X | Quitar el paso marcado |
| Y | Deshacer |
| B | Guardar y salir |
| Vista | Descartar cambios |
| Menú | Mover la lista con la cruceta y bloquearla |

Con teclado: flechas, Enter, Supr y Retroceso; con ratón, clic en las filas y los botones Guardar y Descartar. La combinación del editor queda reservada para el addon. El editor no se abre en combate y se cierra guardando al entrar en combate. La grabación lanzando habilidades sigue disponible y, al terminar, abre el editor para limpiar lo grabado.

## Panel de opciones

`/prh` o Opciones > AddOns > Pudu's Rotation Helper:

- **Escala de la lista** de 50 % a 200 %.
- **Color del resaltado** de la habilidad en las barras (teclado y mando).
- **Bloquear la posición de la lista.** También con el candado sobre la lista, `/prh bloquear` o el atajo "Bloquear / desbloquear lista". Desbloqueada, se arrastra con el ratón (o el cursor del mando) o con los atajos "Mover lista arriba/abajo/izquierda/derecha", asignables a combinaciones del mando. La posición se guarda.
- **Rotación actual** y botón para abrir el editor.
- **Importar / exportar en markdown.** Los addons no pueden leer archivos, así que el `.md` se prepara fuera del juego y se pega en el cuadro. Formato (ver `ejemplos/plantilla.md`):

```markdown
# Protección básica
clase: Guerrero          (opcional; español o inglés)
modo: secuencia          (opcional: secuencia | prioridad)

1. Embate con escudo (23922)
2. Revancha              (solo nombre: el personaje debe conocer el hechizo)
3. 7386                  (solo ID)
```

## Clases

Funciona con las nueve clases de Forever: los perfiles se guardan por clase, cualquier rango de un hechizo cuenta como el mismo, y el resaltado sigue al botón aunque cambien las barras por postura (guerrero), forma (druida) o sigilo (pícaro). Los hechizos de mascota no se siguen.

La lista se muestra en vertical, con icono y nombre de cada habilidad; la primera fila es la siguiente a usar.

Después, la barra muestra los próximos pasos, el botón del siguiente se resalta y avanza al usar cada habilidad.

Otros comandos:

```
/prh set 23922 6572 7386    -- secuencia fija que se repite
/prh prio 23922 6572 7386   -- lista de prioridades: sugiere la primera habilidad lista
/prh reset
```

## Instalación para pruebas

Copia la carpeta del repositorio como `PudusRotationHelper` dentro de `World of Warcraft\_forever_\Interface\AddOns` (ruta por verificar).

## Tests

```
luacheck .
busted tests/
```
