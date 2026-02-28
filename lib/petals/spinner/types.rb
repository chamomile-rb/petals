# frozen_string_literal: true

module Petals
  SpinnerType = Data.define(:frames, :fps)

  module Spinners
    LINE      = SpinnerType.new(frames: %w[| / - \\], fps: 10)
    DOT       = SpinnerType.new(frames: %w[⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷], fps: 10)
    MINI_DOT  = SpinnerType.new(frames: %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏], fps: 12)
    JUMP      = SpinnerType.new(frames: %w[⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠], fps: 10)
    PULSE     = SpinnerType.new(frames: %w[█ ▓ ▒ ░], fps: 8)
    POINTS    = SpinnerType.new(frames: ["∙∙∙", "●∙∙", "∙●∙", "∙∙●"], fps: 7)
    GLOBE     = SpinnerType.new(frames: %w[🌍 🌎 🌏], fps: 4)
    MOON      = SpinnerType.new(frames: %w[🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘], fps: 8)
    MONKEY    = SpinnerType.new(frames: %w[🙈 🙉 🙊], fps: 3)
    METER     = SpinnerType.new(frames: ["▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰", "▰▰▱", "▰▱▱", "▱▱▱"], fps: 7)
    HAMBURGER = SpinnerType.new(frames: %w[☱ ☲ ☴ ☲], fps: 3)
    ELLIPSIS  = SpinnerType.new(frames: ["", ".", "..", "..."], fps: 3)
  end
end
