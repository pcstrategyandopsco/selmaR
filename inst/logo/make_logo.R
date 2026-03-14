library(ggplot2)
library(hexSticker)
library(showtext)
library(sysfonts)

font_add_google("Inter", "inter")
showtext_auto()

# Minimal empty subplot
p <- ggplot() +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA))

sticker(
  p,
  s_x = 1, s_y = 0.75, s_width = 1.3, s_height = 0.01,
  package = "selmaR",
  p_size = 28,
  p_color = "#FFFFFF",
  p_family = "inter",
  p_fontface = "bold",
  p_y = 1.0,
  h_fill = "#1B4F72",
  h_color = "#2E86C1",
  h_size = 1.5,
  filename = "man/figures/logo.png",
  dpi = 300
)

message("Logo saved to man/figures/logo.png")
