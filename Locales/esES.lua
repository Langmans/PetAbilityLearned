local _, ns = ...

-- Spanish for both Spanish clients: esES (Europe) and esMX (Latin America).
ns.Locales.esES = {
    strings = {
        SPLASH_TITLE = "¡Nueva habilidad de mascota aprendida!",
        SPLASH_FROM_PET = "%s te ha enseñado %s.",
        SPLASH_TEACH = "Enséñala a tu mascota desde la ventana de Adiestramiento de bestias.",

        SPLASH_POINTS = "%s tiene %d puntos de entrenamiento libres.",
        HINT_TEACHES = "%s puede enseñarte: %s.",
        HINT_OPEN_TRAINING = "Abre Adiestramiento de bestias una vez para que el addon conozca tus rangos.",
        STATUS = "Aviso durante %d s a escala %.2f, sonido %s, captura %s, consejos de mascota %s, depuración %s. Comandos: %s",
        SCREENSHOT_ON = "Se hace una captura de pantalla de cada aviso.",
        SCREENSHOT_OFF = "Sin capturas de pantalla.",
        HINTS_ON = "Al invocar o domesticar una mascota se indica lo que aún puede enseñarte.",
        HINTS_OFF = "Sin consejos sobre mascotas nuevas.",
        STATUS_ON = "activado",
        STATUS_OFF = "desactivado",
        SOUND_NAME_FAMILY = "familia de la mascota",
        SOUND_NAME_LEVELUP = "subida de nivel",
        NOT_HUNTER = "Solo los cazadores aprenden habilidades de mascota; en este personaje no se vigila nada.",
        TEST_SPELL = "Zarpazo",
        TEST_RANK = "Rango 2",
        NO_LEARN_MESSAGE = "Este cliente no tiene un mensaje de aprendizaje que imitar.",
        SIMULATING = "Simulando: %s",
        NOT_WILD = "%s no es una habilidad de mascota que se aprenda en la naturaleza; sin aviso.",
        DURATION_SET = "Duración del aviso: %d segundos.",
        SCALE_SET = "Escala del aviso: %.2f.",
        SOUND_FAMILY = "Sonido: el grito de la familia de tu mascota (el de subida de nivel si no tiene).",
        SOUND_LEVELUP = "Sonido: el de subida de nivel.",
        SOUND_OFF = "Sonido desactivado.",
        POSITION_RESET = "Posición del aviso restablecida.",
        HISTORY_EMPTY = "Este personaje no ha aprendido ninguna habilidad de mascota desde que se instaló el addon.",
        HISTORY_TITLE = "Habilidades de mascota aprendidas por este personaje (últimas %d de %d):",
        HISTORY_FROM = "de %s",
        DEBUG_ON = "Depuración activada.",
        DEBUG_OFF = "Depuración desactivada.",
        OPTIONS_AFTER_COMBAT = "En combate: las opciones se abrirán al terminar el combate.",

        OPTION_ABOUT = "Versión %s por %s, licencia %s.",
        OPTION_WEBSITE = "Web (Ctrl+C para copiar):",
        OPTION_DESCRIPTION = "Cuando tu cazador aprende una habilidad de mascota de una bestia domesticada "
            .. "(por ejemplo, Zarpazo rango 2 de un acechador nocturno), aparece en grande en el centro de la "
            .. "pantalla. Las habilidades compradas a un instructor de mascotas no cuentan.\n\n"
            .. "Arrastra el aviso para moverlo, clic derecho para cerrarlo; con el ratón encima se queda. "
            .. "Escribe /pal para los ajustes.",
        OPTION_SETTINGS = "Ajustes",
        OPTION_DURATION = "El aviso dura %d segundos",
        OPTION_SCALE = "Tamaño del aviso: %.2f",
        OPTION_SOUND = "Sonido",
        OPTION_SOUND_FAMILY = "El grito de la familia de la mascota (subida de nivel si no tiene)",
        OPTION_SOUND_LEVELUP = "El sonido de subida de nivel",
        OPTION_SOUND_OFF = "Sin sonido",
        OPTION_SCREENSHOT = "Hacer una captura de pantalla de cada aviso",
        OPTION_SCREENSHOT_NOTE = "Se guarda en la carpeta Screenshots del juego. Igual que /pal screenshot on y off.",
        OPTION_HINTS = "Decir lo que puede enseñar una mascota nueva",
        OPTION_HINTS_NOTE = "Al invocar o domesticar una mascota, el chat nombra las habilidades que tiene a un "
            .. "rango mayor que tú. Igual que /pal hints on y off.",
        OPTION_HISTORY = "Aprendido por este personaje",
        OPTION_HISTORY_NOTE = "%d aprendidas, las más recientes primero. Igual que /pal history.",
        OPTION_DEBUG = "Traza de depuración",
        OPTION_DEBUG_NOTE = "Mostrar en el chat cada aprendizaje que ve el addon y qué decidió. Igual que /pal debug.",
        OPTION_TEST = "Mostrar el aviso",
        OPTION_SIM = "Simular un aprendizaje",
    },
}
ns.Locales.esMX = ns.Locales.esES
