-- ============================================================
-- ClancyChestSystem — Esquema completo de tablas (world DB)
--
-- Este archivo se ejecuta UNA SOLA VEZ contra tu base de datos
-- de mundo (la misma que usa worldserver, a la que apunta
-- WorldDatabaseInfo en worldserver.conf — típicamente:
--    AzerothCore  -> acore_world
--    TrinityCore  -> world / world_335 / trinity_world
--    Otros forks  -> el nombre que tengas configurado).
--
-- Todas las sentencias usan CREATE TABLE IF NOT EXISTS, así que
-- es seguro re-ejecutar el archivo (no toca tablas existentes).
-- ============================================================


-- ============================================================
-- 1) Estado del evento (singleton por event_key).
--    Guarda si el evento está activo, su id de activación
--    incremental y cuándo expira.
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_state` (
    `event_key`     VARCHAR(64)  NOT NULL DEFAULT 'default',
    `active`        TINYINT(1)   UNSIGNED NOT NULL DEFAULT 0,
    `activation_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `ends_at`       INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`event_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- 2) Stock configurado del cofre (uno o más premios).
--
--    NOTA: para no requerir migración de schema, los premios que
--    no son items (honor / arena / oro) se guardan en este mismo
--    item_entry usando ids "mágicos" reservados:
--        4000000001 = honor
--        4000000002 = arena
--        4000000003 = oro
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_stock` (
    `event_key`  VARCHAR(64)  NOT NULL DEFAULT 'default',
    `item_entry` INT UNSIGNED NOT NULL,
    `amount`     INT UNSIGNED NOT NULL DEFAULT 0,
    `chance_pct` INT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (`event_key`, `item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- 3) Cofres ya saqueados en cada activación.
--    Sirve para que un cofre sólo se pueda abrir una vez por
--    activación y para llevar el contador "x / y" en el cliente.
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_loot` (
    `event_key`        VARCHAR(64)  NOT NULL DEFAULT 'default',
    `activation_id`    INT UNSIGNED NOT NULL,
    `gameobject_guid`  INT UNSIGNED NOT NULL,
    `player_guid`      INT UNSIGNED NOT NULL DEFAULT 0,
    `looted_at`        INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`event_key`, `activation_id`, `gameobject_guid`),
    KEY `idx_player` (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- 4) AUDITORÍA — Activaciones del evento por GM.
--    Una fila por cada activación: quién la activó, cuándo, con
--    cuántos cofres, cuándo cerró y por qué motivo
--    (manual / expired / all_chests_looted / expired_on_click).
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_audit_activations` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_key`        VARCHAR(64)  NOT NULL DEFAULT 'default',
    `activation_id`    INT UNSIGNED NOT NULL,
    `gm_guid`          INT UNSIGNED NOT NULL DEFAULT 0,
    `gm_account`       INT UNSIGNED NOT NULL DEFAULT 0,
    `gm_name`          VARCHAR(64)  NOT NULL DEFAULT '',
    `started_at`       INT UNSIGNED NOT NULL DEFAULT 0,
    `duration_minutes` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_chests`     INT UNSIGNED NOT NULL DEFAULT 0,
    `ended_at`         INT UNSIGNED NOT NULL DEFAULT 0,
    `end_reason`       VARCHAR(32)  NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `idx_event_activation` (`event_key`, `activation_id`),
    KEY `idx_gm` (`gm_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- 5) AUDITORÍA — Cambios de stock por GM.
--    Cada add / remove / delete / clear que un GM hace al stock.
--    Para `clear`, kind = 'all' y item_entry = 0.
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_audit_stock_changes` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_key`     VARCHAR(64)  NOT NULL DEFAULT 'default',
    `activation_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `at_time`       INT UNSIGNED NOT NULL DEFAULT 0,
    `gm_guid`       INT UNSIGNED NOT NULL DEFAULT 0,
    `gm_account`    INT UNSIGNED NOT NULL DEFAULT 0,
    `gm_name`       VARCHAR(64)  NOT NULL DEFAULT '',
    `action`        VARCHAR(16)  NOT NULL DEFAULT '',
    `kind`          VARCHAR(16)  NOT NULL DEFAULT 'item',
    `item_entry`    INT UNSIGNED NOT NULL DEFAULT 0,
    `amount`        INT UNSIGNED NOT NULL DEFAULT 0,
    `chance_pct`    INT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (`id`),
    KEY `idx_event_time` (`event_key`, `at_time`),
    KEY `idx_gm` (`gm_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- 6) AUDITORÍA — Premios entregados a jugadores.
--    Una fila por cada premio entregado (incluye honor, arena y
--    oro). amount es la cantidad realmente entregada (después
--    de rollback si lo hubo). chest_guid permite cruzar con
--    custom_clancy_chest_loot para saber qué cofre lo dio.
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_audit_rewards` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_key`      VARCHAR(64)  NOT NULL DEFAULT 'default',
    `activation_id`  INT UNSIGNED NOT NULL DEFAULT 0,
    `at_time`        INT UNSIGNED NOT NULL DEFAULT 0,
    `player_guid`    INT UNSIGNED NOT NULL DEFAULT 0,
    `player_account` INT UNSIGNED NOT NULL DEFAULT 0,
    `player_name`    VARCHAR(64)  NOT NULL DEFAULT '',
    `chest_guid`     INT UNSIGNED NOT NULL DEFAULT 0,
    `kind`           VARCHAR(16)  NOT NULL DEFAULT 'item',
    `item_entry`     INT UNSIGNED NOT NULL DEFAULT 0,
    `amount`         INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_event_activation` (`event_key`, `activation_id`),
    KEY `idx_player` (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ============================================================
-- Consultas útiles de auditoría (NO se ejecutan, son sólo
-- ejemplos de copy/paste para tu cliente SQL).
-- ============================================================

-- Activaciones por GM en los últimos 7 días:
--
--   SELECT gm_name, COUNT(*) AS activaciones,
--          SUM(duration_minutes) AS minutos_totales
--   FROM custom_clancy_chest_audit_activations
--   WHERE started_at >= UNIX_TIMESTAMP() - 7*86400
--   GROUP BY gm_name
--   ORDER BY activaciones DESC;
--
-- Items que un GM puso en el stock (auditoría de cambios):
--
--   SELECT FROM_UNIXTIME(at_time) AS cuando, action, kind,
--          item_entry, amount, chance_pct
--   FROM custom_clancy_chest_audit_stock_changes
--   WHERE gm_name = 'NombreDelGM'
--   ORDER BY at_time DESC;
--
-- Top ganadores de un evento concreto:
--
--   SELECT player_name, kind, SUM(amount) AS total
--   FROM custom_clancy_chest_audit_rewards
--   WHERE activation_id = 12
--   GROUP BY player_name, kind
--   ORDER BY total DESC;
--
-- ¿Algún GM se está auto-premiando? (el GM activador y el
--  ganador de premios coinciden en la misma activación):
--
--   SELECT a.gm_name      AS gm,
--          r.player_name  AS ganador,
--          r.kind, r.amount,
--          FROM_UNIXTIME(r.at_time) AS cuando
--   FROM custom_clancy_chest_audit_activations a
--   JOIN custom_clancy_chest_audit_rewards r
--     ON r.event_key     = a.event_key
--    AND r.activation_id = a.activation_id
--    AND r.player_name   = a.gm_name;
