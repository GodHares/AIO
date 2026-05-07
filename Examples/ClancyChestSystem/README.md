# Clancy Chest System

Sistema de cofres temporales tipo "evento mundial" para **AzerothCore WotLK
3.3.5a + Eluna + AIO (Rochet2)**.

Los GMs spawnean cofres en el mundo, configuran qué premios pueden contener
(items, oro, puntos de honor o de arena, con probabilidad por premio), y
activan un evento por tiempo. Los jugadores corren por el mundo a buscarlos,
cada cofre puede recogerse una sola vez por activación, y el evento termina
automáticamente cuando se vacían todos los cofres o cuando expira el tiempo.

No usa `game_event` ni `gameobject_loot_template`: todo el estado vive en
tablas propias del módulo y la entrega de premios se decide en runtime con
los handlers del servidor.

---

## Contenido

```
Examples/ClancyChestSystem/
├── ClancyChestSystem_Server.lua    # Lógica del servidor + handlers AIO.
├── ClancyChestSystem_Client.lua    # UI del cliente (single-frame, dorada).
├── README.md                       # Este archivo.
└── sql/
    ├── 01_world_tables.sql         # CREATE TABLEs (estado, stock, loot, audit).
    └── 02_world_gameobject_template.sql  # INSERT de los GameObjects 910000 y 910001.
```

---

## Requisitos

- **AzerothCore** (rama 3.3.5a) o **TrinityCore** equivalente.
- **Eluna Lua Engine** instalado y funcionando en tu core.
- **AIO** de Rochet2 instalado en cliente y servidor (este repo).
- Acceso a la base de datos `world` para importar los SQL.

---

## Instalación

### 1. Importar los SQL en la base de datos `world`

Importa los dos archivos en este orden:

```bash
mysql -u <usuario> -p world < Examples/ClancyChestSystem/sql/01_world_tables.sql
mysql -u <usuario> -p world < Examples/ClancyChestSystem/sql/02_world_gameobject_template.sql
```

`01_world_tables.sql` crea las tablas operacionales y de auditoría
(`custom_clancy_chest_*`). `02_world_gameobject_template.sql` da de alta los
dos GameObjects (910000 = configurador GM, 910001 = cofre del evento).

Ambos archivos son **idempotentes**: usan `CREATE TABLE IF NOT EXISTS` y
borran/reinsertan los `gameobject_template` antes de añadirlos, así que
puedes correrlos varias veces sin problemas.

### 2. Copiar el script Lua al servidor

```bash
cp Examples/ClancyChestSystem/ClancyChestSystem_Server.lua \
   <ruta_servidor>/lua_scripts/
cp Examples/ClancyChestSystem/ClancyChestSystem_Client.lua \
   <ruta_servidor>/lua_scripts/
```

> El archivo `ClancyChestSystem_Client.lua` se coloca también en
> `lua_scripts/`. AIO lo detecta como addon de cliente y lo envía al
> jugador la primera vez que conecta (o cuando cambia y se invalida la
> caché). **No** hace falta copiarlo manualmente al cliente WoW.

### 3. Reiniciar el worldserver (o `reload eluna`)

```
.reload eluna
```

Si todo cargó correctamente verás los GameObjects 910000 y 910001
disponibles para spawn.

---

## Spawn de los cofres

### Cofre configurador GM (910000)

Es el cofre que solo los GMs deberían tocar. Spawnealo en una zona privada
de GMs (por ejemplo, en una sala de admin) o tenlo siempre cerca del lugar
donde administras eventos:

```
.gobject add 910000
```

Para borrarlo:

```
.gobject delete <guid>
```

### Cofres del evento (910001)

Spawnea tantos como quieras repartidos por el mundo. Cada cofre con id
910001 contará como un cofre del evento. Cuantos más cofres haya
spawneados, más cofres podrán recoger los jugadores en cada activación.

```
.gobject add 910001
```

Buena práctica: spawnea los cofres una sola vez con `.gobject add saved`
para que se persistan entre reinicios:

```
.gobject add 910001
.gobject saveall
```

Para borrar uno (apuntando al cofre):

```
.gobject delete <guid>
```

---

## Uso como GM

1. Ve hasta el cofre configurador (910000) y haz click derecho.
2. Se abrirá la ventana **Clancy Chest System** con cuatro paneles:
   - **Status bar** (arriba): estado del evento (ACTIVO / INACTIVO),
     cofres recogidos / totales, tiempo restante, número de activación.
   - **Configuración**: selector de tipo de premio (Item / Honor / Arena /
     Oro), inputs (Item ID, cantidad, chance %, duración del evento) y
     los botones **Añadir / Quitar / Eliminar / Limpiar / Activar / Parar
     / Refrescar**.
   - **Item seleccionado**: detalle del item resaltado en la lista.
   - **Items configurados**: lista con scroll de todos los premios del
     stock actual (con icono, id, nombre, cantidad, chance y duración).
3. **Para añadir un premio**: elige el tipo (Item / Honor / Arena / Oro),
   escribe la cantidad y el chance %, y pulsa **Añadir**. Para items reales
   también hay que indicar el Item ID.
4. **Para activar el evento**: ajusta la **Duración** en minutos y pulsa
   **Activar**. El evento empieza, se anuncia al mundo (con banner tipo
   *raid warning*) y los cofres 910001 quedan listos para ser recogidos.
5. **Para parar el evento manualmente**: pulsa **Parar**.

> Si prefieres no caminar hasta el cofre, también puedes abrir la ventana
> con los slash commands del cliente:
>
> ```
> /clancychest
> /cofreclancy
> ```
>
> Solo funcionan si tu personaje tiene rango de GM suficiente (ver
> `MIN_GM_RANK` más abajo).

### Tipos de premio

| Tipo  | Significado de `amount`             | Notas                                                                 |
| ----- | ----------------------------------- | --------------------------------------------------------------------- |
| item  | Stack del item                      | Necesita un Item ID válido en `item_template`.                        |
| honor | Puntos de honor a entregar          | Se entrega con `Player:ModifyHonorPoints`.                            |
| arena | Puntos de arena a entregar          | Se entrega con `Player:ModifyArenaPoints`.                            |
| gold  | Oro entero (5 = 5g)                 | Internamente se multiplica por 10000 para pasarlo a cobre con `ModifyMoney`. |

Honor / arena / gold se guardan en la tabla con un id "mágico" reservado
fuera del rango de items reales:

```
honor -> 4000000001
arena -> 4000000002
gold  -> 4000000003
```

Esto evita tener que migrar el schema de la tabla de stock para soportar
recompensas que no son items.

---

## Uso como jugador

1. Cuando un GM activa el evento, todos los jugadores conectados ven un
   banner amarillo central:
   *"¡Han aparecido cofres misteriosos!"*
2. Salen a buscar los cofres 910001 spawneados por el mundo.
3. Cada cofre puede ser recogido por **un solo jugador por activación**.
   El primero que llegue gana.
4. Al hacer click derecho sobre un cofre del evento, el sistema tira los
   chances de cada premio configurado y entrega los que ganen. Si el
   inventario del jugador está lleno y no caben todos los items, se hace
   *rollback* y el cofre queda disponible para reintentarlo.
5. El evento termina cuando se recogen todos los cofres o cuando expira el
   tiempo.

---

## Configuración

Las opciones principales viven en la tabla `CONFIG` al inicio de
`ClancyChestSystem_Server.lua`:

```lua
local CONFIG = {
    EVENT_KEY = "main_clancy_chest_event",

    PREP_GO_ENTRY = 910000,
    ACTIVE_GO_ENTRY = 910001,

    MIN_GM_RANK = 3,

    DEFAULT_DURATION_MINUTES = 10,
    MIN_DURATION_SECONDS = 30,
    MAX_DURATION_SECONDS = 24 * 60 * 60,

    CLEAR_STOCK_ON_DEACTIVATE = false,
    ALLOW_EDIT_WHILE_ACTIVE = false,

    ANNOUNCE_TO_WORLD = true,
    ANNOUNCE_FOUND_CHESTS = true,

    DESPAWN_CHEST_ON_LOOT = false,
}
```

| Opción                       | Default | Descripción                                                                                              |
| ---------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| `EVENT_KEY`                  | `main_clancy_chest_event` | Clave que identifica este evento. Permite tener varios eventos independientes en la misma DB.            |
| `PREP_GO_ENTRY`              | `910000`| Entry del GameObject configurador GM.                                                                    |
| `ACTIVE_GO_ENTRY`            | `910001`| Entry del GameObject del cofre del evento.                                                               |
| `MIN_GM_RANK`                | `3`     | Rango GM mínimo necesario para administrar el sistema (si `Player:IsGM()` no devuelve true).             |
| `DEFAULT_DURATION_MINUTES`   | `10`    | Duración por defecto cuando se activa sin pasar minutos.                                                 |
| `MIN_DURATION_SECONDS`       | `30`    | Duración mínima permitida del evento.                                                                    |
| `MAX_DURATION_SECONDS`       | `86400` | Duración máxima permitida (24 h).                                                                        |
| `CLEAR_STOCK_ON_DEACTIVATE`  | `false` | Si es `true`, al parar el evento se borra todo el stock configurado.                                     |
| `ALLOW_EDIT_WHILE_ACTIVE`    | `false` | Si es `true`, los GMs pueden editar el stock mientras el evento está corriendo.                          |
| `ANNOUNCE_TO_WORLD`          | `true`  | Envía mensajes al chat global cuando empieza/termina el evento o se encuentra un cofre.                  |
| `ANNOUNCE_FOUND_CHESTS`      | `true`  | Anuncia cada cofre encontrado al mundo (banner + chat).                                                  |
| `DESPAWN_CHEST_ON_LOOT`      | `false` | Si es `true`, el cofre desaparece visualmente al ser recogido. Déjalo en `false` si tu core falla con `Despawn`. |

---

## Tablas creadas

| Tabla                                       | Propósito                                                              |
| ------------------------------------------- | ---------------------------------------------------------------------- |
| `custom_clancy_chest_state`                 | Estado actual del evento (activo, activation_id, ends_at).             |
| `custom_clancy_chest_stock`                 | Stock de premios configurados (entry, amount, chance_pct).             |
| `custom_clancy_chest_loot`                  | Registro de cofres recogidos (impide doble loot por activación).       |
| `custom_clancy_chest_audit_activations`     | Auditoría: quién activó/cerró cada evento, cuándo y por qué.           |
| `custom_clancy_chest_audit_stock_changes`   | Auditoría: cambios de stock hechos por GMs (add / remove / clear).     |
| `custom_clancy_chest_audit_rewards`         | Auditoría: premios entregados a jugadores, con activation_id y chest.  |

---

## Troubleshooting

**No me abre la ventana al hacer click en el cofre 910000**
- Verifica que tienes rango de GM suficiente (`.account set gmlevel <n>` o
  `Player:IsGM()` debe devolver true). El default exige rango ≥ 3.
- Comprueba que el script Lua se cargó (`.reload eluna` y revisa el log
  del worldserver).
- Asegúrate de que el GameObject existe: `SELECT * FROM gameobject_template
  WHERE entry = 910000;` debe devolver una fila.

**"No hay cofres 910001 spawneados en el mundo"**
- Asegúrate de haber spawneado al menos un cofre 910001 con `.gobject
  add 910001` y persistido con `.gobject saveall`.
- Verifica con `SELECT COUNT(*) FROM gameobject WHERE id = 910001;`.

**Los premios no se entregan**
- Si es un item, comprueba que el Item ID exista en `item_template`.
- Si es honor / arena, verifica que tu core soporte
  `Player:ModifyHonorPoints` / `Player:ModifyArenaPoints`.

**Quiero limpiar el histórico de loot**
```sql
TRUNCATE TABLE custom_clancy_chest_loot;
```

**Quiero borrar los logs de auditoría**
```sql
TRUNCATE TABLE custom_clancy_chest_audit_activations;
TRUNCATE TABLE custom_clancy_chest_audit_stock_changes;
TRUNCATE TABLE custom_clancy_chest_audit_rewards;
```

**Quiero resetear el evento por completo**
```sql
DELETE FROM custom_clancy_chest_state WHERE event_key = 'main_clancy_chest_event';
DELETE FROM custom_clancy_chest_stock WHERE event_key = 'main_clancy_chest_event';
DELETE FROM custom_clancy_chest_loot  WHERE event_key = 'main_clancy_chest_event';
```

Después haz `.reload eluna` para forzar la recarga del estado.
