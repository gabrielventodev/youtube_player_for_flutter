package com.openpass.shared

data class PlayerConfig(
    val videoId: String,
    val autoPlay: Boolean = false,
    val showControls: Boolean = true,
    val startSeconds: Int = 0,
    val endSeconds: Int = 0,
    val showFullscreenButton: Boolean = true,
    val enableJsApi: Boolean = true,
    val showRelatedVideos: Boolean = false,
    val loop: Boolean = false,
)
