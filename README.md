# pudus-rotation-helper
Addon compatible con World of Warcraft: Forever que asiste visualmente con la rotación de habilidades configurada

Ayuda visual para la rotación de habilidades en **World of Warcraft: Forever**: una barra con las próximas habilidades de una rotación que configura el jugador y un resaltado del botón correspondiente, también en la interfaz beta de mando.

El addon solo muestra sugerencias; no lanza habilidades.

## Estructura

| Archivo | Qué hace |
| --- | --- |
| `PudusRotationHelper.toc` | Metadatos y orden de carga (Interface 16001, por verificar en el cliente final) |
| `Core/Rotation.lua` | Motor de rotación en Lua puro, testeable fuera del juego |
| `Core/Config.lua` | Rotaciones guardadas por clase y perfil |
| `UI/Bar.lua` | Barra movible con los próximos iconos |
| `UI/Highlight.lua` | Borde propio encima de los botones del siguiente hechizo |
| `Init.lua` | Eventos y comando `/prh` |
| `tests/` | Tests con busted |

## Uso

```
/prh set 23922 6572 7386   -- IDs de hechizo en orden
/prh reset
```

## Instalación para pruebas

Copia la carpeta del repositorio como `PudusRotationHelper` dentro de `World of Warcraft\_forever_\Interface\AddOns` (ruta por verificar).

## Tests

```
luacheck .
busted tests/
```
