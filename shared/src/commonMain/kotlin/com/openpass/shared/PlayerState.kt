package com.openpass.shared

enum class PlayerState(val value: Int) {
    UNSTARTED(-1),
    ENDED(0),
    PLAYING(1),
    PAUSED(2),
    BUFFERING(3),
    VIDEO_CUED(5);

    companion object {
        fun fromValue(value: Int): PlayerState =
            entries.firstOrNull { it.value == value } ?: UNSTARTED
    }
}
