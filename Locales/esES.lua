local _, ns = ...

-- Spanish for both Spanish clients: esES (Europe) and esMX (Latin America).
ns.Locales.esES = {
    strings = {
        SPLASH_TITLE = "¡Nueva habilidad de mascota aprendida!",
        SPLASH_FROM_PET = "Aprendida de %s. Enséñala a otras mascotas con Adiestramiento de bestias.",
        SPLASH_TEACH = "Enséñala a tu mascota desde la ventana de Adiestramiento de bestias.",

        STATUS = "Aviso durante %d s a escala %.2f, sonido %s, depuración %s. Comandos: %s",
        STATUS_ON = "activado",
        STATUS_OFF = "desactivado",
        NOT_HUNTER = "Solo los cazadores aprenden habilidades de mascota; en este personaje no se vigila nada.",
        TEST_SPELL = "Zarpazo",
        TEST_RANK = "Rango 2",
        NO_LEARN_MESSAGE = "Este cliente no tiene un mensaje de aprendizaje que imitar.",
        SIMULATING = "Simulando: %s",
        NOT_WILD = "%s no es una habilidad de mascota que se aprenda en la naturaleza; sin aviso.",
        DURATION_SET = "Duración del aviso: %d segundos.",
        SCALE_SET = "Escala del aviso: %.2f.",
        SOUND_ON = "Sonido activado.",
        SOUND_OFF = "Sonido desactivado.",
        POSITION_RESET = "Posición del aviso restablecida.",
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
        OPTION_DEBUG = "Traza de depuración",
        OPTION_DEBUG_NOTE = "Mostrar en el chat cada aprendizaje que ve el addon y qué decidió. Igual que /pal debug.",
        OPTION_TEST = "Mostrar el aviso",
        OPTION_SIM = "Simular un aprendizaje",
    },
}
ns.Locales.esMX = ns.Locales.esES
