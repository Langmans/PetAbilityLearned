local _, ns = ...

ns.Locales.frFR = {
    strings = {
        SPLASH_TITLE = "Nouvelle technique de familier apprise !",
        SPLASH_FROM_PET = "Apprise de %s. Enseignez-la à d'autres familiers via le Dressage des bêtes.",
        SPLASH_TEACH = "Enseignez-la à votre familier depuis la fenêtre Dressage des bêtes.",

        STATUS = "Annonce pendant %d s à l'échelle %.2f, son %s, débogage %s. Commandes : %s",
        STATUS_ON = "activé",
        STATUS_OFF = "désactivé",
        NOT_HUNTER = "Seuls les chasseurs apprennent des techniques de familier ; rien n'est surveillé sur ce personnage.",
        TEST_SPELL = "Griffe",
        TEST_RANK = "Rang 2",
        NO_LEARN_MESSAGE = "Ce client n'a pas de message d'apprentissage à imiter.",
        SIMULATING = "Simulation : %s",
        NOT_WILD = "%s n'est pas une technique de familier apprise dans la nature ; pas d'annonce.",
        DURATION_SET = "Durée de l'annonce : %d secondes.",
        SCALE_SET = "Échelle de l'annonce : %.2f.",
        SOUND_ON = "Son activé.",
        SOUND_OFF = "Son désactivé.",
        POSITION_RESET = "Position de l'annonce réinitialisée.",
        DEBUG_ON = "Débogage activé.",
        DEBUG_OFF = "Débogage désactivé.",
        OPTIONS_AFTER_COMBAT = "En combat : les options s'ouvriront à la fin du combat.",

        OPTION_ABOUT = "Version %s par %s, licence %s.",
        OPTION_WEBSITE = "Site web (Ctrl+C pour copier) :",
        OPTION_DESCRIPTION = "Quand votre chasseur apprend une technique de familier d'une bête apprivoisée "
            .. "(par exemple Griffe rang 2 d'un rôdeur nocturne), elle s'affiche en grand au milieu de l'écran. "
            .. "Les techniques achetées à un dresseur de familiers ne comptent pas.\n\n"
            .. "Faites glisser l'annonce pour la déplacer, clic droit pour la fermer ; elle reste tant que la "
            .. "souris est dessus. Tapez /pal pour les réglages.",
        OPTION_DEBUG = "Trace de débogage",
        OPTION_DEBUG_NOTE = "Afficher dans le chat chaque apprentissage vu par l'addon et sa décision. "
            .. "Comme /pal debug.",
        OPTION_TEST = "Afficher l'annonce",
        OPTION_SIM = "Simuler un apprentissage",
    },
}
