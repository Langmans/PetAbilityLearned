local _, ns = ...

ns.Locales.koKR = {
    strings = {
        SPLASH_TITLE = "새 소환수 기술을 배웠습니다!",
        SPLASH_FROM_PET = "%s에게서 %s|1을;를; 배웠습니다.",
        SPLASH_TEACH = "야수 조련 창에서 소환수에게 가르치세요.",

        SPLASH_POINTS = "%s의 남은 훈련 포인트: %d.",
        HINT_TEACHES = "%s|1이;가; 가르쳐 줄 수 있는 기술: %s.",
        HINT_OPEN_TRAINING = "애드온이 기술 레벨을 알 수 있도록 야수 조련 창을 한 번 여세요.",
        STATUS = "알림 %d초, 크기 %.2f, 소리 %s, 스크린샷 %s, 소환수 안내 %s, 디버그 %s. 명령어: %s",
        SCREENSHOT_ON = "알림마다 스크린샷을 찍습니다.",
        SCREENSHOT_OFF = "스크린샷 끔.",
        HINTS_ON = "소환수를 부르거나 길들이면 아직 배울 수 있는 기술을 알려 줍니다.",
        HINTS_OFF = "새 소환수 안내 끔.",
        STATUS_ON = "켬",
        STATUS_OFF = "끔",
        SOUND_NAME_FAMILY = "소환수 계열",
        SOUND_NAME_LEVELUP = "레벨 업",
        NOT_HUNTER = "소환수 기술은 사냥꾼만 배웁니다. 이 캐릭터에서는 아무것도 감시하지 않습니다.",
        TEST_SPELL = "할퀴기",
        TEST_RANK = "2 레벨",
        NO_LEARN_MESSAGE = "이 클라이언트에는 흉내 낼 습득 메시지가 없습니다.",
        SIMULATING = "시뮬레이션: %s",
        NOT_WILD = "%s|1은;는; 야생에서 배우는 소환수 기술이 아닙니다. 알림 없음.",
        DURATION_SET = "알림 시간: %d초.",
        SCALE_SET = "알림 크기: %.2f.",
        SOUND_FAMILY = "소리: 소환수 계열의 울음소리 (없으면 레벨 업 소리).",
        SOUND_LEVELUP = "소리: 레벨 업 소리.",
        SOUND_OFF = "소리 끔.",
        POSITION_RESET = "알림 위치를 초기화했습니다.",
        HISTORY_EMPTY = "애드온을 설치한 뒤로 이 캐릭터가 배운 소환수 기술이 없습니다.",
        HISTORY_TITLE = "이 캐릭터가 배운 소환수 기술 (최근 %d개 / 전체 %d개):",
        HISTORY_FROM = "%s에게서",
        DEBUG_ON = "디버그 켬.",
        DEBUG_OFF = "디버그 끔.",
        OPTIONS_AFTER_COMBAT = "전투 중: 전투가 끝나면 설정이 열립니다.",

        OPTION_ABOUT = "버전 %s, 제작자 %s, %s 라이선스.",
        OPTION_WEBSITE = "웹사이트 (Ctrl+C로 복사):",
        OPTION_DESCRIPTION = "사냥꾼이 길들인 야수에게서 소환수 기술을 배우면 (예: 밤추적자에게서 할퀴기 2 레벨) "
            .. "화면 가운데에 크게 표시됩니다. 소환수 조련사에게서 산 기술은 해당되지 않습니다.\n\n"
            .. "알림을 끌어서 옮기고, 오른쪽 클릭으로 닫고, 마우스를 올려 두면 계속 표시됩니다. "
            .. "설정은 /pal 을 입력하세요.",
        OPTION_DEBUG = "디버그 추적",
        OPTION_DEBUG_NOTE = "애드온이 본 모든 습득과 그 판단을 대화창에 표시합니다. /pal debug 와 같습니다.",
        OPTION_TEST = "알림 보기",
        OPTION_SIM = "습득 시뮬레이션",
    },
}
