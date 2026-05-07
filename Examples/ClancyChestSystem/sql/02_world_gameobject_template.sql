-- =============================================================================
-- ClancyChestSystem - GameObjects (world.gameobject_template).
-- =============================================================================
--
-- El sistema usa dos GameObjects:
--
--   910000 -> Cofre configurador GM
--             Solo los GMs (rango >= MIN_GM_RANK en CONFIG) pueden interactuar
--             con él. Al hacer click derecho se abre la ventana de
--             administración del evento.
--
--   910001 -> Cofre activo / del evento
--             Los jugadores interactúan con él durante un evento activo y
--             reciben los premios configurados. Cada GUID puede ser recogido
--             una sola vez por activación.
--
-- Importar en la base de datos `world`:
--
--   mysql -u <usuario> -p world < 02_world_gameobject_template.sql
--
-- type = 3 (CHEST) y displayId = 274 son valores estándar para un cofre
-- mediano de WoW 3.3.5. Puedes cambiar `displayId` por cualquier modelo de
-- cofre del cliente; algunos comunes:
--
--   274  -> Cofre pequeño/mediano de madera
--   1685 -> Cofre dorado decorado
--   5762 -> Cofre rúnico
--
-- IMPORTANTE: el cofre 910000 NO debe ser visible para los jugadores normales.
-- Recomendamos spawnearlo en una zona de GM o teleportar al GM hacia él.
-- =============================================================================


-- Si ya existían entradas con estos IDs, las reemplazamos para que esta
-- migración sea idempotente (puedes correrla varias veces sin problemas).
DELETE FROM `gameobject_template` WHERE `entry` IN (910000, 910001);


-- -----------------------------------------------------------------------------
-- 910000: Cofre configurador GM
-- -----------------------------------------------------------------------------
INSERT INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
     `size`,
     `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`,
     `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`,
     `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
     `Data22`, `Data23`,
     `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
    (910000, 3, 274, 'Clancy Chest Configurator', '', '', '',
     1.0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0,
     0, 0,
     '', '', 12340);


-- -----------------------------------------------------------------------------
-- 910001: Cofre activo / del evento
-- -----------------------------------------------------------------------------
INSERT INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
     `size`,
     `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`,
     `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`,
     `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
     `Data22`, `Data23`,
     `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
    (910001, 3, 274, 'Clancy Chest', '', '', '',
     1.0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0,
     0, 0,
     '', '', 12340);
