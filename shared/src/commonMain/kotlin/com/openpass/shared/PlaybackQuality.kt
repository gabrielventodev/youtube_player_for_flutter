package com.openpass.shared

enum class PlaybackQuality(val value: String) {
    SMALL("small"),
    MEDIUM("medium"),
    LARGE("large"),
    HD720("hd720"),
    HD1080("hd1080"),
    HIGHRES("highres"),
    DEFAULT("default");

    companion object {
        fun fromValue(value: String): PlaybackQuality =
            entries.firstOrNull { it.value == value } ?: DEFAULT
    }
}
