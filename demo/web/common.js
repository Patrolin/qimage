// math
function mod(a, b) {
  return (a + b) % b;
}
function lerp(t, x, y) {
  return (1 - t) * x + t * y;
}
function clamp(x, min, max) {
  return Math.min(Math.max(min, x), max);
}
function fold(a, b) {
  return a / (a + b);
}
function unfold(a, b) {
  return a / (b - a);
}
function abs(x) {
  return Math.abs(x);
}
function sign(x) {
  return (x > 0) - (x < 0);
}
function square(x) {
  return x*x;
}
function sqrt(x) {
  return Math.sqrt(x);
}
function cbrt(x) {
  return Math.cbrt(x);
}
function pow(x, y) {
  return Math.pow(x, y);
}
function exp(x, y) {
  return Math.exp(x, y);
}
function sin(x) {
  return Math.sin(x);
}
function cos(x) {
  return Math.cos(x);
}
function atan(x) {
  return Math.atan(x);
}
PI = Math.PI;
TAU = Math.TAU;
function degToRad(degrees) {
  return degrees * (Math.PI / 180);
}
function radToDeg(radians) {
  return radians * (180 / Math.PI);
}
function mul_mat3_v3(m, v) {
  return [
    m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2],
    m[1][0] * v[0] + m[1][1] * v[1] + m[1][2] * v[2],
    m[2][0] * v[0] + m[2][1] * v[1] + m[2][2] * v[2],
  ]
}
// CIELAB // TODO: http://www.brucelindbloom.com
function cielabGamma(L) {
  return (L > pow(6/29, 3)) ? cbrt(L) : L/(3 * (6/29)*(6/29)) + 4/29;
}
function lstarFromY(Y) {
  return (Y/100) * 116 - 16;
}
// cam16
WHITEPOINT_D65 = [95.047, 100, 108.883];
M16 = [
  [0.401288, 0.650173, -0.051461],
  [-0.250268, 1.204414, 0.045854],
  [-0.002079, 0.048952, 0.953127],
]
const HUE_TABLE_h_i = [20.14, 90.0, 164.25, 237.53, 380.14];
const HUE_TABLE_e_i = [0.8,   0.7,  1.0,    1.2,    0.8   ];
/*
  XYZ_w: whitepoint
  Y_w = XYZ_w[1]: whitepoint luminance
  L_a: adapting luminance
  Y_b: background luminance factor
  F: adaptation factor
  c: surround factor
  N_c: chromatic induction factor
  RGB_w: modified cone response
  ...
*/
class Cam16ViewingConditions {
  constructor(whitepoint = WHITEPOINT_D65, L_a = 11.725677948856951, Y_b = 50, F = 1.0) {
    this.whitepoint = whitepoint
    const Y_w = this.whitepoint[1];
    this.L_a = L_a
    this.Y_b = Y_b
    this.F = F // F = N_c
    // computed // TODO: how many of these are used?
    this.c = 1.265 - 2.325*F + 1.75*F*F; // NOTE: we fit a parabola to the table, but we won't use values other than 0.8,0.9,1.0 anyways
    this.RGB_w = mul_mat3_v3(M16, whitepoint);
    this.D = clamp(F * (1 - 1/3.6 * exp((-L_a - 42) / 92)), 0, 1);
    this.k = 1/(5 * L_a + 1);
    this.F_l = this.k**4 * L_a + 0.1 * (1-this.k**4)**2 * cbrt(5 * L_a);
    this.n = Y_b / Y_w;
    this.z = 1.48 + sqrt(this.n);
    this.N_bb = 0.725 / pow(this.n, 0.2); // N_cb = N_bb
    this.D_RGB = [
      this.D * Y_w / this.RGB_w[0] - 1 + this.D,
      this.D * Y_w / this.RGB_w[1] - 1 + this.D,
      this.D * Y_w / this.RGB_w[2] - 1 + this.D
    ]
    this.RGB_wc = [
      this.D_RGB[0] * this.RGB_w[0],
      this.D_RGB[1] * this.RGB_w[1],
      this.D_RGB[2] * this.RGB_w[2],
    ];
    this.RGB_aw = [this.adapt(this.RGB_wc[0]), this.adapt(this.RGB_wc[1]), this.adapt(this.RGB_wc[2])];
    this.A_w = (2 * this.RGB_aw[0] + this.RGB_aw[1] + this.RGB_aw[2] / 20) * this.N_bb;
  }
  adapt(v) {
    const tmp = pow(this.F_l * abs(v) / 100, 0.42);
    return 400 * sign(tmp) * fold(tmp, 27.13);
  }
  unadapt(v) {
    const abs_v = abs(v);
    return sign(v) * (100 / this.F_l * exp(27.13, 1/0.42)) * pow(abs_v / (400 - abs_v), 1/0.42); // TODO: who the fuck wrote this
  }
  xyzToCam16({X, Y, Z}) {
    const tmp_XYZ = mul_mat3_v3(M16, [X, Y, Z]);
    const R_a = tmp_XYZ[0] * this.D_RGB[0];
    const G_a = tmp_XYZ[1] * this.D_RGB[1];
    const B_a = tmp_XYZ[2] * this.D_RGB[2];
    const p_2 =   2*R_a +         G_a + 1/20  * B_a;
    const a =       R_a - 12/11 * G_a + 1/11  * B_a;
    const b = 1/9 * R_a + 1/9 *   G_a - 2/9   * B_a;
    const u =       R_a +         G_a + 21/20 * B_a;
    const h_rad = atan(b/a); // NOTE: h must be between 0 and 360° // TODO: use atan2
    const h = radToDeg(h_rad);
    const h_ = h + 360 * (h < HUE_TABLE_h_i[0]);
    const i = (h_ > HUE_TABLE_h_i[1]) + (h_ > HUE_TABLE_h_i[2]) + (h_ > HUE_TABLE_h_i[3]); // NOTE: we index from 0
    const e_t = (cos(degToRad(h_) + 2) + 3.8)/4;
    const H_i = i * 100;
    const H = H_i + 100 * fold(
      HUE_TABLE_e_i[i+1] * (h_ - HUE_TABLE_h_i[i]),
      HUE_TABLE_e_i[i] * (HUE_TABLE_h_i[i+1] - h_)
    );
    const A = p_2 * this.N_bb;
    const J = 100 * pow(A / this.A_w, this.c*this.z);
    const Q = 4/this.c * sqrt(J/100) * (this.A_w + 4) * pow(this.F_l, 0.25);
    const t = (50000/13 * this.F * this.N_bb * e_t * sqrt(a*a, b*b)) / (u + 0.305);
    const alpha = pow(t, 0.9) * pow(1.64 - pow(0.29, this.n), 0.73);
    const C = alpha * sqrt(J/100);
    const M = C * pow(this.F_l, 0.25);
    const s = 50 * sqrt(alpha*this.c / (this.A_w + 4));
    return {J, Q, C, M, s, H};
  }
  // NOTE: input = {J,Q}, {C,M,S}, {h}
  cam16ToXyz({J, Q, C, M, S, h}) {
    // TODO!: https://arxiv.org/pdf/1802.06067.pdf
    return {X, Y, Z};
  }
}
default_viewing_conditions = new Cam16ViewingConditions();
console.log(default_viewing_conditions.xyzToCam16({X: 0.9504559270516716, Y: 1, Z: 1.0890577507598784})) // TODO!: how does sRGB or w/e map to XYZ/CAM16?


// 180,0,0 - 0,172,0 - 0,0,255
//const P_BLUE = 0.114;
var P_BLUE = 0.3;
//const P_RED = 0.299;
//const P_GREEN = 0.587;
var P_RED = 0.33747178329571104 * (1 - P_BLUE);
var P_GREEN = (1 - 0.33747178329571104) * (1 - P_BLUE);
function getP(R, G, B) {
  return sqrt(P_RED * R ** 2 + P_GREEN * G ** 2 + P_BLUE * B ** 2);
}
// solve for k: sqrt(c) = sqrt(a * (kR)**2 + b * (kG)**2 + c * (kB)**2)
function getPCorrection(R, G, B) {
  return sqrt(0.114) / sqrt(P_RED * R ** 2 + P_GREEN * G ** 2 + P_BLUE * B ** 2);
}
// TODO?: drawTriangle(canvasId, callback) {}
function drawCircle(canvasId, callback) {
  const canvas = document.querySelector(canvasId);
  const context = canvas.getContext("2d");
  const imageData = context.createImageData(canvas.width, canvas.height);
  const { data, width, height } = imageData;
  const circleRadius = width / 2;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const yCentered = y - Math.floor(height / 2);
      const xCentered = x - Math.floor(width / 2);
      const r = sqrt(xCentered ** 2 + yCentered ** 2);
      let alpha = 255;
      if (r > circleRadius) {
        alpha = 0;
      } else if (r >= circleRadius - 1) {
        alpha = (circleRadius - r) * 255;
      }
      const [R, G, B] = callback(xCentered, yCentered, r / circleRadius);
      const i = (y * width + x) * 4;
      data[i] = R;
      data[i + 1] = G;
      data[i + 2] = B;
      data[i + 3] = alpha;
      context.putImageData(imageData, 0, 0);
    }
  }
  context.putImageData(imageData, 0, 0);
}
function drawColorCircle(canvasId, color) {
  drawCircle(canvasId, () => color);
}
function drawHSVCircle(canvasId) {
  drawCircle(canvasId, (xCentered, yCentered) => {
    const H = mod(Math.atan2(yCentered, xCentered) * (-3 / Math.PI), 6);
    const HInteger = Math.floor(H);
    const HRemainder = H - HInteger;
    let R,
      G,
      B = 0;
    if (HInteger === 0) {
      R = 255;
      G = HRemainder * 255;
      B = 0;
    } else if (HInteger === 1) {
      R = (1 - HRemainder) * 255;
      G = 255;
      B = 0;
    } else if (HInteger === 2) {
      R = 0;
      G = 255;
      B = HRemainder * 255;
    } else if (HInteger === 3) {
      R = 0;
      G = (1 - HRemainder) * 255;
      B = 255;
    } else if (HInteger === 4) {
      R = HRemainder * 255;
      G = 0;
      B = 255;
    } else if (HInteger === 5) {
      R = 255;
      G = 0;
      B = (1 - HRemainder) * 255;
    }
    if (xCentered === 0 && yCentered === 0) {
      R = G = B = 192;
    }
    return [R, G, B];
  });
}
// HSL??
function getHSQ(H, S, Q) {
  const HInteger = Math.floor(H);
  const _HRemainder = H - HInteger;
  //let HRemainder = (3 - 2 * _HRemainder) * (_HRemainder * _HRemainder);
  let HRemainder = 0.5 + (1 / Math.PI) * Math.asin(2 * _HRemainder - 1);
  //let HRemainder = _HRemainder;
  let R,
    G,
    B = 0;
  if (HInteger === 0) {
    R = (1 - HRemainder) * 255;
    G = HRemainder * 255;
    B = 0;
  } else if (HInteger === 1) {
    R = 0;
    G = (1 - HRemainder) * 255;
    B = HRemainder * 255;
  } else {
    R = HRemainder * 255;
    G = 0;
    B = (1 - HRemainder) * 255;
  }
  if (S === 0) {
    R = G = B = 128;
  }
  const P_correction = getPCorrection(R / 255, G / 255, B / 255);
  R = R * P_correction;
  G = G * P_correction;
  B = B * P_correction;
  return [R, G, B];
}
function drawHSQCircle(canvasId) {
  console.log("ayaya.drawHSQCircle");
  drawCircle(canvasId, (xCentered, yCentered, r) => {
    const H = mod(Math.atan2(yCentered, xCentered) * (-1.5 / Math.PI), 3);
    return getHSQ(H, r, 100);
  });
}
function drawHSQGreyCircle(canvasId) {
  drawCircle(canvasId, (xCentered, yCentered) => {
    const H = mod(Math.atan2(yCentered, xCentered) * (-1.5 / Math.PI), 3);
    let [R, G, B] = getHSQ(H, 100, 50);
    let P = getP(R / 255, G / 255, B / 255);
    P = P * 255 * getPCorrection(P, P, P);
    return [P, P, P];
  });
}
