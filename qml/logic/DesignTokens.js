function build(isDarkTheme, primaryColor) {
    var accent = primaryColor || "#e53446"
    var dark = !!isDarkTheme
    return {
        color: {
            accent: accent,
            page: dark ? "#1f1f1f" : "#f5f5f5",
            card: dark ? "#232323" : "#ffffff",
            border: dark ? "#3a3a3a" : "#d8d8d8",
            section: dark ? "#1a1a1a" : "#ececec",
            text: dark ? "#f2f2f2" : "#1f1f1f",
            textMuted: dark ? "#b8b8b8" : "#666666",
            textInverse: "#ffffff",
            selected: Qt.rgba(0.9, 0.2, 0.28, dark ? 0.22 : 0.16),
            tile: dark ? "#252525" : "#ffffff",
            tileBorder: dark ? "#3a3a3a" : "#dcdcdc",
            overlay: "#55000000",
            toastBg: "#000000",
            toastText: "#ffffff"
        },
        radius: {
            sm: 0.8,
            md: 1.2
        },
        spacing: {
            sm: 0.8,
            md: 1.2,
            lg: 1.8,
            page: 1.2
        },
        layout: {
            playerToolbarHeight: 7.25
        },
        typography: {
            body: "medium",
            bodySmall: "small",
            title: "large",
            heading: "x-large"
        }
    }
}
