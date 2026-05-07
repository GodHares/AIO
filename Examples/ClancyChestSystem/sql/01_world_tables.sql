-- =============================================================================
-- ClancyChestSystem - Tablas de la base de datos `world`.
-- =============================================================================
--
-- Estas tablas almacenan el estado del evento, el stock de premios, los cofres
-- recogidos y el log de auditoría.
--
-- Importar en la base de datos `world` ANTES de cargar el script Lua del
-- servidor:
--
--   mysql -u <usuario> -p world < 01_world_tables.sql
--
-- Todas las tablas usan el prefijo `custom_clancy_chest_` para no chocar con
-- las tablas estándar de AzerothCore / TrinityCore.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Estado del evento.
--
-- Una fila por `event_key`. Guarda si el evento está activo, el id de
-- activación actual y el timestamp Unix en que termina.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_state` (
    `event_key`     VARCHAR(64)  NOT NULL DEFAULT 'default',
    `active`        TINYINT(1)   UNSIGNED NOT NULL DEFAULT 0,
    `activation_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `ends_at`       INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`event_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- -----------------------------------------------------------------------------
-- Stock de premios configurados para el cofre.
--
-- Una fila por (event_key, item_entry). Para premios que no son items reales
-- se usa un id "mágico" reservado fuera del rango de items de WoW 3.3.5:
--   honor -> 4000000001
--   arena -> 4000000002
--   gold  -> 4000000003
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_stock` (
    `event_key`  VARCHAR(64)  NOT NULL DEFAULT 'default',
    `item_entry` INT UNSIGNED NOT NULL,
    `amount`     INT UNSIGNED NOT NULL DEFAULT 0,
    `chance_pct` INT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (`event_key`, `item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- -----------------------------------------------------------------------------
-- Registro de cofres recogidos.
--
-- Una fila por cada GameObject saqueado durante una activación concreta. Sirve
-- para impedir que el mismo cofre se recoja dos veces en la misma activación.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `custom_clancy_chest_loot` (
    `event_key`       VARCHAR(64)  NOT NULL DEFAULT 'default',
    `activation_id`   INT UNSIGNED NOT NULL,
    `gameobject_guid` INT UNSIGNED NOT NULL,
    `player_guid`     INT UNSIGNED NOT NULL DEFAULT 0,
    `looted_at`       INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`event_key`, `activation_id`, `gameobject_guid`),
    KEY `idx_player` (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- -----------------------------------------------------------------------------
-- Auditoría: activaciones del evento.
--
-- Quién activó/cerró el evento, cuándo, duración programada, total de cofres
-- y motivo de cierre (manual / expired / all_chests_looted / expired_on_click).
-- -----------------------------------------------------------------------------
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
    KEY `idx_event_activation` (`event_key`, `activation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- -----------------------------------------------------------------------------
-- Auditoría: cambios de stock por GMs.
--
-- Cada add / remove / delete / clear hecho por un GM al stock del evento.
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Auditoría: premios entregados.
--
-- Cada premio entregado a un jugador (item / honor / arena / gold), con el
-- activation_id y el guid del cofre que lo entregó.
-- -----------------------------------------------------------------------------
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
