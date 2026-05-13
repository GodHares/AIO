local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

local QuestCreator = AIO.AddHandlers("QuestCreator", {})

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00QuestCreator CLIENT VERSION: QUESTCREATOR-V11-ITEM-TOOLTIP-PREVIEW-2026-05-08|r")

-- =========================================================
-- Localization (i18n)
-- Supported: en, es, ptBR, ru, fr. Fallback: en.
-- =========================================================

QuestCreator_Settings = QuestCreator_Settings or {}
if AIO and AIO.AddSavedVar then
    AIO.AddSavedVar("QuestCreator_Settings")
end

local LOCALE_DISPLAY = {
    en   = "English",
    es   = "Español",
    ptBR = "Português (BR)",
    fr   = "Français",
}
local LOCALE_ORDER = { "en", "es", "ptBR", "fr" }

local LOCALES = {
    en = {
        APP_TITLE             = "AzerothCore Quest Builder Visual",
        BTN_VALIDATE          = "Validate",
        BTN_SAVE              = "Save",
        BTN_CLEAR             = "Clear",
        LBL_LANGUAGE          = "Language",
        TAB_BASIC             = "Basic",
        TAB_TEXTS             = "Texts",
        TAB_OBJECTIVES        = "Objectives",
        TAB_REWARDS           = "Rewards",
        TAB_REPUTATION        = "Reputation",
        TAB_CHAIN             = "Chain",
        TAB_STARTER           = "Starter",
        TAB_ADVANCED          = "Advanced",
        TAB_QUEST_LIST        = "Quest List",
        TAB_PREVIEW           = "Preview",
        QUEST_LIST_TITLE      = "QUEST LIST",
        BTN_BACK              = "<< Back",
        BTN_FORWARD           = "Forward >>",
        BTN_SEARCH            = "Search",
        BTN_RELOAD_LIST       = "Reload List",
        LBL_START_ID          = "Start ID",
        LBL_NEW_COPY_ID       = "New Copy ID",
        COL_ID                = "ID",
        COL_QUEST_TITLE       = "QUEST TITLE",
        COL_LVL               = "LVL",
        COL_MIN               = "MIN",
        COL_MAX               = "MAX",
        COL_NEXT_QUEST        = "NEXT QUEST",
        ROW_LVL_PREFIX        = "Lvl",
        ROW_MIN_PREFIX        = "Min",
        ROW_NEXT_PREFIX       = "Next",
        BTN_LOAD              = "Load",
        BTN_COPY              = "Copy",
        BTN_DELETE            = "Delete",
        BTN_DEL_CHAIN         = "Del Chain",
        PAGER_NO_DATA         = "No data",
        PAGER_IDS_RANGE       = "IDs %s – %s",
        STATUS_REQ_FIRST      = "Requesting first page from ID 1...",
        STATUS_REQ_PREV       = "Requesting previous page up to ID %s...",
        STATUS_REQ_NEXT       = "Requesting next page from ID %s...",
        STATUS_REQ_LAST       = "Requesting last page (backward from ID 999999)...",
        STATUS_RECEIVING      = "Receiving quest stream... expected: %s",
        STATUS_STREAM_DONE    = "Stream received: %s quests.",
        STATUS_NO_QUESTS      = "No quests received.",
        STATUS_SHOWING        = "Showing %s of %s quests. Direction: %s",
        CARD_QUEST_SUMMARY    = "Quest Summary",
        CARD_PREVIEW_CONTROLS = "Preview Controls",
        TITLE_STARTER_ENDER   = "Starter / Ender",
        TITLE_QUICK_REWARD    = "Quick Reward Summary",
        LBL_QUEST_ID          = "Quest ID",
        LBL_TITLE             = "Title",
        LBL_QUEST_TYPE        = "QuestType",
        LBL_QUEST_LEVEL       = "QuestLevel",
        LBL_MIN_LEVEL         = "MinLevel",
        LBL_QUEST_INFO        = "QuestInfo",
        LBL_FLAGS             = "Flags",
        LBL_SPECIAL_FLAGS     = "SpecialFlags",
        LBL_START_NPC         = "Start NPC",
        LBL_END_NPC           = "End NPC",
        BTN_OFFER             = "Offer",
        BTN_IN_PROGRESS       = "In Progress",
        BTN_READY             = "Ready",
        BTN_REWARD_PREVIEW    = "Reward Preview",
        CHK_SHOW_OBJECTIVES   = "Show Objectives",
        CHK_SHOW_REWARDS      = "Show Rewards",
        CHK_SHOW_PORTRAIT     = "Show Portrait",
        CHK_USE_PLAYER_TOKENS = "Use Player Tokens ($N, $C)",
        BTN_ACCEPT            = "Accept",
        BTN_REJECT            = "Reject",
        BTN_CONTINUE          = "Continue",
        BTN_CLOSE             = "Close",
        BTN_COMPLETE          = "Complete",
        BTN_CANCEL            = "Cancel",
        LBL_REWARDS_HINT_1    = "Full rewards are displayed",
        LBL_REWARDS_HINT_2    = "inside the central scrollable parchment.",
        LBL_REPUTATION        = "Reputation",
        LBL_HONOR             = "Honor",
        LBL_XP                = "XP",
        LBL_MONEY             = "Money",
        MSG_DELETE_CHAIN_TITLE = "Delete Chain",
        MSG_DELETE_CHAIN_BODY  = "You are about to delete a chain starting at quest %s\n\nRewardNextQuest will be followed forward." ..
                                 "\n\nTo confirm type:\nDELETE CHAIN %s",
        HELP_TITLE             = "AzerothCore Quest Builder — Help",
        HELP_BODY              =
"This addon is a full quest editor for AzerothCore custom quests, built on top of AIO.\n\n" ..
"|cffffd87aHeader buttons|r\n" ..
"  ?     Open this help.\n" ..
"  Validate  Ask the server to validate the form without saving.\n" ..
"  Save     Persist the quest to the database.\n" ..
"  Clear    Reset every field of the editor.\n\n" ..
"|cffffd87aLanguage|r\n" ..
"  Dropdown in the top-left. Supported: English, Español, Português (BR), Français. Choice is persisted between sessions; other clients fall back to English.\n\n" ..
"|cffffd87aTabs|r\n" ..
"  Basic       ID, title, type, level, min level, flags and special flags.\n" ..
"  Texts       Log description, quest description, area description and completion log.\n" ..
"  Objectives  Up to 4 objectives (creature/object/item/spell/area) and emote IDs.\n" ..
"  Rewards     Items, choice items, money, XP difficulty, honor, kill honor, title, talent and arena points.\n" ..
"  Reputation  Two faction rewards (faction id + value, both raw and override fields).\n" ..
"  Chain       Previous quest, next quest, exclusive group and breadcrumb.\n" ..
"  Starter     Start and end NPCs / GameObjects, source item.\n" ..
"  Advanced    Required races / classes, suggested players, time limit, area, point of interest.\n" ..
"  Quest List  Paginated browser over your custom quest range: search by text, jump by ID, Load, Copy, Delete and Delete Chain.\n" ..
"  Preview     Live preview of the quest in the WoW style with Offer / In Progress / Ready / Reward Preview states, toggles for objectives, rewards, portrait and player tokens, and a quick reward summary.\n\n" ..
"|cffffd87aSafety|r\n" ..
"  Deletes are restricted to the custom quest range (CustomQuestMinId..CustomQuestMaxId). Delete Chain also refuses if the chain crosses into the official quest range, unless AllowDeleteOutsideCustomRange is enabled on the server.\n\n" ..
"All actions go through the AIO RPC layer: client never writes to the database directly.",
    },
    es = {
        APP_TITLE             = "AzerothCore Quest Builder Visual",
        BTN_VALIDATE          = "Validar",
        BTN_SAVE              = "Guardar",
        BTN_CLEAR             = "Limpiar",
        LBL_LANGUAGE          = "Idioma: ",
        TAB_BASIC             = "Básico",
        TAB_TEXTS             = "Textos",
        TAB_OBJECTIVES        = "Objetivos",
        TAB_REWARDS           = "Recompensas",
        TAB_REPUTATION        = "Reputación",
        TAB_CHAIN             = "Cadena",
        TAB_STARTER           = "Inicio",
        TAB_ADVANCED          = "Avanzado",
        TAB_QUEST_LIST        = "Lista de quests",
        TAB_PREVIEW           = "Vista previa",
        QUEST_LIST_TITLE      = "LISTA DE QUESTS",
        BTN_BACK              = "<< Atrás",
        BTN_FORWARD           = "Adelante >>",
        BTN_SEARCH            = "Buscar",
        BTN_RELOAD_LIST       = "Recargar lista",
        LBL_START_ID          = "ID inicial",
        LBL_NEW_COPY_ID       = "ID de la copia",
        COL_ID                = "ID",
        COL_QUEST_TITLE       = "TÍTULO",
        COL_LVL               = "LVL",
        COL_MIN               = "MIN",
        COL_MAX               = "MAX",
        COL_NEXT_QUEST        = "SIGUIENTE",
        ROW_LVL_PREFIX        = "Lvl",
        ROW_MIN_PREFIX        = "Min",
        ROW_NEXT_PREFIX       = "Sig.",
        BTN_LOAD              = "Cargar",
        BTN_COPY              = "Copiar",
        BTN_DELETE            = "Borrar",
        BTN_DEL_CHAIN         = "Borrar cadena",
        PAGER_NO_DATA         = "Sin datos",
        PAGER_IDS_RANGE       = "IDs %s – %s",
        STATUS_REQ_FIRST      = "Solicitando primera página desde ID 1...",
        STATUS_REQ_PREV       = "Solicitando página anterior hasta ID %s...",
        STATUS_REQ_NEXT       = "Solicitando página siguiente desde ID %s...",
        STATUS_REQ_LAST       = "Solicitando última página (backward desde ID 999999)...",
        STATUS_RECEIVING      = "Recibiendo stream de quests... esperado: %s",
        STATUS_STREAM_DONE    = "Stream recibido: %s quests.",
        STATUS_NO_QUESTS      = "No se recibieron quests.",
        STATUS_SHOWING        = "Mostrando %s de %s quests. Dirección: %s",
        CARD_QUEST_SUMMARY    = "Resumen de quest",
        CARD_PREVIEW_CONTROLS = "Controles de vista previa",
        TITLE_STARTER_ENDER   = "Inicio / Fin",
        TITLE_QUICK_REWARD    = "Resumen de recompensas",
        LBL_QUEST_ID          = "ID de quest",
        LBL_TITLE             = "Título",
        LBL_QUEST_TYPE        = "Tipo",
        LBL_QUEST_LEVEL       = "Nivel",
        LBL_MIN_LEVEL         = "Nivel mínimo",
        LBL_QUEST_INFO        = "Info",
        LBL_FLAGS             = "Flags",
        LBL_SPECIAL_FLAGS     = "Flags especiales",
        LBL_START_NPC         = "NPC inicial",
        LBL_END_NPC           = "NPC final",
        BTN_OFFER             = "Ofrecer",
        BTN_IN_PROGRESS       = "En curso",
        BTN_READY             = "Lista",
        BTN_REWARD_PREVIEW    = "Vista de recompensa",
        CHK_SHOW_OBJECTIVES   = "Mostrar objetivos",
        CHK_SHOW_REWARDS      = "Mostrar recompensas",
        CHK_SHOW_PORTRAIT     = "Mostrar retrato",
        CHK_USE_PLAYER_TOKENS = "Usar tokens del jugador ($N, $C)",
        BTN_ACCEPT            = "Aceptar",
        BTN_REJECT            = "Rechazar",
        BTN_CONTINUE          = "Continuar",
        BTN_CLOSE             = "Cerrar",
        BTN_COMPLETE          = "Completar",
        BTN_CANCEL            = "Cancelar",
        LBL_REWARDS_HINT_1    = "Las recompensas completas se muestran",
        LBL_REWARDS_HINT_2    = "dentro del pergamino central con scroll.",
        LBL_REPUTATION        = "Reputación",
        LBL_HONOR             = "Honor",
        LBL_XP                = "XP",
        LBL_MONEY             = "Dinero",
        MSG_DELETE_CHAIN_TITLE = "Borrar cadena",
        MSG_DELETE_CHAIN_BODY  = "Vas a borrar una cadena desde quest %s\n\nSe seguirá RewardNextQuest hacia adelante." ..
                                 "\n\nPara confirmar escribe:\nDELETE CHAIN %s",
        HELP_TITLE             = "AzerothCore Quest Builder — Ayuda",
        HELP_BODY              =
"Este addon es un editor completo de quests custom de AzerothCore, montado sobre AIO.\n\n" ..
"|cffffd87aBotones de cabecera|r\n" ..
"  ?         Abre esta ayuda.\n" ..
"  Validar   Pide al servidor validar el formulario sin guardar.\n" ..
"  Guardar   Persiste la quest en la base de datos.\n" ..
"  Limpiar   Reinicia todos los campos del editor.\n\n" ..
"|cffffd87aIdioma|r\n" ..
"  Dropdown arriba a la izquierda. Idiomas: English, Español, Português (BR), Français. La elección se guarda entre sesiones; otros clientes caen a inglés.\n\n" ..
"|cffffd87aPestañas|r\n" ..
"  Básico         ID, título, tipo, nivel, nivel mínimo, flags y flags especiales.\n" ..
"  Textos         Descripción del log, descripción de la quest, descripción del área y completion log.\n" ..
"  Objetivos      Hasta 4 objetivos (criatura/objeto/item/hechizo/área) e IDs de emote.\n" ..
"  Recompensas    Items, items de elección, dinero, dificultad XP, honor, kill honor, título, puntos de talento y arena.\n" ..
"  Reputación     Dos recompensas de facción (faction id + valor, en versión raw y override).\n" ..
"  Cadena         Quest previa, quest siguiente, exclusive group y breadcrumb.\n" ..
"  Inicio         NPC/GameObject inicial y final, item fuente.\n" ..
"  Avanzado       Razas / clases requeridas, jugadores sugeridos, límite de tiempo, área, punto de interés.\n" ..
"  Lista de quests  Navegador paginado sobre tu rango custom: buscar por texto, saltar por ID, Cargar, Copiar, Borrar y Borrar cadena.\n" ..
"  Vista previa     Preview en vivo al estilo WoW con estados Ofrecer / En curso / Lista / Vista de recompensa, toggles de objetivos/recompensas/retrato/tokens del jugador, y un resumen rápido de recompensas.\n\n" ..
"|cffffd87aSeguridad|r\n" ..
"  Los borrados están restringidos al rango custom (CustomQuestMinId..CustomQuestMaxId). Borrar cadena también rechaza la operación si la cadena entra en el rango oficial, salvo que AllowDeleteOutsideCustomRange esté habilitado en el server.\n\n" ..
"Todas las acciones pasan por la capa RPC de AIO: el cliente nunca escribe en la base de datos directamente.",
    },
    ptBR = {
        APP_TITLE             = "AzerothCore Quest Builder Visual",
        BTN_VALIDATE          = "Validar",
        BTN_SAVE              = "Salvar",
        BTN_CLEAR             = "Limpar",
        LBL_LANGUAGE          = "Idioma: ",
        TAB_BASIC             = "Básico",
        TAB_TEXTS             = "Textos",
        TAB_OBJECTIVES        = "Objetivos",
        TAB_REWARDS           = "Recompensas",
        TAB_REPUTATION        = "Reputação",
        TAB_CHAIN             = "Cadeia",
        TAB_STARTER           = "Início",
        TAB_ADVANCED          = "Avançado",
        TAB_QUEST_LIST        = "Lista de quests",
        TAB_PREVIEW           = "Pré-visualizar",
        QUEST_LIST_TITLE      = "LISTA DE QUESTS",
        BTN_BACK              = "<< Voltar",
        BTN_FORWARD           = "Avançar >>",
        BTN_SEARCH            = "Buscar",
        BTN_RELOAD_LIST       = "Recarregar lista",
        LBL_START_ID          = "ID inicial",
        LBL_NEW_COPY_ID       = "ID da cópia",
        COL_ID                = "ID",
        COL_QUEST_TITLE       = "TÍTULO",
        COL_LVL               = "LVL",
        COL_MIN               = "MIN",
        COL_MAX               = "MAX",
        COL_NEXT_QUEST        = "PRÓXIMA",
        ROW_LVL_PREFIX        = "Lvl",
        ROW_MIN_PREFIX        = "Min",
        ROW_NEXT_PREFIX       = "Próx.",
        BTN_LOAD              = "Carregar",
        BTN_COPY              = "Copiar",
        BTN_DELETE            = "Excluir",
        BTN_DEL_CHAIN         = "Excl. cadeia",
        PAGER_NO_DATA         = "Sem dados",
        PAGER_IDS_RANGE       = "IDs %s – %s",
        STATUS_REQ_FIRST      = "Solicitando primeira página a partir do ID 1...",
        STATUS_REQ_PREV       = "Solicitando página anterior até o ID %s...",
        STATUS_REQ_NEXT       = "Solicitando próxima página a partir do ID %s...",
        STATUS_REQ_LAST       = "Solicitando última página (backward a partir do ID 999999)...",
        STATUS_RECEIVING      = "Recebendo stream de quests... esperado: %s",
        STATUS_STREAM_DONE    = "Stream recebido: %s quests.",
        STATUS_NO_QUESTS      = "Nenhuma quest recebida.",
        STATUS_SHOWING        = "Exibindo %s de %s quests. Direção: %s",
        CARD_QUEST_SUMMARY    = "Resumo da quest",
        CARD_PREVIEW_CONTROLS = "Controles da pré-visualização",
        TITLE_STARTER_ENDER   = "Início / Fim",
        TITLE_QUICK_REWARD    = "Resumo de recompensas",
        LBL_QUEST_ID          = "ID da quest",
        LBL_TITLE             = "Título",
        LBL_QUEST_TYPE        = "Tipo",
        LBL_QUEST_LEVEL       = "Nível",
        LBL_MIN_LEVEL         = "Nível mínimo",
        LBL_QUEST_INFO        = "Info",
        LBL_FLAGS             = "Flags",
        LBL_SPECIAL_FLAGS     = "Flags especiais",
        LBL_START_NPC         = "NPC inicial",
        LBL_END_NPC           = "NPC final",
        BTN_OFFER             = "Oferecer",
        BTN_IN_PROGRESS       = "Em andamento",
        BTN_READY             = "Pronta",
        BTN_REWARD_PREVIEW    = "Prévia recompensas",
        CHK_SHOW_OBJECTIVES   = "Mostrar objetivos",
        CHK_SHOW_REWARDS      = "Mostrar recompensas",
        CHK_SHOW_PORTRAIT     = "Mostrar retrato",
        CHK_USE_PLAYER_TOKENS = "Usar tokens do jogador ($N, $C)",
        BTN_ACCEPT            = "Aceitar",
        BTN_REJECT            = "Recusar",
        BTN_CONTINUE          = "Continuar",
        BTN_CLOSE             = "Fechar",
        BTN_COMPLETE          = "Concluir",
        BTN_CANCEL            = "Cancelar",
        LBL_REWARDS_HINT_1    = "As recompensas completas aparecem",
        LBL_REWARDS_HINT_2    = "no pergaminho central com rolagem.",
        LBL_REPUTATION        = "Reputação",
        LBL_HONOR             = "Honra",
        LBL_XP                = "XP",
        LBL_MONEY             = "Dinheiro",
        MSG_DELETE_CHAIN_TITLE = "Excluir cadeia",
        MSG_DELETE_CHAIN_BODY  = "Você vai excluir uma cadeia a partir da quest %s\n\nRewardNextQuest será seguido adiante." ..
                                 "\n\nPara confirmar digite:\nDELETE CHAIN %s",
        HELP_TITLE             = "AzerothCore Quest Builder — Ajuda",
        HELP_BODY              =
"Este addon é um editor completo de quests customizadas do AzerothCore, em cima do AIO.\n\n" ..
"|cffffd87aBotões do cabeçalho|r\n" ..
"  ?         Abre esta ajuda.\n" ..
"  Validar   Pede ao servidor validar o formulário sem salvar.\n" ..
"  Salvar    Persiste a quest no banco.\n" ..
"  Limpar    Zera todos os campos do editor.\n\n" ..
"|cffffd87aIdioma|r\n" ..
"  Dropdown no canto superior esquerdo. Idiomas: English, Español, Português (BR), Français. A escolha é salva entre sessões; outros clientes caem para inglês.\n\n" ..
"|cffffd87aAbas|r\n" ..
"  Básico         ID, título, tipo, nível, nível mínimo, flags e flags especiais.\n" ..
"  Textos         Descrição do log, descrição da quest, descrição da área e completion log.\n" ..
"  Objetivos      Até 4 objetivos (criatura/objeto/item/feitiço/área) e IDs de emote.\n" ..
"  Recompensas    Itens, itens de escolha, dinheiro, dificuldade de XP, honra, kill honor, título, pontos de talento e arena.\n" ..
"  Reputação      Duas recompensas de facção (faction id + valor, em versão raw e override).\n" ..
"  Cadeia         Quest anterior, próxima, exclusive group e breadcrumb.\n" ..
"  Início         NPC/GameObject inicial e final, item fonte.\n" ..
"  Avançado       Raças / classes exigidas, jogadores sugeridos, limite de tempo, área, ponto de interesse.\n" ..
"  Lista de quests  Navegador paginado sobre seu range custom: busca por texto, salto por ID, Carregar, Copiar, Excluir e Excluir cadeia.\n" ..
"  Pré-visualização   Preview ao vivo no estilo WoW com estados Oferecer / Em andamento / Pronta / Prévia da recompensa, toggles de objetivos/recompensas/retrato/tokens do jogador, e um resumo rápido das recompensas.\n\n" ..
"|cffffd87aSegurança|r\n" ..
"  Exclusões são restritas ao range custom (CustomQuestMinId..CustomQuestMaxId). Excluir cadeia também rejeita se a cadeia entrar no range oficial, a menos que AllowDeleteOutsideCustomRange esteja habilitado no servidor.\n\n" ..
"Todas as ações passam pela camada RPC do AIO: o cliente nunca escreve direto no banco.",
    },
    fr = {
        APP_TITLE             = "AzerothCore Quest Builder Visual",
        BTN_VALIDATE          = "Valider",
        BTN_SAVE              = "Enregistrer",
        BTN_CLEAR             = "Effacer",
        LBL_LANGUAGE          = "Langue",
        TAB_BASIC             = "Basique",
        TAB_TEXTS             = "Textes",
        TAB_OBJECTIVES        = "Objectifs",
        TAB_REWARDS           = "Récompenses",
        TAB_REPUTATION        = "Réputation",
        TAB_CHAIN             = "Chaîne",
        TAB_STARTER           = "Donneur",
        TAB_ADVANCED          = "Avancé",
        TAB_QUEST_LIST        = "Liste des quêtes",
        TAB_PREVIEW           = "Aperçu",
        QUEST_LIST_TITLE      = "LISTE DES QUÊTES",
        BTN_BACK              = "<< Retour",
        BTN_FORWARD           = "Suivant >>",
        BTN_SEARCH            = "Rechercher",
        BTN_RELOAD_LIST       = "Recharger la liste",
        LBL_START_ID          = "ID de départ",
        LBL_NEW_COPY_ID       = "ID de la copie",
        COL_ID                = "ID",
        COL_QUEST_TITLE       = "TITRE",
        COL_LVL               = "NIV",
        COL_MIN               = "MIN",
        COL_MAX               = "MAX",
        COL_NEXT_QUEST        = "QUÊTE SUIV.",
        ROW_LVL_PREFIX        = "Niv.",
        ROW_MIN_PREFIX        = "Min",
        ROW_NEXT_PREFIX       = "Suiv.",
        BTN_LOAD              = "Charger",
        BTN_COPY              = "Copier",
        BTN_DELETE            = "Supprimer",
        BTN_DEL_CHAIN         = "Suppr. chaîne",
        PAGER_NO_DATA         = "Aucune donnée",
        PAGER_IDS_RANGE       = "IDs %s – %s",
        STATUS_REQ_FIRST      = "Demande de la première page depuis l'ID 1...",
        STATUS_REQ_PREV       = "Demande de la page précédente jusqu'à l'ID %s...",
        STATUS_REQ_NEXT       = "Demande de la page suivante depuis l'ID %s...",
        STATUS_REQ_LAST       = "Demande de la dernière page (backward depuis l'ID 999999)...",
        STATUS_RECEIVING      = "Réception du flux de quêtes... attendu : %s",
        STATUS_STREAM_DONE    = "Flux reçu : %s quêtes.",
        STATUS_NO_QUESTS      = "Aucune quête reçue.",
        STATUS_SHOWING        = "Affichage de %s sur %s quêtes. Sens : %s",
        CARD_QUEST_SUMMARY    = "Résumé de la quête",
        CARD_PREVIEW_CONTROLS = "Contrôles de l'aperçu",
        TITLE_STARTER_ENDER   = "Donneur / Fin",
        TITLE_QUICK_REWARD    = "Résumé des récompenses",
        LBL_QUEST_ID          = "ID de quête",
        LBL_TITLE             = "Titre",
        LBL_QUEST_TYPE        = "Type",
        LBL_QUEST_LEVEL       = "Niveau",
        LBL_MIN_LEVEL         = "Niveau min",
        LBL_QUEST_INFO        = "Info",
        LBL_FLAGS             = "Flags",
        LBL_SPECIAL_FLAGS     = "Flags spéciaux",
        LBL_START_NPC         = "PNJ initial",
        LBL_END_NPC           = "PNJ final",
        BTN_OFFER             = "Proposer",
        BTN_IN_PROGRESS       = "En cours",
        BTN_READY             = "Prête",
        BTN_REWARD_PREVIEW    = "Aperçu récompense",
        CHK_SHOW_OBJECTIVES   = "Afficher objectifs",
        CHK_SHOW_REWARDS      = "Afficher récompenses",
        CHK_SHOW_PORTRAIT     = "Afficher portrait",
        CHK_USE_PLAYER_TOKENS = "Utiliser les jetons du joueur ($N, $C)",
        BTN_ACCEPT            = "Accepter",
        BTN_REJECT            = "Refuser",
        BTN_CONTINUE          = "Continuer",
        BTN_CLOSE             = "Fermer",
        BTN_COMPLETE          = "Terminer",
        BTN_CANCEL            = "Annuler",
        LBL_REWARDS_HINT_1    = "Les récompenses complètes s'affichent",
        LBL_REWARDS_HINT_2    = "dans le parchemin central avec défilement.",
        LBL_REPUTATION        = "Réputation",
        LBL_HONOR             = "Honneur",
        LBL_XP                = "XP",
        LBL_MONEY             = "Argent",
        MSG_DELETE_CHAIN_TITLE = "Supprimer la chaîne",
        MSG_DELETE_CHAIN_BODY  = "Vous allez supprimer une chaîne à partir de la quête %s\n\nRewardNextQuest sera suivi vers l'avant." ..
                                 "\n\nPour confirmer, tapez :\nDELETE CHAIN %s",
        HELP_TITLE             = "AzerothCore Quest Builder — Aide",
        HELP_BODY              =
"Cet addon est un éditeur complet de quêtes personnalisées pour AzerothCore, bâti sur AIO.\n\n" ..
"|cffffd87aBoutons d'en-tête|r\n" ..
"  ?           Ouvre cette aide.\n" ..
"  Valider     Demande au serveur de valider le formulaire sans sauvegarder.\n" ..
"  Enregistrer Persiste la quête en base de données.\n" ..
"  Effacer     Réinitialise tous les champs de l'éditeur.\n\n" ..
"|cffffd87aLangue|r\n" ..
"  Menu déroulant en haut à gauche. Langues : English, Español, Português (BR), Français. Le choix est conservé entre les sessions ; les autres clients basculent en anglais.\n\n" ..
"|cffffd87aOnglets|r\n" ..
"  Base           ID, titre, type, niveau, niveau minimum, flags et flags spéciaux.\n" ..
"  Textes         Description du journal, description de la quête, description de la zone et completion log.\n" ..
"  Objectifs      Jusqu'à 4 objectifs (créature/objet/item/sort/zone) et IDs d'emote.\n" ..
"  Récompenses    Items, items de choix, argent, difficulté d'XP, honneur, kill honor, titre, points de talent et d'arène.\n" ..
"  Réputation     Deux récompenses de faction (faction id + valeur, en versions brute et override).\n" ..
"  Chaîne         Quête précédente, suivante, exclusive group et breadcrumb.\n" ..
"  Début          PNJ / GameObject de début et de fin, item source.\n" ..
"  Avancé         Races / classes requises, joueurs suggérés, limite de temps, zone, point d'intérêt.\n" ..
"  Liste de quêtes Navigateur paginé sur votre range custom : recherche par texte, saut par ID, Charger, Copier, Supprimer et Supprimer chaîne.\n" ..
"  Aperçu          Aperçu live au style WoW avec états Proposer / En cours / Prête / Aperçu récompense, toggles objectifs/récompenses/portrait/jetons du joueur, et un résumé rapide des récompenses.\n\n" ..
"|cffffd87aSécurité|r\n" ..
"  Les suppressions sont limitées au range custom (CustomQuestMinId..CustomQuestMaxId). Supprimer chaîne refuse également si la chaîne sort dans le range officiel, sauf si AllowDeleteOutsideCustomRange est activé côté serveur.\n\n" ..
"Toutes les actions passent par la couche RPC d'AIO : le client n'écrit jamais directement en base.",
    },
}

local function GetSelectedLocale()
    if QuestCreator_Settings.locale and LOCALES[QuestCreator_Settings.locale] then
        return QuestCreator_Settings.locale
    end
    local c = (GetLocale and GetLocale()) or "enUS"
    if c == "esES" or c == "esMX" then return "es"
    elseif c == "ptBR" then return "ptBR"
    elseif c == "frFR" then return "fr"
    end
    return "en"
end

local L = setmetatable({}, {
    __index = function(_, key)
        local locale = GetSelectedLocale()
        local localeTable = LOCALES[locale] or LOCALES.en
        local v = localeTable[key]
        if v ~= nil then return v end
        local en = LOCALES.en[key]
        if en ~= nil then return en end
        return key
    end
})

local function SetClientLocale(locale)
    if not LOCALES[locale] then return false end
    QuestCreator_Settings.locale = locale
    if ReloadUI then ReloadUI() end
    return true
end

local frame
local contentFrame
local deleteFrame
local browserStatus
local browserPageText

local pages = {}
local fields = {}
local questRows = {}

local requiredNpcRows = {}
local requiredItemRows = {}
local itemDropRows = {}
local rewardItemRows = {}
local rewardChoiceRows = {}
local rewardFactionRows = {}

local flagChecks = {}
local specialFlagChecks = {}

local preview = {
    state = "offer",
    widgets = {},
    rewardRows = {},
    rewardItemRows = {},
    hooksInstalled = false
}

local currentListId = 1
local currentDeleteQuestId = 0
local activeTextBox = nil

local creatureInfoCache = {}
local gameObjectInfoCache = {}
local creatureModelFrame = nil

local RequestCreatureInfoFromServer
local RequestGameObjectInfoFromServer
local ShowCreatureModelPopup

local isHelpDialogOpen = false

local _preloader = CreateFrame("PlayerModel", "QuestCreatorPreloader", UIParent)
_preloader:SetSize(1, 1)
_preloader:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
_preloader:SetAlpha(0)
_preloader:Show()

local _preloadQueue      = {}
local _preloadQueueSeen  = {}
local _preloadQueueFrame = CreateFrame("Frame")
_preloadQueueFrame:Hide()
_preloadQueueFrame:SetScript("OnUpdate", function(self)
    local id = table.remove(_preloadQueue, 1)
    if id then
        _preloader:ClearModel()
        _preloader:SetCreature(id)
        _preloader:SetCamera(0)
    else
        self:Hide()
    end
end)

local function QueueCreaturePreload(id)
    id = tonumber(id) or 0
    if id <= 0 or _preloadQueueSeen[id] then return end
    _preloadQueueSeen[id] = true
    table.insert(_preloadQueue, id)
    _preloadQueueFrame:Show()
end

local QuestCreator_StreamList = {
    direction = "forward",
    startId = 1,
    pageSize = 16,
    expected = 0,
    quests = {}
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffQuestCreator:|r " .. tostring(msg))
end

local function RGB(r, g, b)
    return r / 255, g / 255, b / 255
end

local GOLD_R, GOLD_G, GOLD_B = RGB(255, 205, 45)
local SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B = RGB(255, 220, 100)
local MUTED_R, MUTED_G, MUTED_B = RGB(210, 190, 145)

local DARK_BG_R, DARK_BG_G, DARK_BG_B = RGB(15, 12, 10)
local CARD_BG_R, CARD_BG_G, CARD_BG_B = RGB(22, 18, 14)
local INPUT_BG_R, INPUT_BG_G, INPUT_BG_B = RGB(8, 6, 4)
local HEADER_BG_R, HEADER_BG_G, HEADER_BG_B = RGB(35, 25, 15)
local BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B = RGB(180, 140, 60)
local TEXT_LABEL_R, TEXT_LABEL_G, TEXT_LABEL_B = RGB(200, 175, 120)
local TEXT_VALUE_R, TEXT_VALUE_G, TEXT_VALUE_B = RGB(230, 220, 200)

local function QC_IsDirection(value)
    value = tostring(value or "")
    return value == "forward" or value == "backward" or value == "search"
end

local function QC_ShiftIfSender(args, expectedFirstIsDirection)
    if expectedFirstIsDirection then
        if not QC_IsDirection(args[1]) then
            table.remove(args, 1)
        end
    else
        if tonumber(args[1]) == nil then
            table.remove(args, 1)
        end
    end
    return args
end

local function QC_FirstRealArg(...)
    local args = { ... }
    if type(args[1]) == "string" and args[1] == UnitName("player") then
        return args[2], args
    end
    if type(args[1]) == "string" and type(args[2]) ~= "nil" then
        return args[2], args
    end
    return args[1], args
end

local function HexDecode(hex)
    hex = tostring(hex or "")
    local out = {}
    for i = 1, string.len(hex), 2 do
        local byte = tonumber(string.sub(hex, i, i + 1), 16)
        if byte then
            out[#out + 1] = string.char(byte)
        end
    end
    return table.concat(out, "")
end

local function TokenReplace(text)
    text = tostring(text or "")
    local playerName = UnitName("player") or "Jugador"
    local playerClass = select(1, UnitClass("player")) or "Clase"
    local playerRace = UnitRace("player") or "Raza"
    text = string.gsub(text, "%$N", playerName)
    text = string.gsub(text, "%$C", playerClass)
    text = string.gsub(text, "%$R", playerRace)
    text = string.gsub(text, "%$B", "\n")
    text = string.gsub(text, "%$G([^:;]-):([^;]-);", "%1")
    return text
end

local function MoneyToText(copper)
    copper = tonumber(copper) or 0
    if copper < 0 then copper = 0 end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return g, s, c
end

local function GetQuestTypeText(v)
    v = tonumber(v) or 2
    if v == 0 then return "AutoComplete"
    elseif v == 1 then return "Disabled" end
    return "Misión Normal"
end

local function SafeSetText(widget, value)
    if widget and widget.SetText then
        widget:SetText(tostring(value or ""))
    end
end

local function CreatePanel(parent, name, x, y, w, h)
    local panel = CreateFrame("Frame", name, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetWidth(w)
    panel:SetHeight(h)
    panel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    panel:SetBackdropColor(CARD_BG_R, CARD_BG_G, CARD_BG_B, 0.98)
    panel:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.8)
    return panel
end

local function CreateCard(parent, name, x, y, w, h, title, iconTexture)
    local card = CreatePanel(parent, name, x, y, w, h)
    if title and title ~= "" then
        local header = CreateFrame("Frame", nil, card)
        header:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -4, -4)
        header:SetHeight(32)
        header:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = nil,
            tile = false,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        header:SetBackdropColor(HEADER_BG_R, HEADER_BG_G, HEADER_BG_B, 0.95)
        local headerBorder = header:CreateTexture(nil, "ARTWORK")
        headerBorder:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        headerBorder:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        headerBorder:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        headerBorder:SetHeight(2)
        headerBorder:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)
        if iconTexture then
            local icon = header:CreateTexture(nil, "OVERLAY")
            icon:SetSize(18, 18)
            icon:SetPoint("LEFT", header, "LEFT", 12, 0)
            icon:SetTexture(iconTexture)
            icon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 0.9)
        end
        local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("CENTER", header, "CENTER", 0, 0)
        titleText:SetText(title)
        titleText:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
        card.title = titleText
        card.header = header
    end
    return card
end

local function CreateDivider(parent, x, y, w)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetWidth(w)
    line:SetHeight(8)
    line:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.5)
    return line
end

local function CreateLabel(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 120)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    label:SetTextColor(TEXT_LABEL_R, TEXT_LABEL_G, TEXT_LABEL_B)
    return label
end

local function CreateMutedLabel(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 200)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    label:SetTextColor(MUTED_R, MUTED_G, MUTED_B)
    return label
end

local function CreateTitle(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 240)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    label:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    return label
end

local function CreateButton(parent, text, x, y, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width or 90)
    button:SetHeight(height or 22)
    button:SetText(text or "")
    return button
end

local function StyleDarkButton(btn, primary)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    if primary then
        btn:SetBackdropColor(0.42, 0.08, 0.04, 0.95)
        btn:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 1)
    else
        btn:SetBackdropColor(0.06, 0.04, 0.03, 0.92)
        btn:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.85)
    end
    btn._isPrimary = primary
end

local function CreateDarkButton(parent, text, x, y, width, height, primary)
    local btn = CreateFrame("Button", nil, parent)
    if x and y then
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    btn:SetWidth(width or 90)
    btn:SetHeight(height or 24)
    StyleDarkButton(btn, primary)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text or "")
    if primary then
        label:SetTextColor(1, 0.92, 0.6)
    else
        label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
    end
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1)
        if self._isPrimary then
            self:SetBackdropColor(0.55, 0.12, 0.05, 0.98)
            self.label:SetTextColor(1, 1, 0.85)
        else
            self:SetBackdropColor(0.12, 0.08, 0.05, 0.98)
            self.label:SetTextColor(1, 0.95, 0.7)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self._isPrimary then
            self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 1)
            self:SetBackdropColor(0.42, 0.08, 0.04, 0.95)
            self.label:SetTextColor(1, 0.92, 0.6)
        else
            self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.85)
            self:SetBackdropColor(0.06, 0.04, 0.03, 0.92)
            self.label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
        end
    end)
    btn:SetScript("OnMouseDown", function(self)
        if self.label then
            self.label:SetPoint("CENTER", self, "CENTER", 1, -1)
        end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if self.label then
            self.label:SetPoint("CENTER", self, "CENTER", 0, 0)
        end
    end)
    return btn
end

local function CreateIconActionButton(parent, text, iconTexture, width)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 78)
    btn:SetHeight(22)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.06, 0.04, 0.03, 0.95)
    btn:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.7)

    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetSize(11, 11)
    icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
    if iconTexture then
        icon:SetTexture(iconTexture)
    end
    icon:SetVertexColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B, 0.95)
    btn.icon = icon

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", btn, "LEFT", 22, 0)
    label:SetText(text or "")
    label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1)
        self:SetBackdropColor(0.12, 0.08, 0.05, 0.98)
        self.label:SetTextColor(1, 0.95, 0.7)
        if self.icon then self.icon:SetVertexColor(1, 0.95, 0.7, 1) end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.7)
        self:SetBackdropColor(0.06, 0.04, 0.03, 0.95)
        self.label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
        if self.icon then self.icon:SetVertexColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B, 0.95) end
    end)
    return btn
end

local function CreatePagerButton(parent, glyph, width)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 28)
    btn:SetHeight(24)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.06, 0.04, 0.03, 0.95)
    btn:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.8)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(glyph or "")
    label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1)
        self.label:SetTextColor(1, 0.95, 0.7)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.8)
        self.label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
    end)
    return btn
end

local function CreateHeaderActionButton(parent, text, x, y, width, height, primary, normalTexCoord, hoverTexCoord)
    local btn = CreateFrame("Button", nil, parent)
    if x and y then
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    btn:SetWidth(width or 100)
    btn:SetHeight(height or 28)
    
    -- TEXTURA NORMAL del botón
    local normalTexture = btn:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints(btn)
    normalTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    if normalTexCoord then
        normalTexture:SetTexCoord(normalTexCoord[1], normalTexCoord[2], normalTexCoord[3], normalTexCoord[4])
    else
        normalTexture:SetTexCoord(0.005859375, 0.099609375, 0.689453125, 0.734375000)
    end
    
    -- TEXTURA HOVER
    local hoverTexture = btn:CreateTexture(nil, "BORDER")
    hoverTexture:SetAllPoints(btn)
    hoverTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    if hoverTexCoord then
        hoverTexture:SetTexCoord(hoverTexCoord[1], hoverTexCoord[2], hoverTexCoord[3], hoverTexCoord[4])
    else
        hoverTexture:SetTexCoord(0.101562500, 0.195312500, 0.689453125, 0.734375000)
    end
    hoverTexture:Hide()
    
    btn.normalTex = normalTexture
    btn.hoverTex = hoverTexture

    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
    icon:SetVertexColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B, 0.95)
    btn.icon = icon

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", btn, "LEFT", 38, 0)
    label:SetText(text or "")
    if primary then
        label:SetTextColor(1, 0.92, 0.6)
    else
        label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
    end
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        if self.hoverTex then
            self.normalTex:Hide()
            self.hoverTex:Show()
        end
        if self.label then
            self.label:SetTextColor(1, 0.95, 0.7)
        end
        if self.icon then
            self.icon:SetVertexColor(1, 0.95, 0.7, 1)
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        if self.hoverTex then
            self.normalTex:Show()
            self.hoverTex:Hide()
        end
        if self.label then
            if self._isPrimary then
                self.label:SetTextColor(1, 0.92, 0.6)
            else
                self.label:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
            end
        end
        if self.icon then
            if self._isPrimary then
                self.icon:SetVertexColor(1, 0.92, 0.6, 0.95)
            else
                self.icon:SetVertexColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B, 0.95)
            end
        end
    end)
    return btn
end

local function CreateHelpButton(parent, x, y, size)
    local btn = CreateFrame("Button", nil, parent)
    if x and y then
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    local s = size
    btn:SetSize(s, s)
    
    -- TEXTURA PRINCIPAL
    local mainTexture = btn:CreateTexture(nil, "BACKGROUND")
    mainTexture:SetAllPoints(btn)
    mainTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    mainTexture:SetTexCoord(0.775390625, 0.833984375, 0.782226563, 0.840820313)
    
    -- EFECTO DE BRILLO
    local glowTexture = btn:CreateTexture(nil, "OVERLAY")
    glowTexture:SetAllPoints(btn)
    glowTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    glowTexture:SetTexCoord(0.775390625, 0.833984375, 0.782226563, 0.840820313)
    glowTexture:SetBlendMode("ADD")
    glowTexture:SetAlpha(0)

    local time = 0
    local state = "waiting"
    local blinkCount = 0
    local blinkPhase = 0
    local isActive = true
    
    local function resetBlinkCycle()
        time = 0
        state = "waiting"
        blinkCount = 0
        blinkPhase = 0
        glowTexture:SetAlpha(0)
    end
    
    local function stopBlinking()
        isActive = false
        glowTexture:SetAlpha(0)
    end
    
    local function resumeBlinking()
        if not isActive and not isHelpDialogOpen then
            isActive = true
            resetBlinkCycle()
        end
    end

    btn:SetScript("OnClick", function(self)
        ShowHelpDialog()
    end)

    btn:SetScript("OnUpdate", function(self, elapsed)
        if not isActive or isHelpDialogOpen then
            return
        end
        
        if state == "waiting" then
            time = time + elapsed
            if time >= 5 then
                time = 0
                blinkCount = 0
                state = "blinking"
                blinkPhase = 0
            end
            
        elseif state == "blinking" then
            if blinkPhase == 0 then
                local alpha = glowTexture:GetAlpha() + elapsed * 1.5
                if alpha >= 0.6 then
                    glowTexture:SetAlpha(0.6)
                    blinkPhase = 1
                else
                    glowTexture:SetAlpha(alpha)
                end
                
            elseif blinkPhase == 1 then
                local alpha = glowTexture:GetAlpha() - elapsed * 1.2
                if alpha <= 0 then
                    glowTexture:SetAlpha(0)
                    blinkCount = blinkCount + 1
                    blinkPhase = 0
                    
                    if blinkCount >= 3 then
                        state = "waiting"
                        time = 0
                    end
                else
                    glowTexture:SetAlpha(alpha)
                end
            end
        end
    end)
    
    btn.stopBlinking = stopBlinking
    btn.resumeBlinking = resumeBlinking
    return btn
end

local function ShowHelpDialog()
    local f = QuestCreator._helpFrame
    if not f then
        f = CreateFrame("Frame", "QuestCreatorHelpFrame", UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        tinsert(UISpecialFrames, "QuestCreatorHelpFrame")
        f:SetWidth(560)
        f:SetHeight(440)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\ui-tooltip-border-maw",
            tile     = true,
            tileSize = 16,
            edgeSize = 22,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 1)
        f:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -18)
        title:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
        f.title = title

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
        close:SetScript("OnClick", function()
            f:Hide()
            isHelpDialogOpen = false
            PlaySound("igSpellBookClose") 
            if QuestCreator._helpButton then
                QuestCreator._helpButton:resumeBlinking()
            end
        end)

        local scroll = CreateFrame("ScrollFrame", "QuestCreatorHelpScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -52)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 56)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(490)
        content:SetHeight(900)
        scroll:SetScrollChild(content)

        local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        body:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
        body:SetWidth(480)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        body:SetSpacing(2)
        body:SetTextColor(0.95, 0.85, 0.55)
        f.body = body
        f.bodyContent = content

        local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        okBtn:SetWidth(100)
        okBtn:SetHeight(28)
        okBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 18)
        okBtn:SetText(L.BTN_CLOSE)
        okBtn:SetScript("OnClick", function()
            f:Hide()
            isHelpDialogOpen = false
            PlaySound("igSpellBookClose") 
            if QuestCreator._helpButton then
                QuestCreator._helpButton:resumeBlinking()
            end
        end)
        f.okBtn = okBtn

        QuestCreator._helpFrame = f
    end

    isHelpDialogOpen = true
    PlaySound("igSpellBookOpen")
    if QuestCreator._helpButton then
        QuestCreator._helpButton:stopBlinking()
    end

    f.title:SetText(L.HELP_TITLE)
    f.body:SetText(L.HELP_BODY or "")
    if f.okBtn and f.okBtn.label then
        f.okBtn.label:SetText(L.BTN_CLOSE)
    end
    local h = f.body:GetStringHeight() + 30
    if h < 360 then h = 360 end
    f.bodyContent:SetHeight(h)
    f:Show()
    f:Raise()
end

local function CreateTabButton(parent, text, x, y, width, height)
    QuestCreator._tabCounter = (QuestCreator._tabCounter or 0) + 1
    local btnName = "QuestCreatorTab" .. QuestCreator._tabCounter
    local btn = CreateFrame("Button", btnName, parent)
    btn:SetSize(width, height)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- TEXTURA NORMAL
    local normalTexture = btn:CreateTexture(nil, "BORDER")
    normalTexture:SetPoint("TOPLEFT", btn, "TOPLEFT", -10, 10)
    normalTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 10, -10)
    normalTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    normalTexture:SetTexCoord(0.000000000, 0.148437500, 0.623046875, 0.681640625)
    
    -- TEXTURA HOVER
    local hoverTexture = btn:CreateTexture(nil, "OVERLAY")
    hoverTexture:SetPoint("TOPLEFT", btn, "TOPLEFT", -10, 10)
    hoverTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 10, -10)
    hoverTexture:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    hoverTexture:SetTexCoord(0.147460938, 0.294921875, 0.623046875, 0.681640625)
    hoverTexture:Hide()
    
    -- Texto
    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btnText:SetText(text)
    btnText:SetTextColor(0.85, 0.85, 0.9, 1)
    
    btn:SetScript("OnEnter", function(self)
        if not self._active then
            hoverTexture:Show()
            normalTexture:Hide()
            btnText:SetTextColor(1, 0.95, 0.6, 1)
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        if not self._active then
            hoverTexture:Hide()
            normalTexture:Show()
            btnText:SetTextColor(0.85, 0.85, 0.9, 1)
        end
    end)

    btn:SetScript("OnClick", function(self)
        PlaySound("igCharacterInfoTab")
        ShowPageAndUpdateTabs(item[2])
    end)

    function btn:Activate()
        self._active = true
        hoverTexture:Show()
        normalTexture:Hide()
        btnText:SetTextColor(1, 0.95, 0.6, 1)
    end

    function btn:Deactivate()
        self._active = false
        hoverTexture:Hide()
        normalTexture:Show()
        btnText:SetTextColor(0.85, 0.85, 0.9, 1)
    end
    
    btn.tabName = text
    
    return btn
end

local function CreateEditBox(parent, name, x, y, width, height, numeric)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetWidth(width or 100)
    box:SetHeight(height or 24)
    box:SetAutoFocus(false)
    box:SetMultiLine(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetTextInsets(8, 8, 4, 4)
    box:SetText("")
    box:SetCursorPosition(0)
    box:SetTextColor(TEXT_VALUE_R, TEXT_VALUE_G, TEXT_VALUE_B)
    if numeric then
        box:SetNumeric(true)
    end
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    box:SetBackdropColor(INPUT_BG_R, INPUT_BG_G, INPUT_BG_B, 1)
    box:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)
    box:SetScript("OnEditFocusGained", function(self)
        activeTextBox = self
        self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)
    end)
    if name then
        fields[name] = box
    end
    return box
end

local function CreateMultiLineBox(parent, name, x, y, width, height)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetWidth(width)
    box:SetHeight(height)
    box:SetAutoFocus(false)
    box:SetMultiLine(true)
    box:SetFontObject(ChatFontNormal)
    box:SetTextInsets(8, 8, 8, 8)
    box:SetText("")
    box:SetCursorPosition(0)
    box:SetTextColor(TEXT_VALUE_R, TEXT_VALUE_G, TEXT_VALUE_B)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    box:SetBackdropColor(INPUT_BG_R, INPUT_BG_G, INPUT_BG_B, 1)
    box:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)
    box:SetScript("OnEditFocusGained", function(self)
        activeTextBox = self
        self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)
    end)
    if name then
        fields[name] = box
    end
    return box
end

local function MakeReadOnlyPreviewBox(parent, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetWidth(w)
    box:SetHeight(h)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    box:SetBackdropColor(INPUT_BG_R, INPUT_BG_G, INPUT_BG_B, 1)
    box:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.4)
    local fs = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -6)
    fs:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -8, 6)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetTextColor(TEXT_VALUE_R, TEXT_VALUE_G, TEXT_VALUE_B)
    return box, fs
end

local function SetBox(name, value)
    if fields[name] and fields[name].SetText then
        fields[name]:SetText(tostring(value or ""))
    end
end

local function GetText(name)
    if fields[name] and fields[name].GetText then
        return fields[name]:GetText() or ""
    end
    return ""
end

local function GetNumber(name, default)
    local n = tonumber(GetText(name))
    if n == nil then
        return default or 0
    end
    return math.floor(n)
end

local function CreateNumberField(parent, label, name, x, y, labelW, boxW)
    CreateLabel(parent, label, x, y, labelW or 100)
    local box = CreateEditBox(parent, name, x + (labelW or 100) + 8, y - 2, boxW or 90, 22, true)
    box:SetText("0")
    return box
end

local function CreatePlainField(parent, label, name, x, y, labelW, boxW, numeric)
    CreateLabel(parent, label, x, y, labelW or 100)
    local box = CreateEditBox(parent, name, x + (labelW or 100) + 8, y - 2, boxW or 90, 22, numeric)
    box:SetText("0")
    return box
end

local function CreateDropDown(parent, name, x, y, width, options, defaultValue)
    local dropdownName = "QuestCreatorDropDown_" .. name
    local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 15, y + 5)
    fields[name] = {
        value = defaultValue,
        _isDropdownProxy = true,
        SetText = function(self, value)
            self.value = value
            for _, option in ipairs(options) do
                if tostring(option.value) == tostring(value) then
                    UIDropDownMenu_SetText(dropdown, option.text)
                    return
                end
            end
            UIDropDownMenu_SetText(dropdown, tostring(value))
        end,
        GetText = function(self)
            return tostring(self.value or "")
        end
    }
    UIDropDownMenu_SetWidth(dropdown, width or 120)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.checked = tostring(fields[name].value) == tostring(option.value)
            info.func = function()
                fields[name].value = option.value
                UIDropDownMenu_SetText(dropdown, option.text)
                if QuestCreator.UpdatePreview then
                    QuestCreator.UpdatePreview()
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    fields[name]:SetText(defaultValue)
    return dropdown
end

local function CreateCheck(parent, label, x, y, checked)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetWidth(18)
    check:SetHeight(18)
    check:SetChecked(checked or false)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 20, y + 1)
    text:SetText(label or "")
    text:SetTextColor(TEXT_LABEL_R, TEXT_LABEL_G, TEXT_LABEL_B)
    check.text = text
    return check
end

local QuestCreator_Flags = {
    { key = "stayAlive",       label = "1 - Stay Alive",          value = 1      },
    { key = "partyAccept",     label = "2 - Party Accept",         value = 2      },
    { key = "exploration",     label = "4 - Exploration",          value = 4      },
    { key = "sharable",        label = "8 - Sharable",             value = 8      },
    { key = "hideRewardPoi",   label = "32 - Hide Reward POI",     value = 32     },
    { key = "raid",            label = "64 - Raid",                value = 64     },
    { key = "noMoneyFromXp",   label = "256 - No Money From XP",   value = 256    },
    { key = "hiddenRewards",   label = "512 - Hidden Rewards",     value = 512    },
    { key = "tracking",        label = "1024 - Tracking",          value = 1024   },
    { key = "daily",           label = "4096 - Daily",             value = 4096   },
    { key = "weekly",          label = "32768 - Weekly",           value = 32768  },
    { key = "autoComplete",    label = "65536 - AutoComplete",     value = 65536  },
    { key = "autoAccept",      label = "524288 - AutoAccept",      value = 524288 },
}

local QuestCreator_SpecialFlags = {
    { key = "repeatable",        label = "1 - Repeatable",              value = 1   },
    { key = "explorationEvent",  label = "2 - Exploration/Event",       value = 2   },
    { key = "autoAccept",        label = "4 - Auto Accept",             value = 4   },
    { key = "dfQuest",           label = "8 - Dungeon Finder",          value = 8   },
    { key = "monthly",           label = "16 - Monthly",                value = 16  },
    { key = "cast",              label = "32 - Cast (KillCredit)",      value = 32  },
    { key = "noRepSpillover",    label = "64 - No Rep Spillover",       value = 64  },
    { key = "canFailAnyState",   label = "128 - Can Fail Any State",    value = 128 },
    { key = "noLoremasterCount", label = "256 - No Loremaster Count",   value = 256 },
}

local function CalculateChecks(defs, checks)
    local value = 0
    for _, def in ipairs(defs) do
        local check = checks[def.key]
        if check and check:GetChecked() then
            value = value + def.value
        end
    end
    return value
end

local function ApplyChecks(value, defs, checks)
    value = tonumber(value) or 0
    if not bit or not bit.band then
        return
    end
    for _, def in ipairs(defs) do
        local check = checks[def.key]
        if check then
            check:SetChecked(bit.band(value, def.value) ~= 0)
        end
    end
end

local function RefreshFlagsBox()
    SetBox("flags", CalculateChecks(QuestCreator_Flags, flagChecks))
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

local function RefreshSpecialFlagsBox()
    SetBox("specialFlags", CalculateChecks(QuestCreator_SpecialFlags, specialFlagChecks))
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

local function CreatePage(parent, name)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    page:SetWidth(1150)
    page:SetHeight(540)
    page:Hide()
    pages[name] = page
    return page
end

local function HideAllPages()
    for _, page in pairs(pages) do
        page:Hide()
    end
end

local function ShowPage(name)
    HideAllPages()
    if pages[name] then
        pages[name]:Show()
    end
    if name == "preview" and QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

local function CreatePairRows(parent, rows, title, x, y, slots, entryPrefix, countPrefix, compact)
    CreateTitle(parent, title, x, y, 260)
    local rowGap = compact and 26 or 30
    local entryW = compact and 95 or 105
    local countW = compact and 80 or 90
    local headerY = y - 30
    local rowY = y - 54
    CreateLabel(parent, "Entry", x + 48, headerY, 80)
    CreateLabel(parent, "Count", x + 175, headerY, 80)
    for i = 1, slots do
        CreateLabel(parent, tostring(i), x + 5, rowY + 4, 24)
        local entry = CreateEditBox(parent, entryPrefix .. i, x + 42, rowY, entryW, 22, false)
        entry:SetText("0")
        local count = CreateEditBox(parent, countPrefix .. i, x + 170, rowY, countW, 22, false)
        count:SetText("0")
        rows[i] = { entry = entry, count = count }
        rowY = rowY - rowGap
    end
end

local function ReadPairRows(rows)
    local data = {}
    for i, row in ipairs(rows) do
        data[i] = {
            entry = tonumber(row.entry:GetText()) or 0,
            count = tonumber(row.count:GetText()) or 0
        }
    end
    return data
end

local function FillPairRows(rows, quest, entryPrefix, countPrefix)
    for i, row in ipairs(rows) do
        row.entry:SetText(tostring(quest[entryPrefix .. i] or 0))
        row.count:SetText(tostring(quest[countPrefix .. i] or 0))
    end
end

local function ClearPairRows(rows)
    for _, row in ipairs(rows) do
        row.entry:SetText("0")
        row.count:SetText("0")
    end
end

local function BuildPayloadFromUI()
    local objectiveTexts = {}
    for i = 1, 4 do
        objectiveTexts[i] = GetText("objectiveText" .. i)
    end
    local rewardFactions = {}
    for i = 1, 5 do
        rewardFactions[i] = {
            faction = GetNumber("rewardFactionId" .. i, 0),
            value = GetNumber("rewardFactionValue" .. i, 0),
            override = GetNumber("rewardFactionOverride" .. i, 0)
        }
    end
    return {
        id = GetNumber("id", 0),
        title = GetText("title"),
        questType = GetNumber("questType", 2),
        questLevel = GetNumber("questLevel", 1),
        minLevel = GetNumber("minLevel", 1),
        questSortId = GetNumber("questSortId", 0),
        questInfoId = GetNumber("questInfoId", 0),
        suggestedGroupNum = GetNumber("suggestedGroupNum", 0),
        allowableRaces = GetNumber("allowableRaces", 0),
        flags = GetNumber("flags", 8),
        specialFlags = GetNumber("specialFlags", 0),
        logDescription = GetText("logDescription"),
        questDescription = GetText("questDescription"),
        areaDescription = GetText("areaDescription"),
        completionLog = GetText("completionLog"),
        completionText = GetText("completionText"),
        rewardText = GetText("rewardText"),
        requiredPlayerKills = GetNumber("requiredPlayerKills", 0),
        requiredNpcOrGo = ReadPairRows(requiredNpcRows),
        requiredItems = ReadPairRows(requiredItemRows),
        itemDrops = ReadPairRows(itemDropRows),
        objectiveTexts = objectiveTexts,
        rewardXpDifficulty = GetNumber("rewardXpDifficulty", 5),
        rewardMoney = GetNumber("rewardMoney", 0),
        rewardMoneyDifficulty = GetNumber("rewardMoneyDifficulty", 0),
        rewardDisplaySpell = GetNumber("rewardDisplaySpell", 0),
        rewardSpell = GetNumber("rewardSpell", 0),
        rewardHonor = GetNumber("rewardHonor", 0),
        rewardKillHonor = GetNumber("rewardKillHonor", 0),
        startItem = GetNumber("startItem", 0),
        rewardTitle = GetNumber("rewardTitle", 0),
        rewardTalents = GetNumber("rewardTalents", 0),
        rewardArenaPoints = GetNumber("rewardArenaPoints", 0),
        rewardItems = ReadPairRows(rewardItemRows),
        rewardChoiceItems = ReadPairRows(rewardChoiceRows),
        requiredFactionId1 = GetNumber("requiredFactionId1", 0),
        requiredFactionId2 = GetNumber("requiredFactionId2", 0),
        requiredFactionValue1 = GetNumber("requiredFactionValue1", 0),
        requiredFactionValue2 = GetNumber("requiredFactionValue2", 0),
        rewardFactions = rewardFactions,
        prevQuestId = GetNumber("prevQuestId", 0),
        nextQuestId = GetNumber("nextQuestId", 0),
        rewardNextQuest = GetNumber("rewardNextQuest", 0),
        exclusiveGroup = GetNumber("exclusiveGroup", 0),
        starter = { type = GetText("starterType"), entry = GetNumber("starterEntry", 0) },
        ender = { type = GetText("enderType"), entry = GetNumber("enderEntry", 0) },
        maxLevel = GetNumber("maxLevel", 0),
        allowableClasses = GetNumber("allowableClasses", 0),
        sourceSpellId = GetNumber("sourceSpellId", 0),
        rewardMailTemplateId = GetNumber("rewardMailTemplateId", 0),
        rewardMailDelay = GetNumber("rewardMailDelay", 0),
        requiredSkillId = GetNumber("requiredSkillId", 0),
        requiredSkillPoints = GetNumber("requiredSkillPoints", 0),
        requiredMinRepFaction = GetNumber("requiredMinRepFaction", 0),
        requiredMaxRepFaction = GetNumber("requiredMaxRepFaction", 0),
        requiredMinRepValue = GetNumber("requiredMinRepValue", 0),
        requiredMaxRepValue = GetNumber("requiredMaxRepValue", 0),
        providedItemCount = GetNumber("providedItemCount", 0),
        emoteOnComplete = GetNumber("emoteOnComplete", 1),
        emoteOnIncomplete = GetNumber("emoteOnIncomplete", 0),
        rewardEmote1 = GetNumber("rewardEmote1", 0),
        rewardEmote2 = GetNumber("rewardEmote2", 0),
        rewardEmote3 = GetNumber("rewardEmote3", 0),
        rewardEmote4 = GetNumber("rewardEmote4", 0),
        rewardEmoteDelay1 = GetNumber("rewardEmoteDelay1", 0),
        rewardEmoteDelay2 = GetNumber("rewardEmoteDelay2", 0),
        rewardEmoteDelay3 = GetNumber("rewardEmoteDelay3", 0),
        rewardEmoteDelay4 = GetNumber("rewardEmoteDelay4", 0),
        timeAllowed = GetNumber("timeAllowed", 0),
        poiContinent = GetNumber("poiContinent", 0),
        poiX = GetNumber("poiX", 0),
        poiY = GetNumber("poiY", 0),
        poiPriority = GetNumber("poiPriority", 0),
        unknown0 = GetNumber("unknown0", 0),
        verifiedBuild = GetNumber("verifiedBuild", 12340),
        requestVerifiedBuild = GetNumber("requestVerifiedBuild", 12340),
        offerVerifiedBuild = GetNumber("offerVerifiedBuild", 12340)
    }
end

local function ClearEditor()
    for _, field in pairs(fields) do
        if field and field.SetText and not field._isDropdownProxy then
            field:SetText("0")
        end
    end
    SetBox("id", 7000)
    SetBox("title", "Nueva misión")
    SetBox("questType", 2)
    SetBox("questLevel", 1)
    SetBox("minLevel", 1)
    SetBox("questSortId", 0)
    SetBox("questInfoId", 0)
    SetBox("suggestedGroupNum", 0)
    SetBox("allowableRaces", 0)
    SetBox("flags", 8)
    SetBox("specialFlags", 0)
    ApplyChecks(8, QuestCreator_Flags, flagChecks)
    ApplyChecks(0, QuestCreator_SpecialFlags, specialFlagChecks)
    SetBox("logDescription", "Objetivo corto de la misión.")
    SetBox("questDescription", "Saludos, $N.$B$BNecesito que completes esta misión.")
    SetBox("areaDescription", "")
    SetBox("completionLog", "Regresa cuando termines.")
    SetBox("completionText", "¿Ya completaste la tarea, $N?")
    SetBox("rewardText", "Buen trabajo, $N.")
    SetBox("requiredPlayerKills", 0)
    SetBox("rewardXpDifficulty", 5)
    SetBox("rewardMoney", 0)
    SetBox("rewardMoneyDifficulty", 0)
    SetBox("rewardDisplaySpell", 0)
    SetBox("rewardSpell", 0)
    SetBox("rewardHonor", 0)
    SetBox("rewardKillHonor", 0)
    SetBox("startItem", 0)
    SetBox("rewardTitle", 0)
    SetBox("rewardTalents", 0)
    SetBox("rewardArenaPoints", 0)
    SetBox("requiredFactionId1", 0)
    SetBox("requiredFactionId2", 0)
    SetBox("requiredFactionValue1", 0)
    SetBox("requiredFactionValue2", 0)
    SetBox("prevQuestId", 0)
    SetBox("nextQuestId", 0)
    SetBox("rewardNextQuest", 0)
    SetBox("exclusiveGroup", 0)
    SetBox("starterType", "creature")
    SetBox("starterEntry", 0)
    SetBox("enderType", "creature")
    SetBox("enderEntry", 0)
    SetBox("maxLevel", 0)
    SetBox("allowableClasses", 0)
    SetBox("sourceSpellId", 0)
    SetBox("rewardMailTemplateId", 0)
    SetBox("rewardMailDelay", 0)
    SetBox("requiredSkillId", 0)
    SetBox("requiredSkillPoints", 0)
    SetBox("requiredMinRepFaction", 0)
    SetBox("requiredMinRepValue", 0)
    SetBox("requiredMaxRepFaction", 0)
    SetBox("requiredMaxRepValue", 0)
    SetBox("providedItemCount", 0)
    SetBox("emoteOnComplete", 1)
    SetBox("emoteOnIncomplete", 0)
    SetBox("rewardEmote1", 0)
    SetBox("rewardEmote2", 0)
    SetBox("rewardEmote3", 0)
    SetBox("rewardEmote4", 0)
    SetBox("rewardEmoteDelay1", 0)
    SetBox("rewardEmoteDelay2", 0)
    SetBox("rewardEmoteDelay3", 0)
    SetBox("rewardEmoteDelay4", 0)
    SetBox("timeAllowed", 0)
    SetBox("poiContinent", 0)
    SetBox("poiX", 0)
    SetBox("poiY", 0)
    SetBox("poiPriority", 0)
    SetBox("unknown0", 0)
    SetBox("verifiedBuild", 12340)
    SetBox("requestVerifiedBuild", 12340)
    SetBox("offerVerifiedBuild", 12340)
    ClearPairRows(requiredNpcRows)
    ClearPairRows(requiredItemRows)
    ClearPairRows(itemDropRows)
    ClearPairRows(rewardItemRows)
    ClearPairRows(rewardChoiceRows)
    for i = 1, 5 do
        SetBox("rewardFactionId" .. i, 0)
        SetBox("rewardFactionValue" .. i, 0)
        SetBox("rewardFactionOverride" .. i, 0)
    end
    for i = 1, 4 do
        SetBox("objectiveText" .. i, "")
    end
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

local function LoadQuestIntoFields(quest)
    if type(quest) ~= "table" then
        return
    end
    SetBox("id", quest.id or 0)
    SetBox("title", quest.title or "")
    SetBox("questType", quest.questType or 2)
    SetBox("questLevel", quest.questLevel or 1)
    SetBox("minLevel", quest.minLevel or 1)
    SetBox("questSortId", quest.questSortId or 0)
    SetBox("questInfoId", quest.questInfoId or 0)
    SetBox("suggestedGroupNum", quest.suggestedGroupNum or 0)
    SetBox("allowableRaces", quest.allowableRaces or 0)
    SetBox("flags", quest.flags or 0)
    SetBox("specialFlags", quest.specialFlags or 0)
    ApplyChecks(quest.flags or 0, QuestCreator_Flags, flagChecks)
    ApplyChecks(quest.specialFlags or 0, QuestCreator_SpecialFlags, specialFlagChecks)
    SetBox("logDescription", quest.logDescription or "")
    SetBox("questDescription", quest.questDescription or "")
    SetBox("areaDescription", quest.areaDescription or "")
    SetBox("completionLog", quest.completionLog or "")
    SetBox("completionText", quest.completionText or "")
    SetBox("rewardText", quest.rewardText or "")
    SetBox("requiredPlayerKills", quest.requiredPlayerKills or 0)
    SetBox("rewardXpDifficulty", quest.rewardXpDifficulty or 5)
    SetBox("rewardMoney", quest.rewardMoney or 0)
    SetBox("rewardMoneyDifficulty", quest.rewardMoneyDifficulty or 0)
    SetBox("rewardDisplaySpell", quest.rewardDisplaySpell or 0)
    SetBox("rewardSpell", quest.rewardSpell or 0)
    SetBox("rewardHonor", quest.rewardHonor or 0)
    SetBox("rewardKillHonor", quest.rewardKillHonor or 0)
    SetBox("startItem", quest.startItem or 0)
    SetBox("rewardTitle", quest.rewardTitle or 0)
    SetBox("rewardTalents", quest.rewardTalents or 0)
    SetBox("rewardArenaPoints", quest.rewardArenaPoints or 0)
    SetBox("requiredFactionId1", quest.requiredFactionId1 or 0)
    SetBox("requiredFactionId2", quest.requiredFactionId2 or 0)
    SetBox("requiredFactionValue1", quest.requiredFactionValue1 or 0)
    SetBox("requiredFactionValue2", quest.requiredFactionValue2 or 0)
    SetBox("prevQuestId", quest.prevQuestId or 0)
    SetBox("nextQuestId", quest.nextQuestId or 0)
    SetBox("rewardNextQuest", quest.rewardNextQuest or 0)
    SetBox("exclusiveGroup", quest.exclusiveGroup or 0)
    SetBox("maxLevel", quest.maxLevel or 0)
    SetBox("allowableClasses", quest.allowableClasses or 0)
    SetBox("sourceSpellId", quest.sourceSpellId or 0)
    SetBox("rewardMailTemplateId", quest.rewardMailTemplateId or 0)
    SetBox("rewardMailDelay", quest.rewardMailDelay or 0)
    SetBox("requiredSkillId", quest.requiredSkillId or 0)
    SetBox("requiredSkillPoints", quest.requiredSkillPoints or 0)
    SetBox("requiredMinRepFaction", quest.requiredMinRepFaction or 0)
    SetBox("requiredMinRepValue", quest.requiredMinRepValue or 0)
    SetBox("requiredMaxRepFaction", quest.requiredMaxRepFaction or 0)
    SetBox("requiredMaxRepValue", quest.requiredMaxRepValue or 0)
    SetBox("providedItemCount", quest.providedItemCount or 0)
    SetBox("emoteOnComplete", quest.emoteOnComplete or 1)
    SetBox("emoteOnIncomplete", quest.emoteOnIncomplete or 0)
    SetBox("rewardEmote1", quest.rewardEmote1 or 0)
    SetBox("rewardEmote2", quest.rewardEmote2 or 0)
    SetBox("rewardEmote3", quest.rewardEmote3 or 0)
    SetBox("rewardEmote4", quest.rewardEmote4 or 0)
    SetBox("rewardEmoteDelay1", quest.rewardEmoteDelay1 or 0)
    SetBox("rewardEmoteDelay2", quest.rewardEmoteDelay2 or 0)
    SetBox("rewardEmoteDelay3", quest.rewardEmoteDelay3 or 0)
    SetBox("rewardEmoteDelay4", quest.rewardEmoteDelay4 or 0)
    SetBox("timeAllowed", quest.timeAllowed or 0)
    SetBox("poiContinent", quest.poiContinent or 0)
    SetBox("poiX", quest.poiX or 0)
    SetBox("poiY", quest.poiY or 0)
    SetBox("poiPriority", quest.poiPriority or 0)
    SetBox("unknown0", quest.unknown0 or 0)
    SetBox("verifiedBuild", quest.verifiedBuild or 12340)
    SetBox("requestVerifiedBuild", quest.requestVerifiedBuild or 12340)
    SetBox("offerVerifiedBuild", quest.offerVerifiedBuild or 12340)
    FillPairRows(requiredNpcRows, quest, "requiredNpcOrGo", "requiredNpcOrGoCount")
    FillPairRows(requiredItemRows, quest, "requiredItemId", "requiredItemCount")
    FillPairRows(itemDropRows, quest, "itemDrop", "itemDropQuantity")
    FillPairRows(rewardItemRows, quest, "rewardItem", "rewardAmount")
    FillPairRows(rewardChoiceRows, quest, "rewardChoiceItemId", "rewardChoiceItemQuantity")
    if quest.starter then
        SetBox("starterType", quest.starter.type or "creature")
        SetBox("starterEntry", quest.starter.entry or 0)
    end
    if quest.ender then
        SetBox("enderType", quest.ender.type or "creature")
        SetBox("enderEntry", quest.ender.entry or 0)
    end
    for i = 1, 4 do
        SetBox("objectiveText" .. i, quest["objectiveText" .. i] or "")
    end
    if quest.rewardFactions then
        for i = 1, 5 do
            local row = quest.rewardFactions[i]
            if row then
                SetBox("rewardFactionId" .. i, row.faction or 0)
                SetBox("rewardFactionValue" .. i, row.value or 0)
                SetBox("rewardFactionOverride" .. i, row.override or 0)
            end
        end
    end
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

-- =========================================================
-- BASIC PAGE RECREADO - Frame compacto proporcional
-- =========================================================
local function CreateBasicPage(parent)
    local p = CreatePage(parent, "basic")

    local CARD_W = 340
    local CARD_H = 480
    local GAP = 16
    local TOTAL_W = CARD_W + GAP + (CARD_W + 20) + GAP + (CARD_W + 20)
    local START_X = math.floor((1150 - TOTAL_W) / 2)

    local ICON_BASIC = "Interface\\Icons\\INV_Misc_Book_09"
    local ICON_FLAGS = "Interface\\Icons\\Ability_Parry"
    local ICON_SPECIAL = "Interface\\Icons\\Spell_Holy_SurgeOfLight"

    local left  = CreateCard(p, nil,  START_X, -18, CARD_W, CARD_H, "Basic", ICON_BASIC)
    local mid   = CreateCard(p, nil,  START_X + CARD_W + GAP, -18, CARD_W + 20, CARD_H, "Flags", ICON_FLAGS)
    local right = CreateCard(p, nil,  START_X + CARD_W + GAP + CARD_W + 20 + GAP, -18, CARD_W + 20, CARD_H, "SpecialFlags", ICON_SPECIAL)

    local LABEL_W = 100
    local INPUT_X = 110
    local INPUT_W = 210
    local ROW_H = 36
    local startY = -48

    CreateLabel(left, "ID", 14, startY, LABEL_W)
    local idBox = CreateEditBox(left, "id", INPUT_X, startY - 2, INPUT_W, 22, true)
    idBox:SetText("7000")

    CreateLabel(left, "QuestType", 14, startY - ROW_H, LABEL_W)
    CreateDropDown(left, "questType", INPUT_X + 15, startY - ROW_H - 6, INPUT_W - 30, {
        { text = "2 - Normal",       value = 2 },
        { text = "0 - AutoComplete", value = 0 },
        { text = "1 - Disabled",     value = 1 }
    }, 2)

    CreateLabel(left, "QuestLevel", 14, startY - ROW_H * 2, LABEL_W)
    CreateEditBox(left, "questLevel", INPUT_X, startY - ROW_H * 2 - 2, INPUT_W, 22, false):SetText("1")

    CreateLabel(left, "MinLevel", 14, startY - ROW_H * 3, LABEL_W)
    CreateEditBox(left, "minLevel", INPUT_X, startY - ROW_H * 3 - 2, INPUT_W, 22, true):SetText("1")

    CreateLabel(left, "QuestSortID", 14, startY - ROW_H * 4, LABEL_W)
    CreateEditBox(left, "questSortId", INPUT_X, startY - ROW_H * 4 - 2, INPUT_W, 22, false):SetText("0")

    CreateLabel(left, "QuestInfoID", 14, startY - ROW_H * 5, LABEL_W)
    CreateDropDown(left, "questInfoId", INPUT_X + 15, startY - ROW_H * 5 - 6, INPUT_W - 30, {
        { text = "0 - None",        value = 0  },
        { text = "1 - Group",       value = 1  },
        { text = "41 - PvP",        value = 41 },
        { text = "62 - Raid",       value = 62 },
        { text = "81 - Dungeon",    value = 81 },
        { text = "82 - Event",      value = 82 },
        { text = "83 - Legendary",  value = 83 },
        { text = "84 - Escort",     value = 84 },
        { text = "85 - Heroic",     value = 85 }
    }, 0)

    CreateLabel(left, "SuggestedGroup", 14, startY - ROW_H * 6, LABEL_W)
    CreateEditBox(left, "suggestedGroupNum", INPUT_X, startY - ROW_H * 6 - 2, INPUT_W, 22, true):SetText("0")

    CreateLabel(left, "AllowableRaces", 14, startY - ROW_H * 7, LABEL_W)
    CreateEditBox(left, "allowableRaces", INPUT_X, startY - ROW_H * 7 - 2, INPUT_W, 22, false):SetText("0")

    CreateLabel(mid, "Flags", 14, startY, 50)
    local flagsBox = CreateEditBox(mid, "flags", 65, startY - 2, 100, 22, true)
    flagsBox:SetText("8")
    flagsBox:SetScript("OnTextChanged", function(self)
        ApplyChecks(tonumber(self:GetText()) or 0, QuestCreator_Flags, flagChecks)
        if QuestCreator.UpdatePreview then QuestCreator.UpdatePreview() end
    end)

    local checkStartY = startY - 34
    local col1X = 12
    local col2X = 185
    local checkGap = 26

    for i, def in ipairs(QuestCreator_Flags) do
        local colX = (i <= 7) and col1X or col2X
        local row = (i <= 7) and (i - 1) or (i - 8)
        local yPos = checkStartY - (row * checkGap)
        local check = CreateCheck(mid, def.label, colX, yPos, false)
        check:SetScript("OnClick", RefreshFlagsBox)
        flagChecks[def.key] = check
    end

    CreateLabel(right, "SpecialFlags", 14, startY, 70)
    local specialBox = CreateEditBox(right, "specialFlags", 90, startY - 2, 100, 22, true)
    specialBox:SetText("0")
    specialBox:SetScript("OnTextChanged", function(self)
        ApplyChecks(tonumber(self:GetText()) or 0, QuestCreator_SpecialFlags, specialFlagChecks)
        if QuestCreator.UpdatePreview then QuestCreator.UpdatePreview() end
    end)

    local specStartY = startY - 34
    local specGap = 26

    for i, def in ipairs(QuestCreator_SpecialFlags) do
        local check = CreateCheck(right, def.label, 12, specStartY - ((i - 1) * specGap), false)
        check:SetScript("OnClick", RefreshSpecialFlagsBox)
        specialFlagChecks[def.key] = check
    end
end

local function CreateTextsPage(parent)
    local p = CreatePage(parent, "texts")
    local TXT_LEFT_W = 520
    local TXT_RIGHT_W = 530
    local TXT_GAP = 16
    local TXT_TOTAL = TXT_LEFT_W + TXT_GAP + TXT_RIGHT_W
    local TXT_X = math.floor((1150 - TXT_TOTAL) / 2)
    local left  = CreateCard(p, nil,  TXT_X, -18, TXT_LEFT_W, 500, "Texts - Main")
    local right = CreateCard(p, nil,  TXT_X + TXT_LEFT_W + TXT_GAP, -18, TXT_RIGHT_W, 500, "Texts - Completion / Reward")
    CreateLabel(left, "Insertar:", 30, -68, 80)
    local function AddTokenButton(text, token, x)
        local btn = CreateButton(left, text, x, -70, 48, 24)
        btn:SetScript("OnClick", function()
            if not activeTextBox then
                Print("Haz click primero dentro de un campo de texto.")
                return
            end
            local oldText = activeTextBox:GetText() or ""
            local cursor  = activeTextBox:GetCursorPosition() or string.len(oldText)
            local before  = string.sub(oldText, 1, cursor)
            local after   = string.sub(oldText, cursor + 1)
            activeTextBox:SetText(before .. token .. after)
            activeTextBox:SetCursorPosition(cursor + string.len(token))
            activeTextBox:SetFocus()
        end)
        return btn
    end
    AddTokenButton("$N", "$N",  120)
    AddTokenButton("$C", "$C",  174)
    AddTokenButton("$R", "$R",  228)
    AddTokenButton("$B", "$B",  282)
    local gBtn = CreateButton(left, "$G", 336, -70, 48, 24)
    gBtn:SetScript("OnClick", function()
        if not activeTextBox then return end
        local token = "$Ghéroe:heroína;"
        local oldText = activeTextBox:GetText() or ""
        local cursor  = activeTextBox:GetCursorPosition() or string.len(oldText)
        activeTextBox:SetText(string.sub(oldText,1,cursor)..token..string.sub(oldText,cursor+1))
        activeTextBox:SetCursorPosition(cursor + string.len(token))
        activeTextBox:SetFocus()
    end)
    CreateLabel(left, "Title / LogTitle", 30, -108, 200)
    local titleBox = CreateEditBox(left, "title", 30, -130, 460, 28, false)
    titleBox:SetFontObject(GameFontNormalLarge)
    CreateLabel(left, "LogDescription", 30, -175, 200)
    CreateMultiLineBox(left, "logDescription", 30, -200, 460, 80)
    CreateLabel(left, "QuestDescription", 30, -295, 200)
    CreateMultiLineBox(left, "questDescription", 30, -320, 460, 160)
    CreateLabel(right, "AreaDescription", 30, -68, 200)
    CreateEditBox(right, "areaDescription", 30, -92, 470, 28, false)
    CreateLabel(right, "QuestCompletionLog", 30, -138, 200)
    CreateMultiLineBox(right, "completionLog", 30, -162, 470, 80)
    CreateLabel(right, "CompletionText / quest_request_items", 30, -258, 280)
    CreateMultiLineBox(right, "completionText", 30, -282, 470, 100)
    CreateLabel(right, "RewardText / quest_offer_reward", 30, -398, 280)
    CreateMultiLineBox(right, "rewardText", 30, -422, 470, 90)
end

local function CreateObjectivesPage(parent)
    local p = CreatePage(parent, "objectives")

    local CARD_W = 340
    local CARD_H = 480
    local GAP = 16
    local OBJ_TOTAL = CARD_W + GAP + CARD_W + GAP + CARD_W
    local OBJ_X = math.floor((1150 - OBJ_TOTAL) / 2)

    local left  = CreateCard(p, nil,  OBJ_X, -18, CARD_W, CARD_H, "Objectives - Kills / NPC / GO")
    local mid   = CreateCard(p, nil,  OBJ_X + CARD_W + GAP, -18, CARD_W, CARD_H, "Required Items / Drops")
    local right = CreateCard(p, nil,  OBJ_X + CARD_W + GAP + CARD_W + GAP, -18, CARD_W, CARD_H, "Objective Texts")

    -- ====== LEFT COLUMN ======
    CreateNumberField(left, "RequiredPlayerKills", "requiredPlayerKills", 20, -52, 140, 160)
    CreateMutedLabel(left, "Usado para quests PvP tipo:", 20, -88, 300)
    CreateMutedLabel(left, "Mata a X jugadores enemigos.", 20, -106, 300)
    CreateDivider(left, 14, -128, 310)

    -- Required NPC / GO header
    local npcHeader = left:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    npcHeader:SetPoint("TOP", left, "TOP", 0, -148)
    npcHeader:SetText("Required NPC / GO")
    npcHeader:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    CreateLabel(left, "Entry", 90, -178, 80)
    CreateLabel(left, "Count", 210, -178, 60)

    local npcRowStartY = -200
    local npcRowGap = 32
    for i = 1, 4 do
        local rowY = npcRowStartY - (i - 1) * npcRowGap
        -- Número
        local numLbl = left:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        numLbl:SetPoint("TOPLEFT", left, "TOPLEFT", 20, rowY + 4)
        numLbl:SetText(tostring(i))
        numLbl:SetTextColor(MUTED_R, MUTED_G, MUTED_B)
        -- Entry
        local entryBox = CreateEditBox(left, "requiredNpcOrGo" .. i, 40, rowY, 120, 24, false)
        entryBox:SetText("0")
        -- Count
        local countBox = CreateEditBox(left, "requiredNpcOrGoCount" .. i, 180, rowY, 80, 24, false)
        countBox:SetText("0")
        -- Botón ?
        local btn = CreateButton(left, "?", 275, rowY - 1, 30, 26)
        local nt = btn:GetNormalTexture()
        if nt then nt:SetVertexColor(0.7, 0.15, 0.15) end
        btn:SetScript("OnClick", function()
            local entry = tonumber(entryBox:GetText()) or 0
            if entry ~= 0 then ShowCreatureModelPopup(entry)
            else Print("Fila " .. i .. " no tiene entry.") end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Ver modelo 3D del NPC / GO", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        requiredNpcRows[i] = { entry = entryBox, count = countBox }
    end

    CreateDivider(left, 14, -340, 310)
    CreateMutedLabel(left, "NPC positivo - GO negativo", 20, -360, 300)
    CreateMutedLabel(left, "Ejemplo: NPC 12345 / GO -54321", 20, -378, 300)

    -- ====== MID COLUMN ======
    -- Required Items header
    local riHeader = mid:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    riHeader:SetPoint("TOPLEFT", mid, "TOPLEFT", 20, -52)
    riHeader:SetText("Required Items")
    riHeader:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    CreateLabel(mid, "Entry", 90, -78, 80)
    CreateLabel(mid, "Count", 230, -78, 60)

    local riY = -100
    local rowGap = 28
    for i = 1, 6 do
        local numLbl = mid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        numLbl:SetPoint("TOPLEFT", mid, "TOPLEFT", 20, riY + 4)
        numLbl:SetText(tostring(i))
        numLbl:SetTextColor(MUTED_R, MUTED_G, MUTED_B)
        local eBox = CreateEditBox(mid, "requiredItemId" .. i,    40,  riY, 130, 24, false)
        local cBox = CreateEditBox(mid, "requiredItemCount" .. i, 200, riY, 120, 24, false)
        eBox:SetText("0"); cBox:SetText("0")
        requiredItemRows[i] = { entry = eBox, count = cBox }
        riY = riY - rowGap
    end

    CreateDivider(mid, 14, -278, 310)

    -- Item Drops header
    local idHeader = mid:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    idHeader:SetPoint("TOPLEFT", mid, "TOPLEFT", 20, -296)
    idHeader:SetText("Item Drops")
    idHeader:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    CreateLabel(mid, "Entry", 90, -322, 80)
    CreateLabel(mid, "Count", 230, -322, 60)

    local idY = -344
    for i = 1, 4 do
        local numLbl = mid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        numLbl:SetPoint("TOPLEFT", mid, "TOPLEFT", 20, idY + 4)
        numLbl:SetText(tostring(i))
        numLbl:SetTextColor(MUTED_R, MUTED_G, MUTED_B)
        local eBox = CreateEditBox(mid, "itemDrop" .. i,         40,  idY, 130, 24, false)
        local cBox = CreateEditBox(mid, "itemDropQuantity" .. i, 200, idY, 120, 24, false)
        eBox:SetText("0"); cBox:SetText("0")
        itemDropRows[i] = { entry = eBox, count = cBox }
        idY = idY - rowGap
    end

    CreateMutedLabel(mid, "Entry = ID del item    |    Count = cantidad requerida", 20, -462, 300)

    -- ====== RIGHT COLUMN ======
    local rtY = -52
    for i = 1, 4 do
        CreateLabel(right, "ObjectiveText" .. i, 20, rtY, 120)
        CreateEditBox(right, "objectiveText" .. i, 20, rtY - 22, 300, 26, false)
        rtY = rtY - 58
    end

    CreateDivider(right, 14, -290, 310)

    -- Notas header
    local notasHeader = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    notasHeader:SetPoint("TOPLEFT", right, "TOPLEFT", 20, -310)
    notasHeader:SetText("Notas")
    notasHeader:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    CreateMutedLabel(right, "RequiredPlayerKills va en quest_template.", 20, -340, 300)
    CreateMutedLabel(right, "RequiredNpcOrGo puede usar NPC positivo", 20, -362, 300)
    CreateMutedLabel(right, "o GO negativo.", 20, -380, 300)
    CreateMutedLabel(right, "RequiredItemId necesita RequiredItemCount.", 20, -402, 300)
end

local function CreateRewardsPage(parent)
    local p = CreatePage(parent, "rewards")

    local CARD_W = 350
    local CARD_H = 500
    local GAP = 16
    local RWD_TOTAL = CARD_W + GAP + CARD_W + GAP + CARD_W
    local RWD_X = math.floor((1150 - RWD_TOTAL) / 2)

    local left  = CreateCard(p, nil,  RWD_X, -18, CARD_W, CARD_H, "Money / XP / Honor", "Interface\\Icons\\INV_Misc_Coin_01")
    local mid   = CreateCard(p, nil,  RWD_X + CARD_W + GAP, -18, CARD_W, CARD_H, "Spells / Title", "Interface\\Icons\\Spell_Holy_DivineIllumination")
    local right = CreateCard(p, nil,  RWD_X + CARD_W + GAP + CARD_W + GAP, -18, CARD_W, CARD_H, "Reward Items", "Interface\\Icons\\INV_Misc_Gift_01")

    -- LEFT: Money / XP / Honor
    local leftLabelW = 140
    local leftBoxW = 160
    local leftStartY = -52
    local leftRowGap = 46

    CreateNumberField(left, "RewardXPDifficulty",    "rewardXpDifficulty",    20, leftStartY,                    leftLabelW, leftBoxW)
    CreatePlainField(left,  "RewardMoney",           "rewardMoney",           20, leftStartY - leftRowGap,       leftLabelW, leftBoxW, false)
    CreatePlainField(left,  "RewardMoneyDifficulty", "rewardMoneyDifficulty", 20, leftStartY - leftRowGap * 2,   leftLabelW, leftBoxW, false)
    CreateNumberField(left, "RewardHonor",           "rewardHonor",           20, leftStartY - leftRowGap * 3,   leftLabelW, leftBoxW)
    CreateNumberField(left, "RewardKillHonor",       "rewardKillHonor",       20, leftStartY - leftRowGap * 4,   leftLabelW, leftBoxW)
    CreateNumberField(left, "RewardArenaPoints",     "rewardArenaPoints",     20, leftStartY - leftRowGap * 5,   leftLabelW, leftBoxW)

    -- MID: Spells / Title
    local midLabelW = 140
    local midBoxW = 160
    local midStartY = -52
    local midRowGap = 46

    CreateNumberField(mid, "RewardDisplaySpell", "rewardDisplaySpell", 20, midStartY,                  midLabelW, midBoxW)
    CreateNumberField(mid, "RewardSpell",        "rewardSpell",        20, midStartY - midRowGap,      midLabelW, midBoxW)
    CreateNumberField(mid, "StartItem",          "startItem",          20, midStartY - midRowGap * 2,  midLabelW, midBoxW)
    CreateNumberField(mid, "RewardTitle",        "rewardTitle",        20, midStartY - midRowGap * 3,  midLabelW, midBoxW)
    CreateNumberField(mid, "RewardTalents",      "rewardTalents",      20, midStartY - midRowGap * 4,  midLabelW, midBoxW)

    -- RIGHT: Reward Items
    local rightStartY = -48

    CreateLabel(right, "Entry", 75, rightStartY, 60)
    CreateLabel(right, "Count", 240, rightStartY, 60)

    local riY = rightStartY - 20
    local riGap = 30
    for i = 1, 4 do
        local numLbl = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        numLbl:SetPoint("TOPLEFT", right, "TOPLEFT", 22, riY + 2)
        numLbl:SetText(tostring(i))
        numLbl:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

        local eBox = CreateEditBox(right, "rewardItem" .. i,   45,  riY, 140, 20, false)
        eBox:SetText("0")

        local cBox = CreateEditBox(right, "rewardAmount" .. i, 210, riY, 120, 20, false)
        cBox:SetText("0")

        rewardItemRows[i] = { entry = eBox, count = cBox }
        riY = riY - riGap
    end

    local dividerY = riY + 4
    local crDivider = right:CreateTexture(nil, "ARTWORK")
    crDivider:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    crDivider:SetPoint("TOPLEFT", right, "TOPLEFT", 14, dividerY)
    crDivider:SetPoint("TOPRIGHT", right, "TOPRIGHT", -14, dividerY)
    crDivider:SetHeight(6)
    crDivider:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.7)

    local crHeader = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    crHeader:SetPoint("TOP", right, "TOP", 0, dividerY - 16)
    crHeader:SetText("Choice Rewards")
    crHeader:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    CreateLabel(right, "Entry", 75, dividerY - 38, 60)
    CreateLabel(right, "Count", 240, dividerY - 38, 60)

    local crY = dividerY - 56
    local crGap = 30
    for i = 1, 6 do
        local numLbl = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        numLbl:SetPoint("TOPLEFT", right, "TOPLEFT", 22, crY + 2)
        numLbl:SetText(tostring(i))
        numLbl:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

        local eBox = CreateEditBox(right, "rewardChoiceItemId" .. i,       45,  crY, 140, 20, false)
        eBox:SetText("0")

        local cBox = CreateEditBox(right, "rewardChoiceItemQuantity" .. i, 210, crY, 120, 20, false)
        cBox:SetText("0")

        rewardChoiceRows[i] = { entry = eBox, count = cBox }
        crY = crY - crGap
    end
end
local function CreateReputationPage(parent)
    local p = CreatePage(parent, "reputation")

    local REP_W = 530
    local REP_GAP = 16
    local REP_TOTAL = REP_W + REP_GAP + REP_W
    local REP_X = math.floor((1150 - REP_TOTAL) / 2)
    local left  = CreateCard(p, nil,  REP_X, -18, REP_W, 500, "Required Reputation", "Interface\\Icons\\INV_Jewelry_Talisman_08")
    local right = CreateCard(p, nil,  REP_X + REP_W + REP_GAP, -18, REP_W, 500, "Reward Reputation", "Interface\\Icons\\INV_Jewelry_Talisman_07")

    -- LEFT: Required Reputation
    CreateLabel(left, "RequiredFactionId",    90, -58, 140)
    CreateLabel(left, "RequiredFactionValue", 310, -58, 140)

    local reqY = -88
    local reqGap = 60
    for i = 1, 4 do
        local starIcon = left:CreateTexture(nil, "OVERLAY")
        starIcon:SetSize(16, 16)
        starIcon:SetPoint("TOPLEFT", left, "TOPLEFT", 32, reqY + 4)
        starIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        starIcon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B)

        local fBox = CreateEditBox(left, "requiredFactionId" .. i,    90,  reqY, 180, 26, true)
        fBox:SetText("0")

        local vBox = CreateEditBox(left, "requiredFactionValue" .. i, 310, reqY, 180, 26, false)
        vBox:SetText("0")

        reqY = reqY - reqGap
    end

    -- RIGHT: Reward Reputation
    CreateLabel(right, "Slot",     55, -58, 40)
    CreateLabel(right, "Faction",  170, -58, 120)
    CreateLabel(right, "Value",    350, -58, 80)
    CreateLabel(right, "Override", 450, -58, 80)

    local repY = -90
    local repGap = 60
    for i = 1, 5 do
        local badge = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        badge:SetPoint("TOPLEFT", right, "TOPLEFT", 42, repY + 4)
        badge:SetText(tostring(i))
        badge:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

        local fBox = CreateEditBox(right, "rewardFactionId" .. i,       90,  repY, 220, 26, true)
        fBox:SetText("0")

        local vBox = CreateEditBox(right, "rewardFactionValue" .. i,    340, repY, 90, 26, false)
        vBox:SetText("0")

        local oBox = CreateEditBox(right, "rewardFactionOverride" .. i, 450, repY, 70, 26, false)
        oBox:SetText("0")

        rewardFactionRows[i] = { faction = fBox, value = vBox, override = oBox }
        repY = repY - repGap
    end
end
local function CreateChainPage(parent)
    local p = CreatePage(parent, "chain")
    local CHN_L = 500
    local CHN_R = 560
    local CHN_GAP = 16
    local CHN_TOTAL = CHN_L + CHN_GAP + CHN_R
    local CHN_X = math.floor((1150 - CHN_TOTAL) / 2)
    local left  = CreateCard(p, nil,  CHN_X, -18, CHN_L, 500, "Quest Chain")
    local right = CreateCard(p, nil,  CHN_X + CHN_L + CHN_GAP, -18, CHN_R, 500, "Notas de cadena")
    CreatePlainField(left, "PrevQuestID",     "prevQuestId",     20, -72,  160, 300, false)
    CreatePlainField(left, "NextQuestID",     "nextQuestId",     20, -120, 160, 300, false)
    CreatePlainField(left, "RewardNextQuest", "rewardNextQuest", 20, -168, 160, 300, false)
    CreatePlainField(left, "ExclusiveGroup",  "exclusiveGroup",  20, -216, 160, 300, false)
    CreateMutedLabel(right, "RewardNextQuest abre automáticamente la siguiente misión.", 20, -72,  520)
    CreateMutedLabel(right, "PrevQuestID y NextQuestID viven en quest_template_addon.",  20, -110, 520)
    CreateMutedLabel(right, "ExclusiveGroup sirve para grupos exclusivos de quests.",    20, -148, 520)
end

local function CreateStarterPage(parent)
    local p = CreatePage(parent, "starter")

    local STR_W = 530
    local STR_GAP = 16
    local STR_TOTAL = STR_W + STR_GAP + STR_W
    local STR_X = math.floor((1150 - STR_TOTAL) / 2)
    local left  = CreateCard(p, nil,  STR_X, -18, STR_W, 500, "Starter", "Interface\\Icons\\INV_Misc_Map_01")
    local right = CreateCard(p, nil,  STR_X + STR_W + STR_GAP, -18, STR_W, 500, "Ender", "Interface\\Icons\\INV_Misc_Map_02")

    local function AddCornerStar(card)
        local star = card:CreateTexture(nil, "OVERLAY")
        star:SetSize(12, 12)
        star:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
        star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        star:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 0.6)

        local star2 = card:CreateTexture(nil, "OVERLAY")
        star2:SetSize(12, 12)
        star2:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)
        star2:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        star2:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 0.6)
    end
    AddCornerStar(left)
    AddCornerStar(right)

    -- LEFT: Starter
    CreateLabel(left, "StarterType", 80, -68, 120)
    CreateDropDown(left, "starterType", 220, -74, 200, {
        { text = "creature",   value = "creature"   },
        { text = "gameobject", value = "gameobject" },
        { text = "none",       value = "none"       }
    }, "creature")

    local div1 = left:CreateTexture(nil, "ARTWORK")
    div1:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    div1:SetPoint("TOPLEFT", left, "TOPLEFT", 40, -110)
    div1:SetPoint("TOPRIGHT", left, "TOPRIGHT", -40, -110)
    div1:SetHeight(6)
    div1:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.5)

    CreateLabel(left, "StarterEntry", 80, -130, 120)
    local seBox = CreateEditBox(left, "starterEntry", 220, -132, 200, 26, true)
    seBox:SetText("0")

    local div2 = left:CreateTexture(nil, "ARTWORK")
    div2:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    div2:SetPoint("TOPLEFT", left, "TOPLEFT", 40, -172)
    div2:SetPoint("TOPRIGHT", left, "TOPRIGHT", -40, -172)
    div2:SetHeight(6)
    div2:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.5)

    -- RIGHT: Ender
    CreateLabel(right, "EnderType", 80, -68, 120)
    CreateDropDown(right, "enderType", 220, -74, 200, {
        { text = "creature",   value = "creature"   },
        { text = "gameobject", value = "gameobject" },
        { text = "none",       value = "none"       }
    }, "creature")

    local div3 = right:CreateTexture(nil, "ARTWORK")
    div3:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    div3:SetPoint("TOPLEFT", right, "TOPLEFT", 40, -110)
    div3:SetPoint("TOPRIGHT", right, "TOPRIGHT", -40, -110)
    div3:SetHeight(6)
    div3:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.5)

    CreateLabel(right, "EnderEntry", 80, -130, 120)
    local eeBox = CreateEditBox(right, "enderEntry", 220, -132, 200, 26, true)
    eeBox:SetText("0")

    local div4 = right:CreateTexture(nil, "ARTWORK")
    div4:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    div4:SetPoint("TOPLEFT", right, "TOPLEFT", 40, -172)
    div4:SetPoint("TOPRIGHT", right, "TOPRIGHT", -40, -172)
    div4:SetHeight(6)
    div4:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.5)
end
local function CreateAdvancedPage(parent)
    local p = CreatePage(parent, "advanced")
    local ADV_W = 350
    local ADV_GAP = 16
    local ADV_TOTAL = ADV_W + ADV_GAP + ADV_W + ADV_GAP + ADV_W
    local ADV_X = math.floor((1150 - ADV_TOTAL) / 2)
    local left  = CreateCard(p, nil,  ADV_X, -18, ADV_W, 500, "Addon / Requirements")
    local mid   = CreateCard(p, nil,  ADV_X + ADV_W + ADV_GAP, -18, ADV_W, 500, "Request / Offer Emotes")
    local right = CreateCard(p, nil,  ADV_X + ADV_W + ADV_GAP + ADV_W + ADV_GAP, -18, ADV_W, 500, "POI / Misc")
    CreatePlainField(left,  "MaxLevel",              "maxLevel",              20, -72,  160, 160, false)
    CreatePlainField(left,  "AllowableClasses",      "allowableClasses",      20, -118, 160, 160, false)
    CreateNumberField(left, "SourceSpellID",         "sourceSpellId",         20, -164, 160, 160)
    CreateNumberField(left, "RequiredSkillID",       "requiredSkillId",       20, -210, 160, 160)
    CreateNumberField(left, "RequiredSkillPoints",   "requiredSkillPoints",   20, -256, 160, 160)
    CreateNumberField(left, "ProvidedItemCount",     "providedItemCount",     20, -302, 160, 160)
    CreateDivider(left, 10, -340, 320)
    CreateNumberField(left, "RequiredMinRepFaction", "requiredMinRepFaction", 20, -360, 160, 160)
    CreatePlainField(left,  "RequiredMinRepValue",   "requiredMinRepValue",   20, -406, 160, 160, false)
    CreateNumberField(left, "RequiredMaxRepFaction", "requiredMaxRepFaction", 20, -452, 160, 160)
    CreateNumberField(mid, "EmoteOnComplete",   "emoteOnComplete",   20, -72,  160, 160)
    CreateNumberField(mid, "EmoteOnIncomplete", "emoteOnIncomplete", 20, -118, 160, 160)
    CreateDivider(mid, 10, -156, 320)
    CreateNumberField(mid, "RewardEmote1",  "rewardEmote1",       20, -174, 160, 160)
    CreateNumberField(mid, "RewardEmote2",  "rewardEmote2",       20, -220, 160, 160)
    CreateNumberField(mid, "RewardEmote3",  "rewardEmote3",       20, -266, 160, 160)
    CreateNumberField(mid, "RewardEmote4",  "rewardEmote4",       20, -312, 160, 160)
    CreateDivider(mid, 10, -350, 320)
    CreateNumberField(mid, "RewardDelay1",  "rewardEmoteDelay1",  20, -368, 160, 160)
    CreateNumberField(mid, "RewardDelay2",  "rewardEmoteDelay2",  20, -414, 160, 160)
    CreateNumberField(right, "TimeAllowed",   "timeAllowed",   20, -72,  160, 160)
    CreatePlainField(right,  "POIContinent",  "poiContinent",  20, -118, 160, 160, false)
    CreatePlainField(right,  "POIx",         "poiX",          20, -164, 160, 160, false)
    CreatePlainField(right,  "POIy",         "poiY",          20, -210, 160, 160, false)
    CreateNumberField(right, "POIPriority",   "poiPriority",   20, -256, 160, 160)
    CreatePlainField(right,  "Unknown0",      "unknown0",      20, -302, 160, 160, false)
    CreateDivider(right, 10, -340, 320)
    CreateNumberField(right, "VerifiedBuild", "verifiedBuild",       20, -360, 160, 160)
    CreateNumberField(right, "RequestBuild",  "requestVerifiedBuild", 20, -406, 160, 160)
end

local function SetBrowserStatus(msg)
    if browserStatus then
        browserStatus:SetText(tostring(msg or ""))
    end
end

local function SetBrowserPageRange(firstId, lastId)
    if not browserPageText then return end
    if firstId and lastId then
        browserPageText:SetText(string.format(L.PAGER_IDS_RANGE, tostring(firstId), tostring(lastId)))
    else
        browserPageText:SetText(L.PAGER_NO_DATA)
    end
end

local function RenderQuestRows(quests, direction)
    for i = 1, #questRows do
        questRows[i]:Hide()
    end
    if not quests or #quests == 0 then
        SetBrowserStatus(L.STATUS_NO_QUESTS)
        SetBrowserPageRange(nil, nil)
        Print(L.STATUS_NO_QUESTS)
        return
    end
    local visibleCount = math.min(#quests, #questRows)
    SetBrowserStatus(string.format(L.STATUS_SHOWING, tostring(visibleCount), tostring(#quests), tostring(direction or "n/a")))
    local firstShownId = tonumber(quests[1].id) or 0
    local lastShownId  = tonumber(quests[visibleCount].id) or firstShownId
    QuestCreator_StreamList.firstShownId = firstShownId
    QuestCreator_StreamList.lastShownId  = lastShownId
    SetBrowserPageRange(firstShownId, lastShownId)
    for i = 1, visibleCount do
        local quest = quests[i]
        local row = questRows[i]
        if row then
            local questId = tonumber(quest.id) or 0
            local title = tostring(quest.title or ("Quest " .. tostring(questId)))
            local level = tonumber(quest.level) or 0
            local minLevel = tonumber(quest.minLevel) or 0
            local rewardNextQuest = tonumber(quest.rewardNextQuest) or 0
            
            -- Formato con prefijos como en la imagen
            row.idText:SetText(tostring(questId))
            row.titleText:SetText(title)
            row.lvlText:SetText(L.ROW_LVL_PREFIX .. " " .. tostring(level))
            row.minText:SetText(L.ROW_MIN_PREFIX .. " " .. tostring(minLevel))
            row.maxText:SetText("-")
            row.nextText:SetText(L.ROW_NEXT_PREFIX .. " " .. tostring(rewardNextQuest))
            
            row.questId = questId
            row.loadButton:SetScript("OnClick", function()
                AIO.Handle("QuestCreator", "LoadQuest", questId)
            end)
            row.copyButton:SetScript("OnClick", function()
                AIO.Handle("QuestCreator", "CopyQuest", questId, GetNumber("browserCopyId", 0))
            end)
            row.deleteButton:SetScript("OnClick", function()
                AIO.Handle("QuestCreator", "PreviewDeleteQuest", questId)
            end)
            row.chainDeleteButton:SetScript("OnClick", function()
                currentDeleteQuestId = questId
                deleteFrame.confirmDeleteChain = true
                deleteFrame.title:SetText("Delete Chain")
                deleteFrame.info:SetText("Vas a borrar una cadena desde quest " .. tostring(questId) .. "\n\nSe seguirá RewardNextQuest hacia adelante." .. "\n\nPara confirmar escribe:" .. "\nDELETE CHAIN " .. tostring(questId))
                deleteFrame.confirm:SetText("")
                deleteFrame:Show()
            end)
            row:Show()
        end
    end
    if direction == "forward" then
        currentListId = (tonumber(quests[#quests].id) or currentListId) + 1
        SetBox("browserStartId", currentListId)
    elseif direction == "backward" then
        currentListId = (tonumber(quests[#quests].id) or currentListId) - 1
        if currentListId < 1 then currentListId = 1 end
        SetBox("browserStartId", currentListId)
    end
end

local function CreateBrowserPage(parent)
    local p = CreatePage(parent, "browser")

    -- Header "Quest List" (icon + uppercase title)
    local headerIcon = p:CreateTexture(nil, "OVERLAY")
    headerIcon:SetSize(20, 20)
    headerIcon:SetPoint("TOPLEFT", p, "TOPLEFT", 22, -22)
    headerIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    headerIcon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B)

    local headerText = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerText:SetPoint("TOPLEFT", p, "TOPLEFT", 50, -24)
    headerText:SetText(L.QUEST_LIST_TITLE)
    headerText:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    local headerDiv = p:CreateTexture(nil, "ARTWORK")
    headerDiv:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    headerDiv:SetPoint("TOPLEFT", p, "TOPLEFT", 18, -48)
    headerDiv:SetPoint("TOPRIGHT", p, "TOPRIGHT", -18, -48)
    headerDiv:SetHeight(6)
    headerDiv:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)

    -- Filter bar (darker, more elegant)
    local filterBar = CreateFrame("Frame", nil, p)
    filterBar:SetPoint("TOPLEFT", p, "TOPLEFT", 18, -56)
    filterBar:SetPoint("TOPRIGHT", p, "TOPRIGHT", -18, -56)
    filterBar:SetHeight(46)
    filterBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    filterBar:SetBackdropColor(0.04, 0.03, 0.02, 0.95)
    filterBar:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.65)

    CreateLabel(filterBar, L.LBL_START_ID, 14, -16, 60)
    local startBox = CreateEditBox(filterBar, "browserStartId", 70, -16, 110, 22, true)
    startBox:SetText("1")

    local backward = CreateDarkButton(filterBar, L.BTN_BACK, 196, -16, 82, 22, false)
    backward:SetScript("OnClick", function()
        currentListId = tonumber(startBox:GetText()) or 1
        SetBrowserStatus(string.format(L.STATUS_REQ_PREV, tostring(currentListId)))
        AIO.Handle("QuestCreator", "ListQuestsBackward", currentListId)
    end)

    local forward = CreateDarkButton(filterBar, L.BTN_FORWARD, 286, -16, 90, 22, false)
    forward:SetScript("OnClick", function()
        currentListId = tonumber(startBox:GetText()) or 1
        SetBrowserStatus(string.format(L.STATUS_REQ_NEXT, tostring(currentListId)))
        AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
    end)

    CreateLabel(filterBar, L.BTN_SEARCH, 400, -16, 50)
    CreateEditBox(filterBar, "browserSearch", 452, -16, 220, 22, false)

    local searchButton = CreateDarkButton(filterBar, L.BTN_SEARCH, 684, -16, 78, 22, true)
    searchButton:SetScript("OnClick", function()
        SetBrowserStatus(L.BTN_SEARCH .. ": " .. GetText("browserSearch"))
        AIO.Handle("QuestCreator", "SearchQuests", GetText("browserSearch"))
    end)

    local reloadButton = CreateDarkButton(filterBar, L.BTN_RELOAD_LIST, 770, -16, 90, 22, true)
    reloadButton:SetScript("OnClick", function()
        currentListId = 1
        SetBox("browserStartId", currentListId)
        SetBrowserStatus(L.STATUS_REQ_FIRST)
        AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
    end)

    CreateLabel(filterBar, L.LBL_NEW_COPY_ID, 880, -16, 70)
    local copyId = CreateEditBox(filterBar, "browserCopyId", 950, -16, 90, 22, true)
    copyId:SetText("0")

    -- Status text
    browserStatus = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    browserStatus:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -114)
    browserStatus:SetWidth(900)
    browserStatus:SetJustifyH("LEFT")
    browserStatus:SetTextColor(MUTED_R, MUTED_G, MUTED_B)
    browserStatus:SetText(L.BTN_RELOAD_LIST .. "...")

    -- Table frame
    local tableFrame = CreateFrame("Frame", nil, p)
    tableFrame:SetPoint("TOPLEFT", p, "TOPLEFT", 18, -126)
    tableFrame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -18, 40)
    tableFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    tableFrame:SetBackdropColor(0.03, 0.02, 0.015, 0.98)
    tableFrame:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.75)

    -- Header row background
    local headerBg = tableFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 6, -6)
    headerBg:SetPoint("TOPRIGHT", tableFrame, "TOPRIGHT", -6, -6)
    headerBg:SetHeight(26)
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerBg:SetVertexColor(0.10, 0.07, 0.04, 0.95)

    -- Column layout (uppercase headers, like target image)
    local COL_X_ID       = 28
    local COL_X_TITLE    = 90
    local COL_X_LVL      = 410
    local COL_X_MIN      = 480
    local COL_X_MAX      = 550
    local COL_X_NEXT     = 620
    local ACTION_BTN_W   = 75
    local ACTION_BTN_GAP = 4
    local ACTION_X_LOAD  = 720
    local ACTION_X_COPY  = ACTION_X_LOAD + ACTION_BTN_W + ACTION_BTN_GAP
    local ACTION_X_DEL   = ACTION_X_COPY + ACTION_BTN_W + ACTION_BTN_GAP
    local ACTION_X_CHAIN = ACTION_X_DEL  + ACTION_BTN_W + ACTION_BTN_GAP

    local function addHeader(text, x, w, justify)
        local h = tableFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", x, -12)
        h:SetWidth(w)
        h:SetJustifyH(justify or "CENTER")
        h:SetText(text)
        h:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
        return h
    end

    addHeader(L.COL_ID,          COL_X_ID,    60,  "LEFT")
    addHeader(L.COL_QUEST_TITLE, COL_X_TITLE, 310, "LEFT")
    addHeader(L.COL_LVL,         COL_X_LVL,   60,  "CENTER")
    addHeader(L.COL_MIN,         COL_X_MIN,   60,  "CENTER")
    addHeader(L.COL_MAX,         COL_X_MAX,   60,  "CENTER")
    addHeader(L.COL_NEXT_QUEST,  COL_X_NEXT,  90,  "LEFT")

    local tableDiv = tableFrame:CreateTexture(nil, "ARTWORK")
    tableDiv:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tableDiv:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 8, -34)
    tableDiv:SetPoint("TOPRIGHT", tableFrame, "TOPRIGHT", -8, -34)
    tableDiv:SetHeight(6)
    tableDiv:SetVertexColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 0.6)

    -- Quest rows
    local rowStartY = -42
    local rowHeight = 20

    for i = 1, 16 do
        local row = CreateFrame("Frame", nil, tableFrame)
        row:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 4, rowStartY - (i-1) * rowHeight)
        row:SetPoint("TOPRIGHT", tableFrame, "TOPRIGHT", -4, rowStartY - (i-1) * rowHeight)
        row:SetHeight(rowHeight)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        if i % 2 == 0 then
            row.bg:SetVertexColor(0.08, 0.05, 0.03, 0.45)
        else
            row.bg:SetVertexColor(0.04, 0.025, 0.015, 0.35)
        end

        -- Small red gem indicator (left side)
        row.gem = row:CreateTexture(nil, "OVERLAY")
        row.gem:SetSize(10, 10)
        row.gem:SetPoint("LEFT", row, "LEFT", 12, 0)
        row.gem:SetTexture("Interface\\COMMON\\Indicator-Red")
        row.gem:SetVertexColor(1, 0.25, 0.2, 1)

        row.gemGlow = row:CreateTexture(nil, "ARTWORK")
        row.gemGlow:SetSize(16, 16)
        row.gemGlow:SetPoint("CENTER", row.gem, "CENTER", 0, 0)
        row.gemGlow:SetTexture("Interface\\Cooldown\\star4")
        row.gemGlow:SetBlendMode("ADD")
        row.gemGlow:SetVertexColor(0.6, 0.05, 0.02, 0.55)

        row.idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.idText:SetPoint("LEFT", row, "LEFT", COL_X_ID - 4, 0)
        row.idText:SetWidth(60)
        row.idText:SetJustifyH("LEFT")
        row.idText:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)

        row.titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.titleText:SetPoint("LEFT", row, "LEFT", COL_X_TITLE - 4, 0)
        row.titleText:SetWidth(310)
        row.titleText:SetJustifyH("LEFT")
        row.titleText:SetTextColor(TEXT_VALUE_R, TEXT_VALUE_G, TEXT_VALUE_B)

        row.lvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.lvlText:SetPoint("LEFT", row, "LEFT", COL_X_LVL - 4, 0)
        row.lvlText:SetWidth(60)
        row.lvlText:SetJustifyH("CENTER")
        row.lvlText:SetTextColor(MUTED_R, MUTED_G, MUTED_B)

        row.minText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.minText:SetPoint("LEFT", row, "LEFT", COL_X_MIN - 4, 0)
        row.minText:SetWidth(60)
        row.minText:SetJustifyH("CENTER")
        row.minText:SetTextColor(MUTED_R, MUTED_G, MUTED_B)

        row.maxText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.maxText:SetPoint("LEFT", row, "LEFT", COL_X_MAX - 4, 0)
        row.maxText:SetWidth(60)
        row.maxText:SetJustifyH("CENTER")
        row.maxText:SetTextColor(MUTED_R, MUTED_G, MUTED_B)

        row.nextText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nextText:SetPoint("LEFT", row, "LEFT", COL_X_NEXT - 4, 0)
        row.nextText:SetWidth(90)
        row.nextText:SetJustifyH("LEFT")
        row.nextText:SetTextColor(MUTED_R, MUTED_G, MUTED_B)

        -- Action buttons (icon + text, dark with gold border)
        row.loadButton = CreateIconActionButton(row, L.BTN_LOAD, "Interface\\BUTTONS\\UI-RefreshButton", ACTION_BTN_W)
        row.loadButton:SetPoint("LEFT", row, "LEFT", ACTION_X_LOAD - 4, 0)

        row.copyButton = CreateIconActionButton(row, L.BTN_COPY, "Interface\\PaperDollInfoFrame\\UI-EquipmentManager-Toggle", ACTION_BTN_W)
        row.copyButton:SetPoint("LEFT", row, "LEFT", ACTION_X_COPY - 4, 0)

        row.deleteButton = CreateIconActionButton(row, L.BTN_DELETE, "Interface\\BUTTONS\\UI-MinusButton-Up", ACTION_BTN_W)
        row.deleteButton:SetPoint("LEFT", row, "LEFT", ACTION_X_DEL - 4, 0)

        row.chainDeleteButton = CreateIconActionButton(row, L.BTN_DEL_CHAIN, "Interface\\PetPaperDollFrame\\UI-PetSlot-Link", ACTION_BTN_W)
        row.chainDeleteButton:SetPoint("LEFT", row, "LEFT", ACTION_X_CHAIN - 4, 0)

        row:Hide()
        questRows[i] = row
    end

    -- Pagination (centered group of 4 styled buttons with page text in middle)
    local pagination = CreateFrame("Frame", nil, p)
    pagination:SetPoint("BOTTOM", p, "BOTTOM", 0, 6)
    pagination:SetWidth(360)
    pagination:SetHeight(26)

    local btnFirst = CreatePagerButton(pagination, "<<", 30)
    btnFirst:SetPoint("LEFT", pagination, "LEFT", 30, 0)
    btnFirst:SetScript("OnClick", function()
        currentListId = 1
        SetBox("browserStartId", currentListId)
        SetBrowserStatus(L.STATUS_REQ_FIRST)
        AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
    end)

    local btnPrev = CreatePagerButton(pagination, "<", 26)
    btnPrev:SetPoint("LEFT", btnFirst, "RIGHT", 6, 0)
    btnPrev:SetScript("OnClick", function()
        local firstShown = tonumber(QuestCreator_StreamList.firstShownId) or 0
        local target = firstShown - 1
        if target < 1 then target = 1 end
        currentListId = target
        SetBox("browserStartId", currentListId)
        SetBrowserStatus(string.format(L.STATUS_REQ_PREV, tostring(currentListId)))
        AIO.Handle("QuestCreator", "ListQuestsBackward", currentListId)
    end)

    browserPageText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    browserPageText:SetPoint("CENTER", pagination, "CENTER", 0, 0)
    browserPageText:SetWidth(160)
    browserPageText:SetJustifyH("CENTER")
    browserPageText:SetText(L.PAGER_NO_DATA)
    browserPageText:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    local btnNext = CreatePagerButton(pagination, ">", 26)
    btnNext:SetPoint("RIGHT", pagination, "RIGHT", -62, 0)
    btnNext:SetScript("OnClick", function()
        local lastShown = tonumber(QuestCreator_StreamList.lastShownId) or 0
        if lastShown <= 0 then
            lastShown = (tonumber(currentListId) or 1) - 1
        end
        currentListId = lastShown + 1
        if currentListId < 1 then currentListId = 1 end
        SetBox("browserStartId", currentListId)
        SetBrowserStatus(string.format(L.STATUS_REQ_NEXT, tostring(currentListId)))
        AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
    end)

    local btnLast = CreatePagerButton(pagination, ">>", 30)
    btnLast:SetPoint("LEFT", btnNext, "RIGHT", 6, 0)
    btnLast:SetScript("OnClick", function()
        currentListId = 999999
        SetBox("browserStartId", currentListId)
        SetBrowserStatus(L.STATUS_REQ_LAST)
        AIO.Handle("QuestCreator", "ListQuestsBackward", currentListId)
    end)
end

local function CollectObjectiveLines()
    local lines = {}
    for i = 1, 4 do
        local text = GetText("objectiveText" .. i)
        if text and text ~= "" then
            lines[#lines + 1] = TokenReplace(text)
        end
    end
    local pk = GetNumber("requiredPlayerKills", 0)
    if pk > 0 and #lines == 0 then
        lines[#lines + 1] = "Mata a " .. tostring(pk) .. " jugadores enemigos."
    end
    for i = 1, 4 do
        local entry = tonumber(requiredNpcRows[i] and requiredNpcRows[i].entry:GetText() or 0) or 0
        local count = tonumber(requiredNpcRows[i] and requiredNpcRows[i].count:GetText() or 0) or 0
        if entry ~= 0 and count > 0 then
            if entry > 0 then
                local info = creatureInfoCache[entry]
                if info and info.ready and info.name and info.name ~= "" then
                    lines[#lines + 1] = "Elimina " .. tostring(count) .. " " .. info.name .. " (ID " .. tostring(entry) .. ")."
                else
                    lines[#lines + 1] = "Elimina " .. tostring(count) .. " del NPC " .. tostring(entry) .. "."
                    if not info or not info.requested then
                        RequestCreatureInfoFromServer(entry)
                    end
                end
            else
                local goEntry = -entry
                local info = gameObjectInfoCache[goEntry]
                if info and info.ready and info.name and info.name ~= "" then
                    lines[#lines + 1] = "Interactúa con " .. tostring(count) .. " " .. info.name .. " (GO " .. tostring(goEntry) .. ")."
                else
                    lines[#lines + 1] = "Interactúa con " .. tostring(count) .. " del GO " .. tostring(goEntry) .. "."
                    if not info or not info.requested then
                        RequestGameObjectInfoFromServer(goEntry)
                    end
                end
            end
        end
    end
    for i = 1, 6 do
        local entry = tonumber(requiredItemRows[i] and requiredItemRows[i].entry:GetText() or 0) or 0
        local count = tonumber(requiredItemRows[i] and requiredItemRows[i].count:GetText() or 0) or 0
        if entry ~= 0 and count > 0 then
            _ = entry
        end
    end
    if #lines == 0 then
        lines[#lines + 1] = "Sin objetivos definidos."
    end
    return lines
end

local function BuildPreviewRewardBlock()
    local lines = {}
    local money = GetNumber("rewardMoney", 0)
    local g, s, c = MoneyToText(money)
    local xpPreview = math.max(GetNumber("rewardXpDifficulty", 0) * 690, 0)
    local honor = GetNumber("rewardHonor", 0)
    local killHonor = GetNumber("rewardKillHonor", 0)
    local arena = GetNumber("rewardArenaPoints", 0)
    local titleReward = GetNumber("rewardTitle", 0)
    local talents = GetNumber("rewardTalents", 0)
    local displaySpell = GetNumber("rewardDisplaySpell", 0)
    local rewardSpell = GetNumber("rewardSpell", 0)
    lines[#lines + 1] = "Recompensas"
    lines[#lines + 1] = "Recibirás: " .. tostring(g) .. " oro, " .. tostring(s) .. " plata, " .. tostring(c) .. " cobre"
    lines[#lines + 1] = "Experiencia: " .. tostring(xpPreview)
    if honor > 0 then lines[#lines + 1] = "Honor: " .. tostring(honor) end
    if killHonor > 0 then lines[#lines + 1] = "Kill Honor: " .. tostring(killHonor) end
    if arena > 0 then lines[#lines + 1] = "Arena Points: " .. tostring(arena) end
    if titleReward > 0 then lines[#lines + 1] = "Título: " .. tostring(titleReward) end
    if talents > 0 then lines[#lines + 1] = "Talentos: " .. tostring(talents) end
    if displaySpell > 0 then lines[#lines + 1] = "Display Spell: " .. tostring(displaySpell) end
    if rewardSpell > 0 then lines[#lines + 1] = "Reward Spell: " .. tostring(rewardSpell) end
    local repAdded = false
    for i = 1, 5 do
        local faction = GetNumber("rewardFactionId" .. i, 0)
        local value = GetNumber("rewardFactionValue" .. i, 0)
        if faction ~= 0 or value ~= 0 then
            if not repAdded then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "Reputación"
                repAdded = true
            end
            lines[#lines + 1] = "Facción " .. tostring(faction) .. ": +" .. tostring(value)
        end
    end
    return table.concat(lines, "\n")
end

local function BuildPreviewRewardItems()
    local items = {}
    for i = 1, 4 do
        local id = tonumber(rewardItemRows[i] and rewardItemRows[i].entry:GetText() or 0) or 0
        local count = tonumber(rewardItemRows[i] and rewardItemRows[i].count:GetText() or 0) or 0
        if id > 0 then
            items[#items + 1] = { id = id, count = math.max(count, 1), choice = false }
        end
    end
    for i = 1, 6 do
        local id = tonumber(rewardChoiceRows[i] and rewardChoiceRows[i].entry:GetText() or 0) or 0
        local count = tonumber(rewardChoiceRows[i] and rewardChoiceRows[i].count:GetText() or 0) or 0
        if id > 0 then
            items[#items + 1] = { id = id, count = math.max(count, 1), choice = true }
        end
    end
    return items
end

local function CreatePreviewPage(parent)
    local p = CreatePage(parent, "preview")
    preview.page = p
    local left = CreateCard(p, nil, 13, -18, 270, 480, L.CARD_QUEST_SUMMARY)
    local center = CreateCard(p, nil, 295, -18, 560, 480, "")
    local right = CreateCard(p, nil, 867, -18, 270, 480, L.CARD_PREVIEW_CONTROLS)
    preview.widgets.left = left
    preview.widgets.center = center
    preview.widgets.right = right
    CreateLabel(left, L.LBL_QUEST_ID, 14, -55, 80)
    local _, fsId = MakeReadOnlyPreviewBox(left, 100, -58, 140, 24)
    preview.widgets.summaryId = fsId
    CreateLabel(left, L.LBL_TITLE, 14, -95, 80)
    local _, fsTitle = MakeReadOnlyPreviewBox(left, 100, -98, 140, 24)
    preview.widgets.summaryTitle = fsTitle
    CreateLabel(left, L.LBL_QUEST_TYPE, 14, -135, 80)
    local _, fsQType = MakeReadOnlyPreviewBox(left, 100, -138, 140, 24)
    preview.widgets.summaryQuestType = fsQType
    CreateLabel(left, L.LBL_QUEST_LEVEL, 14, -175, 80)
    local _, fsQLvl = MakeReadOnlyPreviewBox(left, 100, -178, 140, 24)
    preview.widgets.summaryQuestLevel = fsQLvl
    CreateLabel(left, L.LBL_MIN_LEVEL, 14, -215, 80)
    local _, fsMin = MakeReadOnlyPreviewBox(left, 100, -218, 140, 24)
    preview.widgets.summaryMinLevel = fsMin
    CreateLabel(left, L.LBL_QUEST_INFO, 14, -255, 80)
    local _, fsInfo = MakeReadOnlyPreviewBox(left, 100, -258, 140, 60)
    preview.widgets.summaryInfo = fsInfo
    CreateLabel(left, L.LBL_FLAGS, 14, -330, 80)
    local _, fsFlags = MakeReadOnlyPreviewBox(left, 100, -333, 140, 24)
    preview.widgets.summaryFlags = fsFlags
    CreateLabel(left, L.LBL_SPECIAL_FLAGS, 14, -368, 80)
    local _, fsSFlags = MakeReadOnlyPreviewBox(left, 100, -371, 140, 24)
    preview.widgets.summarySpecialFlags = fsSFlags
    CreateDivider(left, 14, -403, 220)
    CreateTitle(left, L.TITLE_STARTER_ENDER, 14, -422, 220)
    CreateLabel(left, L.LBL_START_NPC, 14, -444, 80)
    preview.widgets.startNpcLabel = CreateMutedLabel(left, "", 100, -444, 140)
    CreateLabel(left, L.LBL_END_NPC, 14, -462, 80)
    preview.widgets.endNpcLabel = CreateMutedLabel(left, "", 100, -462, 140)
    local qf = CreatePanel(center, nil, 10, -10, 540, 420)
    qf:SetBackdropColor(0.015, 0.012, 0.01, 0.94)
    qf:SetBackdropBorderColor(0.85, 0.62, 0.28, 0.95)
    preview.widgets.questFrame = qf
    local portraitBg = CreateFrame("Frame", nil, qf)
    portraitBg:SetPoint("TOPLEFT", qf, "TOPLEFT", 12, -12)
    portraitBg:SetWidth(58)
    portraitBg:SetHeight(58)
    portraitBg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    portraitBg:SetBackdropColor(0, 0, 0, 0.95)
    portraitBg:SetBackdropBorderColor(0.95, 0.72, 0.25, 1)
    local portrait = portraitBg:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", portraitBg, "TOPLEFT", 4, -4)
    portrait:SetPoint("BOTTOMRIGHT", portraitBg, "BOTTOMRIGHT", -4, 4)
    portrait:SetTexture("Interface\\Icons\\Achievement_Leader_King_Varian_Wrynn")
    preview.widgets.portrait = portrait
    preview.widgets.portraitBg = portraitBg
    local header = CreateFrame("Frame", nil, qf)
    header:SetPoint("TOPLEFT", qf, "TOPLEFT", 82, -16)
    header:SetWidth(410)
    header:SetHeight(28)
    header:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    header:SetBackdropColor(0.015, 0.015, 0.015, 0.98)
    header:SetBackdropBorderColor(0.65, 0.52, 0.32, 0.9)
    local npcName = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npcName:SetPoint("CENTER", header, "CENTER", 0, 0)
    npcName:SetTextColor(1, 1, 1)
    preview.widgets.npcName = npcName
    local closeBtn = CreateFrame("Button", nil, qf, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", qf, "TOPRIGHT", -8, -12)
    closeBtn:SetScript("OnClick", function() end)
    closeBtn:Hide()
    preview.widgets.previewClose = closeBtn
    local parchment = CreateFrame("Frame", nil, qf)
    parchment:SetPoint("TOPLEFT", qf, "TOPLEFT", 22, -86)
    parchment:SetWidth(496)
    parchment:SetHeight(280)
    parchment:SetBackdrop({
        bgFile = "Interface\\QuestFrame\\QuestBG",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 256,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    parchment:SetBackdropColor(1, 0.86, 0.52, 1)
    parchment:SetBackdropBorderColor(0.35, 0.22, 0.08, 0.95)
    preview.widgets.parchment = parchment
    local parchmentOverlay = parchment:CreateTexture(nil, "BACKGROUND")
    parchmentOverlay:SetPoint("TOPLEFT", parchment, "TOPLEFT", 3, -3)
    parchmentOverlay:SetPoint("BOTTOMRIGHT", parchment, "BOTTOMRIGHT", -3, 3)
    parchmentOverlay:SetTexture(0.86, 0.62, 0.32, 0.45)
    preview.widgets.parchmentOverlay = parchmentOverlay
    local scrollName = "QuestCreatorPreviewScrollFrame"
    local scroll = CreateFrame("ScrollFrame", scrollName, parchment, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parchment, "TOPLEFT", 12, -12)
    scroll:SetPoint("BOTTOMRIGHT", parchment, "BOTTOMRIGHT", -28, 12)
    local scrollChild = CreateFrame("Frame", scrollName .. "Child", scroll)
    scrollChild:SetWidth(440)
    scrollChild:SetHeight(900)
    scroll:SetScrollChild(scrollChild)
    preview.widgets.previewScroll = scroll
    preview.widgets.previewScrollChild = scrollChild
    local questTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    questTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    questTitle:SetWidth(430)
    questTitle:SetJustifyH("LEFT")
    questTitle:SetTextColor(0.19, 0.08, 0.015)
    preview.widgets.questTitle = questTitle
    local questBody = scrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
    questBody:SetPoint("TOPLEFT", questTitle, "BOTTOMLEFT", 0, -18)
    questBody:SetWidth(430)
    questBody:SetJustifyH("LEFT")
    questBody:SetJustifyV("TOP")
    questBody:SetTextColor(0.12, 0.06, 0.01)
    preview.widgets.questBody = questBody
    local rewardTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    rewardTitle:SetWidth(430)
    rewardTitle:SetJustifyH("LEFT")
    rewardTitle:SetTextColor(0.19, 0.08, 0.015)
    rewardTitle:SetText("RECOMPENSAS")
    preview.widgets.previewRewardTitle = rewardTitle
    local rewardBody = scrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
    rewardBody:SetWidth(430)
    rewardBody:SetJustifyH("LEFT")
    rewardBody:SetJustifyV("TOP")
    rewardBody:SetTextColor(0.12, 0.06, 0.01)
    preview.widgets.previewRewardBody = rewardBody
    preview.widgets.previewRewardItemsTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    preview.widgets.previewRewardItemsTitle:SetWidth(430)
    preview.widgets.previewRewardItemsTitle:SetJustifyH("LEFT")
    preview.widgets.previewRewardItemsTitle:SetTextColor(0.19, 0.08, 0.015)
    preview.widgets.previewRewardItemsTitle:SetText("OBJETOS DE RECOMPENSA")
    local ICON_SIZE = 46
    local CELL_W    = 180
    local CELL_H    = 54
    local CELL_GAP  = 6
    local function MakeItemCell(parent, isChoice)
        local cell = CreateFrame("Button", nil, parent)
        cell:SetWidth(CELL_W)
        cell:SetHeight(CELL_H)
        cell:EnableMouse(true)
        local iconFrame = CreateFrame("Frame", nil, cell)
        iconFrame:SetWidth(ICON_SIZE)
        iconFrame:SetHeight(ICON_SIZE)
        iconFrame:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        iconFrame:SetBackdrop({
            bgFile  = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        iconFrame:SetBackdropBorderColor(0.3, 0.2, 0.05, 1)
        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT",  iconFrame, "TOPLEFT",  3, -3)
        icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        local qty = iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        qty:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 4)
        qty:SetTextColor(1, 1, 1)
        local nameFS = cell:CreateFontString(nil, "OVERLAY", "QuestFont")
        nameFS:SetPoint("TOPLEFT",    cell, "TOPLEFT",    ICON_SIZE + 6, -2)
        nameFS:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetJustifyV("TOP")
        nameFS:SetTextColor(0.12, 0.06, 0.01)
        cell.iconFrame = iconFrame
        cell.icon      = icon
        cell.qty       = qty
        cell.nameFS    = nameFS
        cell.itemId    = 0
        cell.isChoice  = isChoice or false
        cell:SetScript("OnEnter", function(self)
            if self.itemId and self.itemId > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. tostring(self.itemId))
                GameTooltip:Show()
            end
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cell:Hide()
        return cell
    end
    local choiceTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
    choiceTitle:SetWidth(430)
    choiceTitle:SetJustifyH("LEFT")
    choiceTitle:SetTextColor(0.12, 0.06, 0.01)
    choiceTitle:SetText("Podrás elegir una de estas recompensas:")
    preview.widgets.previewChoiceTitle = choiceTitle
    preview.choiceCells = {}
    for i = 1, 6 do
        preview.choiceCells[i] = MakeItemCell(scrollChild, true)
    end
    local alsoTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
    alsoTitle:SetWidth(430)
    alsoTitle:SetJustifyH("LEFT")
    alsoTitle:SetTextColor(0.12, 0.06, 0.01)
    alsoTitle:SetText("También recibirás:")
    preview.widgets.previewAlsoTitle = alsoTitle
    preview.fixedCells = {}
    for i = 1, 4 do
        preview.fixedCells[i] = MakeItemCell(scrollChild, false)
    end
    local moneyRow = CreateFrame("Frame", nil, scrollChild)
    moneyRow:SetWidth(430)
    moneyRow:SetHeight(22)
    preview.widgets.previewMoneyRow = moneyRow
    local moneyFS = moneyRow:CreateFontString(nil, "OVERLAY", "QuestFont")
    moneyFS:SetPoint("LEFT", moneyRow, "LEFT", 0, 0)
    moneyFS:SetWidth(430)
    moneyFS:SetJustifyH("LEFT")
    moneyFS:SetTextColor(0.12, 0.06, 0.01)
    preview.widgets.previewMoneyText = moneyFS
    local reqTitle = scrollChild:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    reqTitle:SetWidth(430)
    reqTitle:SetJustifyH("LEFT")
    reqTitle:SetTextColor(0.19, 0.08, 0.015)
    reqTitle:SetText("Objetos necesarios:")
    preview.widgets.previewReqTitle = reqTitle
    preview.reqCells = {}
    for i = 1, 6 do
        preview.reqCells[i] = MakeItemCell(scrollChild, false)
    end
    local acceptButton = CreateButton(qf, L.BTN_ACCEPT, 28, -375, 100, 24)
    local rejectButton = CreateButton(qf, L.BTN_REJECT, 412, -375, 100, 24)
    acceptButton:Hide()
    rejectButton:Hide()
    preview.widgets.acceptButton = acceptButton
    preview.widgets.rejectButton = rejectButton
    local stateOffer = CreateDarkButton(right, L.BTN_OFFER, 14, -55, 72, 24, true)
    local stateProgress = CreateDarkButton(right, L.BTN_IN_PROGRESS, 92, -55, 88, 24, true)
    local stateReady = CreateDarkButton(right, L.BTN_READY, 186, -55, 72, 24, true)
    local stateReward = CreateDarkButton(right, L.BTN_REWARD_PREVIEW, 14, -85, 120, 24, true)
    preview.widgets.stateButtons = {
        offer = stateOffer,
        progress = stateProgress,
        ready = stateReady,
        reward = stateReward
    }
    stateOffer:SetScript("OnClick", function()
        preview.state = "offer"
        QuestCreator.UpdatePreview()
    end)
    stateProgress:SetScript("OnClick", function()
        preview.state = "progress"
        QuestCreator.UpdatePreview()
    end)
    stateReady:SetScript("OnClick", function()
        preview.state = "ready"
        QuestCreator.UpdatePreview()
    end)
    stateReward:SetScript("OnClick", function()
        preview.state = "reward"
        QuestCreator.UpdatePreview()
    end)
    local showObjectives = CreateCheck(right, L.CHK_SHOW_OBJECTIVES, 14, -125, true)
    local showRewards = CreateCheck(right, L.CHK_SHOW_REWARDS, 14, -153, true)
    local showPortrait = CreateCheck(right, L.CHK_SHOW_PORTRAIT, 14, -181, true)
    local useTokens = CreateCheck(right, L.CHK_USE_PLAYER_TOKENS, 14, -209, true)
    preview.widgets.showObjectives = showObjectives
    preview.widgets.showRewards = showRewards
    preview.widgets.showPortrait = showPortrait
    preview.widgets.useTokens = useTokens
    showObjectives:SetScript("OnClick", function() QuestCreator.UpdatePreview() end)
    showRewards:SetScript("OnClick", function() QuestCreator.UpdatePreview() end)
    showPortrait:SetScript("OnClick", function() QuestCreator.UpdatePreview() end)
    useTokens:SetScript("OnClick", function() QuestCreator.UpdatePreview() end)
    CreateDivider(right, 14, -245, 220)
    CreateTitle(right, L.TITLE_QUICK_REWARD, 14, -270, 220)
    preview.widgets.rewardXP = CreateLabel(right, "", 14, -302, 220)
    preview.widgets.rewardMoney = CreateLabel(right, "", 14, -326, 220)
    CreateMutedLabel(right, L.LBL_REWARDS_HINT_1, 14, -365, 220)
    CreateMutedLabel(right, L.LBL_REWARDS_HINT_2, 14, -385, 220)
    CreateDivider(right, 14, -418, 220)
    preview.widgets.repText = CreateLabel(right, "", 14, -438, 220)
    preview.widgets.honorText = CreateLabel(right, "", 14, -458, 220)
    preview.widgets.npcObjectiveRows = {}
    for i = 1, 4 do
        local row = {}
        local fs = scrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
        fs:SetWidth(430)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetTextColor(0.12, 0.06, 0.01)
        fs:Hide()
        row.fs = fs
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetWidth(430)
        btn:SetHeight(18)
        btn:Hide()
        btn._npcEntry = 0
        btn:SetScript("OnClick", function()
            if btn._npcEntry and btn._npcEntry ~= 0 then
                ShowCreatureModelPopup(btn._npcEntry)
            end
        end)
        btn:SetScript("OnEnter", function()
            fs:SetTextColor(0.55, 0.25, 0.05)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Ver modelo 3D", 1, 0.82, 0)
            GameTooltip:AddLine("Entry: " .. tostring(btn._npcEntry), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            fs:SetTextColor(0.12, 0.06, 0.01)
            GameTooltip:Hide()
        end)
        row.btn = btn
        preview.widgets.npcObjectiveRows[i] = row
    end
end

function QuestCreator.UpdatePreview()
    if not preview or not preview.widgets or not preview.page then
        return
    end
    local title = GetText("title")
    if title == "" then title = "Nueva misión" end
    local qid = GetNumber("id", 0)
    local qLevel = GetNumber("questLevel", 1)
    local minLevel = GetNumber("minLevel", 1)
    local qType = GetQuestTypeText(GetNumber("questType", 2))
    local qInfo = GetText("logDescription")
    local flags = GetNumber("flags", 0)
    local sflags = GetNumber("specialFlags", 0)
    local starterEntry = GetNumber("starterEntry", 0)
    local enderEntry = GetNumber("enderEntry", 0)
    SafeSetText(preview.widgets.summaryId, qid)
    SafeSetText(preview.widgets.summaryTitle, title)
    SafeSetText(preview.widgets.summaryQuestType, qType)
    SafeSetText(preview.widgets.summaryQuestLevel, qLevel)
    SafeSetText(preview.widgets.summaryMinLevel, minLevel)
    SafeSetText(preview.widgets.summaryInfo, TokenReplace(qInfo))
    SafeSetText(preview.widgets.summaryFlags, flags)
    SafeSetText(preview.widgets.summarySpecialFlags, sflags)
    SafeSetText(preview.widgets.startNpcLabel, starterEntry > 0 and ("NPC " .. starterEntry) or "-")
    SafeSetText(preview.widgets.endNpcLabel, enderEntry > 0 and ("NPC " .. enderEntry) or "-")
    local npcName = "Quest Giver"
    if starterEntry > 0 then
        npcName = "NPC " .. tostring(starterEntry)
    elseif enderEntry > 0 then
        npcName = "NPC " .. tostring(enderEntry)
    end
    SafeSetText(preview.widgets.npcName, npcName)
    if preview.widgets.showPortrait and preview.widgets.showPortrait:GetChecked() then
        preview.widgets.portraitBg:Show()
        preview.widgets.portrait:SetTexture("Interface\\Icons\\Achievement_Leader_King_Varian_Wrynn")
    else
        preview.widgets.portraitBg:Hide()
    end
    local showObjectives = preview.widgets.showObjectives:GetChecked()
    local showRewards = preview.widgets.showRewards:GetChecked()
    local useTokens = preview.widgets.useTokens:GetChecked()
    local questDesc = GetText("questDescription")
    local completionText = GetText("completionText")
    local rewardText = GetText("rewardText")
    local logText = GetText("logDescription")
    if useTokens then
        questDesc = TokenReplace(questDesc)
        completionText = TokenReplace(completionText)
        rewardText = TokenReplace(rewardText)
        logText = TokenReplace(logText)
    end
    local bodyText = ""
    if preview.state == "offer" then
        bodyText = questDesc ~= "" and questDesc or logText
    elseif preview.state == "progress" then
        bodyText = completionText ~= "" and completionText or "Aún no has completado todos los objetivos."
    elseif preview.state == "ready" then
        bodyText = rewardText ~= "" and rewardText or "Buen trabajo. Has completado la misión."
    else
        bodyText = rewardText ~= "" and rewardText or "Vista previa de recompensas."
    end
    if bodyText == "" then
        bodyText = "Texto de misión vacío. Agrega QuestDescription o LogDescription en la pestaña Texts."
    end
    local objectivesBlock = ""
    local npcRowsData = {}
    if showObjectives and preview.state ~= "reward" then
        local objectiveLines = CollectObjectiveLines()
        local nonNpcLines = {}
        for _, line in ipairs(objectiveLines) do
            nonNpcLines[#nonNpcLines + 1] = line
        end
        objectivesBlock = "\n\nObjetivos de la misión\n"
        for i = 1, 4 do
            local entry = tonumber(requiredNpcRows[i] and requiredNpcRows[i].entry:GetText() or 0) or 0
            local count = tonumber(requiredNpcRows[i] and requiredNpcRows[i].count:GetText() or 0) or 0
            if entry > 0 and count > 0 then
                local info = creatureInfoCache[entry]
                local lineTxt
                if info and info.ready and info.name and info.name ~= "" then
                    lineTxt = "Elimina " .. tostring(count) .. " " .. info.name .. " (ID " .. tostring(entry) .. ")."
                else
                    lineTxt = "Elimina " .. tostring(count) .. " del NPC " .. tostring(entry) .. "."
                end
                npcRowsData[#npcRowsData + 1] = { entry = entry, lineText = lineTxt }
            end
        end
        local hasNpcRows = #npcRowsData > 0
        for _, line in ipairs(objectiveLines) do
            local isNpcLine = false
            for _, nd in ipairs(npcRowsData) do
                if line == nd.lineText then isNpcLine = true; break end
            end
            if not isNpcLine then
                objectivesBlock = objectivesBlock .. line .. "\n"
            end
        end
        for _ = 1, #npcRowsData do
            objectivesBlock = objectivesBlock .. "\n"
        end
    end
    local finalBody = bodyText .. objectivesBlock
    local rewardBlock = ""
    if showRewards then
        rewardBlock = BuildPreviewRewardBlock()
    end
    preview.widgets.questTitle:SetText(string.upper(title))
    preview.widgets.questBody:SetText(finalBody)
    local rows = preview.widgets.npcObjectiveRows
    if rows then
        for _, row in ipairs(rows) do
            row.fs:Hide()
            row.fs:SetText("")
            row.btn:Hide()
            row.btn._npcEntry = 0
        end
        if showObjectives and preview.state ~= "reward" and #npcRowsData > 0 then
            if not preview.widgets.measureFS then
                local mfs = preview.widgets.previewScrollChild:CreateFontString(nil, "OVERLAY", "QuestFont")
                mfs:SetWidth(370)
                mfs:SetJustifyH("LEFT")
                mfs:SetJustifyV("TOP")
                mfs:SetAlpha(0)
                mfs:SetPoint("TOPLEFT", preview.widgets.questTitle, "BOTTOMLEFT", 0, -18)
                preview.widgets.measureFS = mfs
            end
            local mfs    = preview.widgets.measureFS
            local titleH = preview.widgets.questTitle:GetStringHeight() or 20
            local baseY  = titleH + 18
            for idx, nd in ipairs(npcRowsData) do
                local row = rows[idx]
                if row then
                    local textBefore = bodyText .. "\n\nObjetivos de la misión\n"
                    for _, line in ipairs(CollectObjectiveLines()) do
                        local isNpc = false
                        for _, nd2 in ipairs(npcRowsData) do
                            if line == nd2.lineText then isNpc = true; break end
                        end
                        if not isNpc then
                            textBefore = textBefore .. line .. "\n"
                        end
                    end
                    for j = 1, idx - 1 do
                        textBefore = textBefore .. "\n"
                    end
                    mfs:SetText(textBefore)
                    local heightBefore = mfs:GetStringHeight() or 0
                    local rowY = -(baseY + heightBefore)
                    row.fs:ClearAllPoints()
                    row.fs:SetPoint("TOPLEFT", preview.widgets.previewScrollChild, "TOPLEFT", 0, rowY)
                    row.fs:SetText(nd.lineText)
                    row.fs:Show()
                    row.btn:ClearAllPoints()
                    row.btn:SetPoint("TOPLEFT", preview.widgets.previewScrollChild, "TOPLEFT", 0, rowY)
                    row.btn._npcEntry = nd.entry
                    row.btn:Show()
                end
            end
            mfs:SetText("")
        end
    end
    local bodyHeight = preview.widgets.questBody:GetStringHeight() or 120
    local rewardHeight = 0
    local CELL_W   = 180
    local CELL_H   = 54
    local CELL_GAP = 6
    local SC       = preview.widgets.previewScrollChild
    local function FillGrid(cells, items, startY)
        local curY = startY
        local row  = 0
        for idx, item in ipairs(items) do
            local cell = cells[idx]
            if not cell then break end
            local col = (idx - 1) % 2
            if col == 0 then
                if idx > 1 then curY = curY - CELL_H - CELL_GAP end
                row = row + 1
            end
            local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(item.id)
            itemName = itemName or ("Item " .. tostring(item.id))
            itemIcon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
            local r, g, b = 0.12, 0.06, 0.01
            if itemQuality then
                local qr, qg, qb = GetItemQualityColor(itemQuality)
                if qr then r, g, b = qr, qg, qb end
            end
            cell.icon:SetTexture(itemIcon)
            cell.nameFS:SetText(itemName)
            cell.nameFS:SetTextColor(r, g, b)
            cell.qty:SetText(item.count > 1 and tostring(item.count) or "")
            cell.itemId = item.id
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", SC, "TOPLEFT", col * (CELL_W + CELL_GAP), curY)
            cell:Show()
        end
        for idx = #items + 1, #cells do
            cells[idx]:Hide()
            cells[idx].itemId = 0
        end
        if #items == 0 then return startY end
        return curY - CELL_H
    end
    local choiceItems = {}
    for i = 1, 6 do
        local id    = tonumber(rewardChoiceRows[i] and rewardChoiceRows[i].entry:GetText() or 0) or 0
        local count = tonumber(rewardChoiceRows[i] and rewardChoiceRows[i].count:GetText() or 0) or 0
        if id > 0 then
            choiceItems[#choiceItems + 1] = { id = id, count = math.max(count, 1) }
        end
    end
    local fixedItems = {}
    for i = 1, 4 do
        local id    = tonumber(rewardItemRows[i] and rewardItemRows[i].entry:GetText() or 0) or 0
        local count = tonumber(rewardItemRows[i] and rewardItemRows[i].count:GetText() or 0) or 0
        if id > 0 then
            fixedItems[#fixedItems + 1] = { id = id, count = math.max(count, 1) }
        end
    end
    local reqItems = {}
    for i = 1, 6 do
        local id    = tonumber(requiredItemRows[i] and requiredItemRows[i].entry:GetText() or 0) or 0
        local count = tonumber(requiredItemRows[i] and requiredItemRows[i].count:GetText() or 0) or 0
        if id > 0 then
            reqItems[#reqItems + 1] = { id = id, count = math.max(count, 1) }
        end
    end
    preview.widgets.previewChoiceTitle:Hide()
    preview.widgets.previewAlsoTitle:Hide()
    preview.widgets.previewMoneyRow:Hide()
    preview.widgets.previewReqTitle:Hide()
    preview.widgets.previewRewardItemsTitle:Hide()
    for _, c in ipairs(preview.choiceCells) do c:Hide(); c.itemId = 0 end
    for _, c in ipairs(preview.fixedCells)  do c:Hide(); c.itemId = 0 end
    for _, c in ipairs(preview.reqCells)    do c:Hide(); c.itemId = 0 end
    local titleH    = preview.widgets.questTitle:GetStringHeight() or 20
    local bodyH     = preview.widgets.questBody:GetStringHeight()  or 20
    local rewardTitleY = -(titleH + 18 + bodyH + 24)
    preview.widgets.previewRewardTitle:ClearAllPoints()
    preview.widgets.previewRewardTitle:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, rewardTitleY)
    preview.widgets.previewRewardBody:ClearAllPoints()
    preview.widgets.previewRewardBody:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, rewardTitleY - 20)
    if preview.state == "reward" then
        preview.widgets.previewRewardTitle:Show()
    else
        preview.widgets.previewRewardTitle:Hide()
    end
    preview.widgets.previewRewardBody:SetText("")
    preview.widgets.previewRewardBody:Hide()
    local cursorY = rewardTitleY - 8
    if preview.state == "reward" then
        cursorY = cursorY - 22
    end
    local showChoiceAndFixed = showRewards and (preview.state ~= "progress")
    preview.widgets.previewChoiceTitle:Hide()
    preview.widgets.previewAlsoTitle:Hide()
    preview.widgets.previewMoneyRow:Hide()
    if showChoiceAndFixed then
        if #choiceItems > 0 then
            preview.widgets.previewChoiceTitle:ClearAllPoints()
            preview.widgets.previewChoiceTitle:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, cursorY)
            preview.widgets.previewChoiceTitle:Show()
            cursorY = cursorY - 18
            cursorY = FillGrid(preview.choiceCells, choiceItems, cursorY)
            cursorY = cursorY - CELL_GAP - 4
        end
        if #fixedItems > 0 then
            preview.widgets.previewAlsoTitle:ClearAllPoints()
            preview.widgets.previewAlsoTitle:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, cursorY)
            preview.widgets.previewAlsoTitle:Show()
            cursorY = cursorY - 18
            cursorY = FillGrid(preview.fixedCells, fixedItems, cursorY)
            cursorY = cursorY - CELL_GAP - 4
        end
        local money_r = GetNumber("rewardMoney", 0)
        local gr, sr, cr = MoneyToText(money_r)
        local xpVal    = math.max(GetNumber("rewardXpDifficulty", 0) * 690, 0)
        local honorR   = GetNumber("rewardHonor", 0)
        local arenaR   = GetNumber("rewardArenaPoints", 0)
        local allParts = {}
        if gr > 0    then allParts[#allParts+1] = gr .. "|cffffd700oro|r"    end
        if sr > 0    then allParts[#allParts+1] = sr .. "|cffc7c7c7plata|r"  end
        if cr > 0    then allParts[#allParts+1] = cr .. "|cffb87333cobre|r"  end
        if xpVal > 0 then allParts[#allParts+1] = xpVal  .. " exp."          end
        if honorR > 0 then allParts[#allParts+1] = honorR .. " honor"        end
        if arenaR > 0 then allParts[#allParts+1] = arenaR .. " pts. arena"   end
        if #allParts > 0 then
            local mr = preview.widgets.previewMoneyRow
            mr:ClearAllPoints()
            mr:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, cursorY)
            preview.widgets.previewMoneyText:SetText("También recibirás: " .. table.concat(allParts, "  "))
            mr:Show()
            cursorY = cursorY - 22 - CELL_GAP
        end
    else
        for _, c in ipairs(preview.choiceCells) do c:Hide(); c.itemId = 0 end
        for _, c in ipairs(preview.fixedCells)  do c:Hide(); c.itemId = 0 end
    end
    preview.widgets.previewReqTitle:Hide()
    for _, c in ipairs(preview.reqCells) do c:Hide(); c.itemId = 0 end
    if showObjectives and (preview.state == "offer" or preview.state == "progress") and #reqItems > 0 then
        preview.widgets.previewReqTitle:ClearAllPoints()
        preview.widgets.previewReqTitle:SetPoint("TOPLEFT", SC, "TOPLEFT", 0, cursorY - 8)
        preview.widgets.previewReqTitle:Show()
        cursorY = cursorY - 8 - 20
        cursorY = FillGrid(preview.reqCells, reqItems, cursorY)
        cursorY = cursorY - CELL_GAP
    end
    local totalHeight = math.max(math.abs(cursorY) + 40, 330)
    preview.widgets.previewScrollChild:SetHeight(totalHeight)
    preview.widgets.previewScroll:SetVerticalScroll(0)
    local money = GetNumber("rewardMoney", 0)
    local g, s, c = MoneyToText(money)
    local xpPreview = math.max(GetNumber("rewardXpDifficulty", 0) * 690, 0)
    SafeSetText(preview.widgets.rewardXP, (L.LBL_XP or "XP") .. ": " .. tostring(xpPreview))
    SafeSetText(preview.widgets.rewardMoney, (L.LBL_MONEY or "Money") .. ": " .. tostring(g) .. "g " .. tostring(s) .. "s " .. tostring(c) .. "c")
    local repValue = GetNumber("rewardFactionValue1", 0)
    if repValue == 0 then
        repValue = GetNumber("rewardFactionValue2", 0)
    end
    local honor = GetNumber("rewardHonor", 0)
    SafeSetText(preview.widgets.repText, L.LBL_REPUTATION .. ": +" .. tostring(repValue))
    SafeSetText(preview.widgets.honorText, L.LBL_HONOR .. ": +" .. tostring(honor))
    if preview.state == "offer" then
        preview.widgets.acceptButton:SetText(L.BTN_ACCEPT)
        preview.widgets.rejectButton:SetText(L.BTN_REJECT)
    elseif preview.state == "progress" then
        preview.widgets.acceptButton:SetText(L.BTN_CONTINUE)
        preview.widgets.rejectButton:SetText(L.BTN_CLOSE)
    elseif preview.state == "ready" then
        preview.widgets.acceptButton:SetText(L.BTN_COMPLETE)
        preview.widgets.rejectButton:SetText(L.BTN_CANCEL)
    else
        preview.widgets.acceptButton:SetText(L.BTN_ACCEPT)
        preview.widgets.rejectButton:SetText(L.BTN_CLOSE)
    end
    for key, button in pairs(preview.widgets.stateButtons) do
        if button then
            if key == preview.state then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end
    end
end

local function InstallPreviewHooks()
    if preview.hooksInstalled then
        return
    end
    preview.hooksInstalled = true
    for _, widget in pairs(fields) do
        if type(widget) == "table" and not widget._isDropdownProxy and widget.GetScript and widget.SetScript then
            local oldTextChanged = widget:GetScript("OnTextChanged")
            widget:SetScript("OnTextChanged", function(self, ...)
                if oldTextChanged then
                    oldTextChanged(self, ...)
                end
                if QuestCreator.UpdatePreview then
                    QuestCreator.UpdatePreview()
                end
            end)
        end
    end
    local function HookPairRows(rows)
        for _, row in ipairs(rows) do
            if row.entry then
                local oldEntry = row.entry:GetScript("OnTextChanged")
                row.entry:SetScript("OnTextChanged", function(self, ...)
                    if oldEntry then
                        oldEntry(self, ...)
                    end
                    if QuestCreator.UpdatePreview then
                        QuestCreator.UpdatePreview()
                    end
                end)
            end
            if row.count then
                local oldCount = row.count:GetScript("OnTextChanged")
                row.count:SetScript("OnTextChanged", function(self, ...)
                    if oldCount then
                        oldCount(self, ...)
                    end
                    if QuestCreator.UpdatePreview then
                        QuestCreator.UpdatePreview()
                    end
                end)
            end
        end
    end
    HookPairRows(requiredNpcRows)
    HookPairRows(requiredItemRows)
    HookPairRows(itemDropRows)
    HookPairRows(rewardItemRows)
    HookPairRows(rewardChoiceRows)
    for _, row in ipairs(requiredNpcRows) do
        if row.entry then
            local prevHook = row.entry:GetScript("OnTextChanged")
            row.entry:SetScript("OnTextChanged", function(self, userInput)
                if prevHook then prevHook(self, userInput) end
                if not userInput then return end
                local entry = tonumber(self:GetText()) or 0
                if entry > 0 then
                    RequestCreatureInfoFromServer(entry)
                    QueueCreaturePreload(entry)
                elseif entry < 0 then
                    RequestGameObjectInfoFromServer(-entry)
                end
            end)
        end
    end
end

local function CreateDeleteFrame()
    deleteFrame = CreateFrame("Frame", "QuestCreatorDeleteFrame", UIParent)
    deleteFrame:SetWidth(430)
    deleteFrame:SetHeight(220)
    deleteFrame:SetPoint("CENTER")
    deleteFrame:SetFrameStrata("DIALOG")
    deleteFrame:EnableMouse(true)
    tinsert(UISpecialFrames, "QuestCreatorDeleteFrame")
    deleteFrame:SetMovable(true)
    deleteFrame:RegisterForDrag("LeftButton")
    deleteFrame:SetScript("OnDragStart", deleteFrame.StartMoving)
    deleteFrame:SetScript("OnDragStop", deleteFrame.StopMovingOrSizing)
    deleteFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    deleteFrame.title = deleteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deleteFrame.title:SetPoint("TOP", deleteFrame, "TOP", 0, -20)
    deleteFrame.title:SetText("Delete Quest")
    deleteFrame.info = deleteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deleteFrame.info:SetPoint("TOPLEFT", deleteFrame, "TOPLEFT", 25, -50)
    deleteFrame.info:SetWidth(380)
    deleteFrame.info:SetJustifyH("LEFT")
    deleteFrame.info:SetText("")
    deleteFrame.confirm = CreateFrame("EditBox", nil, deleteFrame)
    deleteFrame.confirm:SetPoint("TOPLEFT", deleteFrame, "TOPLEFT", 35, -135)
    deleteFrame.confirm:SetWidth(230)
    deleteFrame.confirm:SetHeight(22)
    deleteFrame.confirm:SetAutoFocus(false)
    deleteFrame.confirm:SetFontObject(GameFontHighlightSmall)
    deleteFrame.confirm:SetTextInsets(6, 6, 2, 2)
    deleteFrame.confirm:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local deleteButton = CreateFrame("Button", nil, deleteFrame, "UIPanelButtonTemplate")
    deleteButton:SetPoint("TOPLEFT", deleteFrame, "TOPLEFT", 280, -132)
    deleteButton:SetWidth(90)
    deleteButton:SetHeight(24)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        if deleteFrame.confirmDeleteChain then
            AIO.Handle("QuestCreator", "DeleteQuestChain", currentDeleteQuestId, deleteFrame.confirm:GetText())
        else
            AIO.Handle("QuestCreator", "DeleteQuest", currentDeleteQuestId, deleteFrame.confirm:GetText())
        end
    end)
    local closeButton = CreateFrame("Button", nil, deleteFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", deleteFrame, "BOTTOM", 0, 20)
    closeButton:SetWidth(90)
    closeButton:SetHeight(24)
    closeButton:SetText("Cancel")
    closeButton:SetScript("OnClick", function()
        deleteFrame:Hide()
    end)
    deleteFrame.confirmDeleteChain = false
    deleteFrame:Hide()
end

local navTabButtons = {}

local function ShowPageAndUpdateTabs(name)
    HideAllPages()
    if pages[name] then 
        pages[name]:Show() 
    end
    if name == "preview" and QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
    for tabName, btn in pairs(navTabButtons) do
        if tabName == name then
            btn._active = true
            btn:Activate()
        else
            btn._active = false
            btn:Deactivate()
        end
    end
end

local function CreateFactionIcon(parent, x, y, width, height)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    icon:SetWidth(width)
    icon:SetHeight(height)
    
    local faction = UnitFactionGroup("player")
    
    if faction == "Alliance" then
        icon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
        icon:SetTexCoord(0.754882813, 0.887695313, 0.615234375, 0.749023438)
    elseif faction == "Horde" then
        icon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
        icon:SetTexCoord(0.620117188, 0.752929688, 0.615234375, 0.749023438)
    else
        icon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
        icon:SetTexCoord(0.485351563, 0.618164063, 0.615234375, 0.749023438)
    end
    
    return icon
end

local function CreateMainFrame()
    frame = CreateFrame("Frame", "QuestCreatorMainFrame", UIParent)
    frame:SetWidth(1200)
    frame:SetHeight(750)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    tinsert(UISpecialFrames, "QuestCreatorMainFrame")
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -10)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 10)
    bg:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    bg:SetTexCoord(0.000000000, 0.860000000, 0.000000000, 0.600000000)

    frame:SetBackdrop({
        edgeFile = "Interface\\QuestCreator\\border-tooltip-Noa",
        tile     = true,
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)

    local factionIcon = CreateFactionIcon(frame, 12, -20, 75, 75)
    
    local titleBg = frame:CreateTexture(nil, "BORDER")
    titleBg:SetPoint("TOP", frame, "TOP", 0, -30)
    titleBg:SetWidth(600)
    titleBg:SetHeight(100)
    titleBg:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    titleBg:SetTexCoord(0.011718750, 0.677421875, 0.894531250, 1.000000000)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", titleBg, "CENTER", 0, 10)
    title:SetText(L.APP_TITLE)
    title:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -14)
    close:SetScript("OnClick", function() frame:Hide() end)
    local langDropdown = CreateFrame("Frame", "QuestCreatorLangDropdown", frame, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -74)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(langDropdown, 110) end
    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(langDropdown, function(self, level)
            for _, code in ipairs(LOCALE_ORDER) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = LOCALE_DISPLAY[code]
                info.value = code
                info.func = function(b) SetClientLocale(b.value) end
                info.checked = (code == GetSelectedLocale())
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(langDropdown, GetSelectedLocale()) end
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(langDropdown, LOCALE_DISPLAY[GetSelectedLocale()] or "English") end
    local langLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("RIGHT", langDropdown, "LEFT", 0, 2)
    langLabel:SetText(L.LBL_LANGUAGE)
    langLabel:SetTextColor(SOFT_GOLD_R, SOFT_GOLD_G, SOFT_GOLD_B)
	
    local helpButton = CreateHelpButton(frame, 25, -95, 42)
    helpButton:SetScript("OnClick", function() ShowHelpDialog() end)
	
    local BTN_NORMAL = {0.005859375, 0.099609375, 0.689453125, 0.734375000}
    local BTN_HOVER = {0.101562500, 0.195312500, 0.689453125, 0.734375000}

    local clearButton = CreateHeaderActionButton(frame, L.BTN_CLEAR, nil, -25, 125, 34, false, BTN_NORMAL, BTN_HOVER)
    clearButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -25)

    local clearIcon = clearButton:CreateTexture(nil, "OVERLAY")
    clearIcon:SetSize(28, 28)
    clearIcon:SetPoint("LEFT", clearButton, "LEFT", 5, 0)
    clearIcon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    clearIcon:SetTexCoord(0.428710938, 0.475585938, 0.621093750, 0.667945313)
    clearButton.icon = clearIcon

    local saveButton = CreateHeaderActionButton(frame, L.BTN_SAVE, nil, -25, 125, 34, false, BTN_NORMAL, BTN_HOVER)
    saveButton:SetPoint("RIGHT", clearButton, "LEFT", -5, 0)

    local saveIcon = saveButton:CreateTexture(nil, "OVERLAY")
    saveIcon:SetSize(28, 28)
    saveIcon:SetPoint("LEFT", saveButton, "LEFT", 5, 0)
    saveIcon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    saveIcon:SetTexCoord(0.313476563, 0.361328125, 0.621093750, 0.667945313)
    saveButton.icon = saveIcon

    local validateButton = CreateHeaderActionButton(frame, L.BTN_VALIDATE, nil, -25, 125, 34, false, BTN_NORMAL, BTN_HOVER)
    validateButton:SetPoint("RIGHT", saveButton, "LEFT", -5, 0)

    local validateIcon = validateButton:CreateTexture(nil, "OVERLAY")
    validateIcon:SetSize(28, 28)
    validateIcon:SetPoint("LEFT", validateButton, "LEFT", 5, 0)
    validateIcon:SetTexture("Interface\\QuestCreator\\uiframequestCreator")
    validateIcon:SetTexCoord(0.370117188, 0.416992188, 0.621093750, 0.667945313)
    validateButton.icon = validateIcon

    clearButton:SetScript("OnClick", function()
        ClearEditor()
    end)

    saveButton:SetScript("OnClick", function()
        local payload = BuildPayloadFromUI()
        AIO.Handle("QuestCreator", "Save", payload)
    end)

    validateButton:SetScript("OnClick", function()
        local payload = BuildPayloadFromUI()
        AIO.Handle("QuestCreator", "Validate", payload)
    end)

    local nav = {
        { L.TAB_BASIC,      "basic"      },
        { L.TAB_TEXTS,      "texts"      },
        { L.TAB_OBJECTIVES, "objectives" },
        { L.TAB_REWARDS,    "rewards"    },
        { L.TAB_REPUTATION, "reputation" },
        { L.TAB_CHAIN,      "chain"      },
        { L.TAB_STARTER,    "starter"    },
        { L.TAB_ADVANCED,   "advanced"   },
        { L.TAB_QUEST_LIST, "browser"    },
        { L.TAB_PREVIEW,    "preview"    }
    }
    local prevTab = nil
    for i, item in ipairs(nav) do
        local btn = CreateTabButton(frame, item[1], 0, 0, 100, 28)
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -142)
        else
            btn:SetPoint("TOPLEFT", prevTab, "TOPRIGHT", 15, 0)
        end
        btn:SetScript("OnClick", function()
		    PlaySound("igCharacterInfoTab")
            ShowPageAndUpdateTabs(item[2])
        end)
        navTabButtons[item[2]] = btn
        prevTab = btn
    end
    contentFrame = CreateFrame("Frame", "QuestCreatorContentFrame", frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -160)
    contentFrame:SetWidth(1150)
    contentFrame:SetHeight(550)
    contentFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\QuestCreator\\border-tooltip-Noa",
        tile     = true,
        tileSize = 16,
        edgeSize = 24,
        insets   = { left = 4, right = 4, top = 8, bottom = 8 }
    })
    contentFrame:SetBackdropColor(DARK_BG_R, DARK_BG_G, DARK_BG_B, 1)
    contentFrame:SetBackdropBorderColor(BORDER_GOLD_R, BORDER_GOLD_G, BORDER_GOLD_B, 1)
    CreateBasicPage(contentFrame)
    CreateTextsPage(contentFrame)
    CreateObjectivesPage(contentFrame)
    CreateRewardsPage(contentFrame)
    CreateReputationPage(contentFrame)
    CreateChainPage(contentFrame)
    CreateStarterPage(contentFrame)
    CreateAdvancedPage(contentFrame)
    CreateBrowserPage(contentFrame)
    CreatePreviewPage(contentFrame)
    CreateDeleteFrame()
    InstallPreviewHooks()
    ClearEditor()
    ShowPageAndUpdateTabs("preview")
    frame:Hide()
end

function QuestCreator.ShowFrame()
    if not frame then
        CreateMainFrame()
    end

    ShowPageAndUpdateTabs("preview")
    frame:Show()
    
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

function QuestCreator.BeginQuestListStream(...)
    local args = { ... }
    args = QC_ShiftIfSender(args, true)
    QuestCreator_StreamList.direction = tostring(args[1] or "forward")
    QuestCreator_StreamList.startId = tonumber(args[2]) or 1
    QuestCreator_StreamList.pageSize = 16
    QuestCreator_StreamList.expected = tonumber(args[4]) or 0
    QuestCreator_StreamList.quests = {}
    SetBrowserStatus("Recibiendo stream de quests... esperado: " .. tostring(QuestCreator_StreamList.expected))
end

function QuestCreator.AddQuestListRow(...)
    local args = { ... }
    args = QC_ShiftIfSender(args, false)
    QuestCreator_StreamList.quests[#QuestCreator_StreamList.quests + 1] = {
        id = tonumber(args[1]) or 0,
        title = HexDecode(args[2] or ""),
        level = tonumber(args[3]) or 0,
        minLevel = tonumber(args[4]) or 0,
        sortId = tonumber(args[5]) or 0,
        rewardNextQuest = tonumber(args[6]) or 0
    }
end

function QuestCreator.EndQuestListStream(...)
    local args = { ... }
    args = QC_ShiftIfSender(args, true)
    local direction = args[1]
    local quests = QuestCreator_StreamList.quests
    SetBrowserStatus("Stream recibido: " .. tostring(#quests) .. " quests.")
    RenderQuestRows(quests, QuestCreator_StreamList.direction or direction or "forward")
end

function QuestCreator.ApplyCriticalQuestFields(...)
    local args = { ... }
    if type(args[1]) == "string" and args[1] == UnitName("player") then
        table.remove(args, 1)
    elseif type(args[1]) == "string" and tonumber(args[1]) == nil and tonumber(args[2]) ~= nil then
        table.remove(args, 1)
    end
    local questId = tonumber(args[1]) or 0
    local requiredPlayerKills = tonumber(args[2]) or 0
    local rewardHonor = tonumber(args[3]) or 0
    local rewardKillHonor = tonumber(args[4]) or 0
    local startItem = tonumber(args[5]) or 0
    local flags = tonumber(args[6]) or 0
    local specialFlags = tonumber(args[7]) or 0
    local questInfoId = tonumber(args[8]) or 0
    local questType = tonumber(args[9]) or 2
    local questLevel = tonumber(args[10]) or 1
    local minLevel = tonumber(args[11]) or 1
    local questSortId = tonumber(args[12]) or 0
    local rewardMoney = tonumber(args[13]) or 0
    local rewardXpDifficulty = tonumber(args[14]) or 5
    local rewardDisplaySpell = tonumber(args[15]) or 0
    local rewardSpell = tonumber(args[16]) or 0
    local rewardNextQuest = tonumber(args[17]) or 0
    local rewardMoneyDifficulty = tonumber(args[18]) or 0
    local allowableRaces = tonumber(args[19]) or 0
    SetBox("id", questId)
    SetBox("requiredPlayerKills", requiredPlayerKills)
    SetBox("rewardHonor", rewardHonor)
    SetBox("rewardKillHonor", rewardKillHonor)
    SetBox("startItem", startItem)
    SetBox("flags", flags)
    SetBox("specialFlags", specialFlags)
    ApplyChecks(flags, QuestCreator_Flags, flagChecks)
    ApplyChecks(specialFlags, QuestCreator_SpecialFlags, specialFlagChecks)
    SetBox("questInfoId", questInfoId)
    SetBox("questType", questType)
    SetBox("questLevel", questLevel)
    SetBox("minLevel", minLevel)
    SetBox("questSortId", questSortId)
    SetBox("allowableRaces", allowableRaces)
    SetBox("rewardMoney", rewardMoney)
    SetBox("rewardXpDifficulty", rewardXpDifficulty)
    SetBox("rewardDisplaySpell", rewardDisplaySpell)
    SetBox("rewardSpell", rewardSpell)
    SetBox("rewardNextQuest", rewardNextQuest)
    SetBox("rewardMoneyDifficulty", rewardMoneyDifficulty)
    Print("Critical load aplicado: Quest " .. tostring(questId) .. " RequiredPlayerKills = " .. tostring(requiredPlayerKills))
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
end

function QuestCreator.ShowValidationErrors(...)
    local errors = QC_FirstRealArg(...)
    Print("|cffff3333Errores:|r")
    if type(errors) == "table" then
        for _, err in pairs(errors) do
            DEFAULT_CHAT_FRAME:AddMessage("|cffff7777- " .. tostring(err) .. "|r")
        end
    elseif errors ~= nil then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff7777- " .. tostring(errors) .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff7777- Error desconocido.|r")
    end
end

function QuestCreator.ShowValidationSuccess(...)
    local data = QC_FirstRealArg(...)
    Print("|cff33ff33Validación correcta.|r Quests: " .. tostring(data and data.count or 1))
end

function QuestCreator.ShowSaveSuccess(...)
    local ids = QC_FirstRealArg(...)
    Print("|cff33ff33Guardado correcto.|r " .. tostring(ids or ""))
end

function QuestCreator.LoadQuestIntoUI(...)
    local quest = QC_FirstRealArg(...)
    if type(quest) ~= "table" then
        Print("No se recibió data de quest.")
        return
    end
    if not frame then
        CreateMainFrame()
    end
    LoadQuestIntoFields(quest)
    ShowPage("preview")
    frame:Show()
    for i = 1, 4 do
        local key = "requiredNpcOrGo" .. i
        local entry = tonumber(quest[key]) or 0
        if entry > 0 then
            RequestCreatureInfoFromServer(entry)
            QueueCreaturePreload(entry)
        elseif entry < 0 then
            RequestGameObjectInfoFromServer(-entry)
        end
    end
    Print("|cff33ff33Quest cargada:|r " .. tostring(quest.id))
end

function QuestCreator.LoadQuestCopyIntoUI(...)
    local data = QC_FirstRealArg(...)
    if type(data) ~= "table" or type(data.quest) ~= "table" then
        Print("No se recibió data de copia.")
        return
    end
    if not frame then
        CreateMainFrame()
    end
    LoadQuestIntoFields(data.quest)
    if fields and fields["title"] then
        local t = fields["title"]:GetText() or ""
        t = t:gsub("\\n", " ")
        t = t:gsub("\n", " ")
        t = t:gsub("%s*%(Copy%)%s*$", "")
        t = t:gsub("%s*%(COPY%)%s*$", "")
        t = t:gsub("%s*%- Copy%s*$", "")
        t = t:gsub("%s+$", "")
        fields["title"]:SetText(t)
    end
    ShowPage("texts")
    frame:Show()
    if not frame._copyBanner then
        local banner = CreateFrame("Frame", nil, frame)
        banner:SetHeight(28)
        banner:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -38)
        banner:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -38)
        banner:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        banner:SetBackdropColor(0.7, 0.5, 0, 0.85)
        banner:SetBackdropBorderColor(1, 0.8, 0, 1)
        banner:SetFrameStrata("HIGH")
        local bannerText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bannerText:SetPoint("CENTER", banner, "CENTER", 0, 0)
        bannerText:SetTextColor(1, 1, 0.6)
        bannerText:SetText("[!] COPIA - Edita el titulo antes de guardar y pulsa Save")
        local bannerClose = CreateFrame("Button", nil, banner, "UIPanelCloseButton")
        bannerClose:SetSize(20, 20)
        bannerClose:SetPoint("RIGHT", banner, "RIGHT", -2, 0)
        bannerClose:SetScript("OnClick", function()
            banner:Hide()
        end)
        frame._copyBanner = banner
    end
    frame._copyBanner:Show()
    C_Timer.After(0.05, function()
        if fields and fields["title"] then
            local titleBox = fields["title"]
            titleBox:SetFocus()
            local len = string.len(titleBox:GetText() or "")
            titleBox:SetCursorPosition(len)
            titleBox:HighlightText(0, len)
        end
    end)
    for i = 1, 4 do
        local key = "requiredNpcOrGo" .. i
        local entry = tonumber(data.quest[key]) or 0
        if entry > 0 then
            RequestCreatureInfoFromServer(entry)
            QueueCreaturePreload(entry)
        elseif entry < 0 then
            RequestGameObjectInfoFromServer(-entry)
        end
    end
    Print("|cffffaa00[QuestCreator]|r Copia lista. ID: |cffffcc00" .. tostring(data.newId) .. "|r — Edita el título y pulsa |cff33ff33Save|r.")
end

function QuestCreator.ShowDeletePreview(...)
    local previewData = QC_FirstRealArg(...)
    if type(previewData) ~= "table" then
        Print("No se recibió preview de borrado.")
        return
    end
    currentDeleteQuestId = previewData.id
    deleteFrame.confirmDeleteChain = false
    deleteFrame.title:SetText("Delete Quest")
    deleteFrame.info:SetText("Vas a borrar:" .. "\n[" .. tostring(previewData.id) .. "] " .. tostring(previewData.title) .. "\n\nPara confirmar escribe:" .. "\n" .. tostring(previewData.confirmText))
    deleteFrame.confirm:SetText("")
    deleteFrame:Show()
end

function QuestCreator.ShowDeleteSuccess(...)
    local questId = QC_FirstRealArg(...)
    Print("|cff33ff33Quest borrada:|r " .. tostring(questId))
    if deleteFrame then
        deleteFrame:Hide()
    end
    AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
end

function QuestCreator.ShowDeleteChainSuccess(...)
    local chain = QC_FirstRealArg(...)
    Print("|cff33ff33Cadena borrada.|r")
    if type(chain) == "table" then
        for _, id in pairs(chain) do
            DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Borrada: " .. tostring(id) .. "|r")
        end
    elseif chain ~= nil then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Borrada: " .. tostring(chain) .. "|r")
    end
    if deleteFrame then
        deleteFrame:Hide()
    end
    AIO.Handle("QuestCreator", "ListQuestsForward", currentListId)
end

RequestCreatureInfoFromServer = function(entry)
    entry = tonumber(entry) or 0
    if entry <= 0 then return end
    local cache = creatureInfoCache[entry]
    if cache and cache.requested then
        return
    end
    creatureInfoCache[entry] = {
        name = (cache and cache.name) or "",
        displayId = (cache and cache.displayId) or 0,
        requested = true,
        ready = false
    }
    AIO.Handle("QuestCreator", "RequestCreatureInfo", entry)
end

RequestGameObjectInfoFromServer = function(entry)
    entry = tonumber(entry) or 0
    if entry <= 0 then return end
    local cache = gameObjectInfoCache[entry]
    if cache and cache.requested then
        return
    end
    gameObjectInfoCache[entry] = {
        name = (cache and cache.name) or "",
        displayId = (cache and cache.displayId) or 0,
        requested = true,
        ready = false
    }
    AIO.Handle("QuestCreator", "RequestGameObjectInfo", entry)
end

function QuestCreator.ReceiveCreatureInfo(...)
    local args = { ... }
    args = QC_ShiftIfSender(args, false)
    local entry     = tonumber(args[1]) or 0
    local found     = tonumber(args[2]) or 0
    local name      = HexDecode(args[3] or "")
    local displayId = tonumber(args[4]) or 0
    if entry <= 0 then return end
    creatureInfoCache[entry] = {
        name      = name,
        displayId = displayId,
        requested = true,
        ready     = (found == 1)
    }
    if found == 1 then
        QueueCreaturePreload(entry)
    end
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
    if creatureModelFrame and creatureModelFrame:IsShown()
        and creatureModelFrame.pendingEntry == entry then
        if creatureModelFrame.ApplyData then
            creatureModelFrame.ApplyData(entry, name, displayId, false)
        end
    end
end

function QuestCreator.ReceiveGameObjectInfo(...)
    local args = { ... }
    args = QC_ShiftIfSender(args, false)
    local entry = tonumber(args[1]) or 0
    local found = tonumber(args[2]) or 0
    local name = HexDecode(args[3] or "")
    local displayId = tonumber(args[4]) or 0
    if entry <= 0 then return end
    gameObjectInfoCache[entry] = {
        name = name,
        displayId = displayId,
        requested = true,
        ready = (found == 1)
    }
    if QuestCreator.UpdatePreview then
        QuestCreator.UpdatePreview()
    end
    if creatureModelFrame and creatureModelFrame:IsShown()
        and creatureModelFrame.pendingEntry == -entry then
        if creatureModelFrame.ApplyData then
            creatureModelFrame.ApplyData(-entry, name, displayId, true)
        end
    end
end

local function CreateCreatureModelFrame()
    if creatureModelFrame then
        return creatureModelFrame
    end
    local f = CreateFrame("Frame", "QuestCreatorCreatureModelFrame", UIParent)
    f:SetWidth(340)
    f:SetHeight(430)
    f:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    tinsert(UISpecialFrames, "QuestCreatorCreatureModelFrame")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    f:SetBackdropBorderColor(0.85, 0.62, 0.28, 1)
    local titleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", f, "TOP", 0, -18)
    titleLabel:SetText("Vista del NPC")
    titleLabel:SetTextColor(1, 0.82, 0.2)
    f.title = titleLabel
    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOP", titleLabel, "BOTTOM", 0, -2)
    subtitle:SetWidth(300)
    subtitle:SetJustifyH("CENTER")
    subtitle:SetText("")
    subtitle:SetTextColor(0.9, 0.9, 0.9)
    f.subtitle = subtitle
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() f:Hide() end)
    local model = CreateFrame("PlayerModel", "QuestCreatorNPCModel", f)
    model:SetSize(300, 300)
    model:SetPoint("CENTER", f, "CENTER", 0, 10)
    model:SetFrameLevel(f:GetFrameLevel() + 10)
    local modelBg = model:CreateTexture(nil, "BACKGROUND")
    modelBg:SetAllPoints()
    modelBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    modelBg:SetVertexColor(0.03, 0.03, 0.05, 1)
    f.model = model
    local hint = model:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 10)
    hint:SetPoint("BOTTOM", model, "BOTTOM", 0, 6)
    hint:SetText("|cff888888Arrastra para rotar · Scroll para zoom|r")
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("CENTER", model, "CENTER", 0, 0)
    status:SetWidth(280)
    status:SetJustifyH("CENTER")
    status:SetText("")
    status:SetTextColor(1, 0.5, 0.3)
    f.status = status
    local rotLeft = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rotLeft:SetWidth(56)
    rotLeft:SetHeight(22)
    rotLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 10)
    rotLeft:SetText("<<")
    rotLeft:SetScript("OnClick", function()
        model:SetFacing(model:GetFacing() - 0.4)
    end)
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetWidth(76)
    resetBtn:SetHeight(22)
    resetBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        f.currentScale = 0.4
        model:SetCamera(1)
        model:SetFacing(0.3)
        model:SetPosition(0, 0, 0)
        model:SetModelScale(0.4)
    end)
    local rotRight = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rotRight:SetWidth(56)
    rotRight:SetHeight(22)
    rotRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 10)
    rotRight:SetText(">>")
    rotRight:SetScript("OnClick", function()
        model:SetFacing(model:GetFacing() + 0.4)
    end)
    local _rotating    = false
    local _startX      = 0
    local _startFacing = 0
    local dragFrame = CreateFrame("Frame")
    dragFrame:Hide()
    dragFrame:SetScript("OnUpdate", function()
        if not _rotating then
            dragFrame:Hide()
            return
        end
        local x = GetCursorPosition()
        model:SetFacing(_startFacing + (x - _startX) * 0.02)
    end)
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then
            _rotating    = true
            _startX      = GetCursorPosition()
            _startFacing = self:GetFacing()
            dragFrame:Show()
        end
    end)
    model:SetScript("OnMouseUp", function()
        _rotating = false
        dragFrame:Hide()
    end)
    model:EnableMouseWheel(true)
    f.currentScale = 0.4
    model:SetScript("OnMouseWheel", function(self, delta)
        local s = (f.currentScale or 0.4) + delta * 0.05
        s = math.max(0.05, math.min(3.0, s))
        f.currentScale = s
        self:SetModelScale(s)
    end)
    local _loadEntry     = 0
    local _loadIsGo      = false
    local _loadDisplayId = 0
    local _waitFrames    = 0
    local _applied       = false
    model:SetScript("OnUpdate", function(self)
        if _loadEntry == 0 then return end
        if _waitFrames > 0 then
            _waitFrames = _waitFrames - 1
            return
        end
        if _applied then return end
        _applied = true
        if _loadIsGo then
            pcall(function()
                self:SetDisplayInfo(_loadDisplayId)
                self:SetCamera(1)
                self:SetModelScale(f.currentScale or 0.4)
                self:SetFacing(0.3)
                self:SetPosition(0, 0, 0)
            end)
        else
            pcall(function()
                self:SetCreature(_loadEntry)
                self:SetCamera(1)
                self:SetModelScale(f.currentScale or 0.4)
                self:SetFacing(0.3)
                self:SetPosition(0, 0, 0)
            end)
        end
        f.status:SetText("")
        _loadEntry = 0
    end)
    function f.ApplyData(entry, name, displayId, isGameObject)
        f.title:SetText(isGameObject and "Vista del GameObject" or "Vista del NPC")
        local absEntry = math.abs(tonumber(entry) or 0)
        if name and name ~= "" then
            f.subtitle:SetText(name .. "  (Entry " .. absEntry .. ")")
        else
            f.subtitle:SetText("Entry " .. absEntry)
        end
        f.currentScale = 0.4
        _applied       = false
        _loadIsGo      = isGameObject
        _loadDisplayId = displayId or 0
        model:ClearModel()
        f.status:SetText("")
        if isGameObject then
            _loadEntry   = absEntry
            _waitFrames  = 10
        else
            _loadEntry  = absEntry
            local alreadyPreloaded = _preloadQueueSeen[absEntry]
            _waitFrames = alreadyPreloaded and 5 or 30
        end
    end
    f:Hide()
    creatureModelFrame = f
    return f
end

ShowCreatureModelPopup = function(rawEntry)
    rawEntry = tonumber(rawEntry) or 0
    if rawEntry == 0 then
        Print("Entry inválida (0).")
        return
    end
    local f = CreateCreatureModelFrame()
    f:Show()
    f.pendingEntry = rawEntry
    if rawEntry > 0 then
        local cache = creatureInfoCache[rawEntry]
        if cache and cache.ready then
            f.ApplyData(rawEntry, cache.name, cache.displayId, false)
        else
            f.title:SetText("Vista del NPC")
            f.subtitle:SetText("Cargando...  (Entry " .. rawEntry .. ")")
            f.status:SetText("Consultando base de datos...")
            f.model:ClearModel()
            RequestCreatureInfoFromServer(rawEntry)
            QueueCreaturePreload(rawEntry)
        end
    else
        local goEntry = -rawEntry
        local cache = gameObjectInfoCache[goEntry]
        if cache and cache.ready then
            f.ApplyData(rawEntry, cache.name, cache.displayId, true)
        else
            f.title:SetText("Vista del GameObject")
            f.subtitle:SetText("Cargando...  (Entry " .. goEntry .. ")")
            f.status:SetText("Consultando base de datos...")
            f.model:ClearModel()
            RequestGameObjectInfoFromServer(goEntry)
        end
    end
end

SLASH_ACQB1 = "/acqb"
SlashCmdList["ACQB"] = function()
    QuestCreator.ShowFrame()
end