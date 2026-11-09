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
| `Bindings.xml` | Atajos asignables (grabar, deshacer) |
| `Core/Config.lua` | Rotaciones guardadas por clase y perfil |
| `UI/Bar.lua` | Barra movible con los próximos iconos |
| `UI/Highlight.lua` | Borde propio encima de los botones del siguiente hechizo |
| `Init.lua` | Eventos y comando `/prh` |
| `tests/` | Tests con busted |

## Uso

La forma principal de configurar la rotación es grabarla en el juego:

1. Asigna el atajo "Grabar / guardar secuencia" en Opciones > Atajos de teclado > AddOns (sirve un botón del mando) o escribe `/prh grabar`.
2. Pulsa tus habilidades en el orden de la rotación. Cada pulsación cuenta aunque falle por falta de objetivo o recurso; mejor hacerlo contra un muñeco de entrenamiento.
3. Pulsa de nuevo el atajo (o `/prh fin`) para guardar. `/prh deshacer` quita el último paso y `/prh cancelar` descarta la grabación.

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
