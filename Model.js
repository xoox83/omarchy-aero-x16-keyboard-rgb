.pragma library

function clamp(n, lo, hi) {
  n = Number(n)
  if (isNaN(n)) return lo
  if (n < lo) return lo
  if (n > hi) return hi
  return Math.round(n)
}

function hex(r, g, b) {
  function byte(n) {
    var h = clamp(n, 0, 255).toString(16)
    return h.length < 2 ? "0" + h : h
  }
  return "#" + byte(r) + byte(g) + byte(b)
}

function parseState(text) {
  var fallback = { r: 0, g: 80, b: 255, brightness: 100 }
  try {
    var o = JSON.parse(String(text || ""))
    if (!o || typeof o !== "object") return fallback
    return {
      r: clamp(o.r, 0, 255),
      g: clamp(o.g, 0, 255),
      b: clamp(o.b, 0, 255),
      brightness: clamp(o.brightness, 0, 100)
    }
  } catch (e) {
    return fallback
  }
}

function isOff(state) {
  if (!state) return true
  if (state.brightness <= 0) return true
  return state.r === 0 && state.g === 0 && state.b === 0
}

function swatchMatches(swatch, state) {
  if (!swatch || !state) return false
  if (swatch.id === "off") return isOff(state)
  if (isOff(state)) return false
  return swatch.r === state.r && swatch.g === state.g && swatch.b === state.b
}

var swatches = [
  { id: "off", name: "Off", r: 0, g: 0, b: 0 },
  { id: "red", name: "Red", r: 255, g: 0, b: 0 },
  { id: "orange", name: "Orange", r: 255, g: 120, b: 0 },
  { id: "yellow", name: "Yellow", r: 255, g: 200, b: 0 },
  { id: "green", name: "Green", r: 0, g: 255, b: 0 },
  { id: "cyan", name: "Cyan", r: 0, g: 200, b: 220 },
  { id: "blue", name: "Blue", r: 0, g: 80, b: 255 },
  { id: "purple", name: "Purple", r: 140, g: 0, b: 255 },
  { id: "magenta", name: "Magenta", r: 220, g: 0, b: 180 },
  { id: "white", name: "White", r: 255, g: 255, b: 255 }
]
