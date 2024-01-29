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
function fold(x, a) {
  return x / (x + a);
}
function unfold(y, a) {
  return y*a / (1 - y);
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
function cube(x) {
  return x*x*x;
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
function ln(x) {
  return Math.log(x);
}
PI = Math.PI;
TAU = 2*Math.PI;
function sin(x) {
  return Math.sin(x);
}
function cos(x) {
  return Math.cos(x);
}
function atan2(y, x) {
  return mod(Math.atan2(y, x), TAU);
}
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
// CIELAB // NOTE: http://www.brucelindbloom.com
const LAB_EPSILON = 216/24389;
const LAB_KAPPA = 24389/27;
function yToLstar(Y, whitepoint = WHITEPOINT_D65) {
  const y_r = Y / whitepoint[1];
  const lstar = (y_r > LAB_EPSILON) ? cbrt(y_r) * 116 - 16 : y_r * LAB_KAPPA;
  return lstar
}
function lstarToY(lstar, whitepoint = WHITEPOINT_D65) {
  const f_y = (lstar + 16) / 116;
  const y_r = (cube(f_y) > LAB_EPSILON) ? cube(f_y) : lstar / LAB_KAPPA;
  return y_r * whitepoint[1];
}
// cam16 // NOTE: https://observablehq.com/@jrus/cam16, https://arxiv.org/pdf/1802.06067.pdf
const WHITEPOINT_D65 = [95.047, 100, 108.883];
const M16 = [
  [ 0.401288,  0.650173, -0.051461],
  [-0.250268,  1.204414,  0.045854],
  [-0.002079,  0.048952,  0.953127],
]
const HUE_TABLE_h_i = [20.14, 90.0, 164.25, 237.53, 380.14];
const HUE_TABLE_e_i = [0.8,   0.7,  1.0,    1.2,    0.8   ];
const PAB_TO_RGB_a = [
  [ 460/1403,  451/1403,  288/1403 ],
  [ 460/1403, -891/1403, -261/1403 ],
  [ 460/1403, -220/1403, -6300/1403],
];
const M16_INVERSE = [
  [ 1.862070, -1.011250,  0.149187],
  [ 0.387527,  0.621447, -0.008974],
  [-0.015842, -0.034123,  1.049960],
];
/*
  XYZ_w: whitepoint
  Y_w = XYZ_w[1]: whitepoint luminance
  L_a: "adapting luminance" = average luminance of environment
  Y_b: "background luminance factor" = relative luminance of the nearby background (within 10°)
  F: adaptation factor
  c: surround factor
  N_c: chromatic induction factor
  RGB: modified cone response
  ...
*/
// NOTE: J has range 0 - Y_w
// NOTE: range of C depends on L_a and Y_b // TODO: can we give it a reasonable range?
// NOTE: h has range 0 - 360
class Cam16ViewingConditions {
  constructor(XYZ_w = WHITEPOINT_D65, L_a = 11.725677948856951, Y_b = lstarToY(50), F = 1.0, fullyAdapted = false) {
    const Y_w = XYZ_w[1];
    this.F = F // F = N_c
    // computed
    this.c = (F > 0.9)
      ? lerp((F-0.9) / 0.1, 0.59, 0.69)
      : lerp((F-0.8) / 0.1, 0.525, 0.59);
    const n = Y_b / Y_w;
    this.alpha_factor = pow(1.64 - pow(0.29, n), 0.73);
    this.z = 1.48 + sqrt(n);
    const D = fullyAdapted ? 1 : clamp(F * (1 - 1/3.6 * exp((-L_a - 42) / 92)), 0, 1);
    const k = 1/(5 * L_a + 1);
    this.F_l = k**4 * L_a + 0.1 * (1-k**4)**2 * cbrt(5 * L_a);
    this.F_l_root4 = pow(this.F_l, 0.25);
    this.N_bb = 0.725 / pow(n, 0.2); // N_cb = N_bb
    const RGB_w = mul_mat3_v3(M16, XYZ_w);
    this.D_RGB = [
      D * Y_w / RGB_w[0] + 1 - D, // NOTE: +1, -D are the correct signs
      D * Y_w / RGB_w[1] + 1 - D,
      D * Y_w / RGB_w[2] + 1 - D
    ]
    const RGB_wc = [
      this.D_RGB[0] * RGB_w[0],
      this.D_RGB[1] * RGB_w[1],
      this.D_RGB[2] * RGB_w[2],
    ];
    const RGB_aw = [this.adapt(RGB_wc[0]), this.adapt(RGB_wc[1]), this.adapt(RGB_wc[2])];
    this.A_w = (2 * RGB_aw[0] + RGB_aw[1] + RGB_aw[2] / 20) * this.N_bb;
  }
  adapt(v) {
    return 400 * sign(v) * fold(pow(this.F_l * abs(v) / 100, 0.42), 27.13);
  }
  unadapt(v) {
    const abs_v = abs(v);
    return sign(v) * (100 / this.F_l) * pow((27.13*abs_v) / (400 - abs_v), 1/0.42);
  }
  srgbToCam16(srgb) {
    const [X, Y, Z] = [0, 0, 0] // TODO!: srgb to xyz
    return this.xyzToCam16({X, Y, Z});
  }
  xyzToCam16({X, Y, Z}) {
    const RGB = mul_mat3_v3(M16, [X, Y, Z]); // NOTE: RGB here means cone responses
    const RGB_c = [
      RGB[0] * this.D_RGB[0],
      RGB[1] * this.D_RGB[1],
      RGB[2] * this.D_RGB[2],
    ];
    const R_a = this.adapt(RGB_c[0]);
    const G_a = this.adapt(RGB_c[1]);
    const B_a = this.adapt(RGB_c[2]);
    const p_2 =   2*R_a +         G_a + 1/20  * B_a;
    const a =       R_a - 12/11 * G_a + 1/11  * B_a;
    const b = 1/9 * R_a + 1/9 *   G_a - 2/9   * B_a;
    const u =       R_a +         G_a + 21/20 * B_a;
    const h_rad = atan2(b, a);
    const h = radToDeg(h_rad); // NOTE: h must be between 0 and 360°
    const h_ = h + 360 * (h < HUE_TABLE_h_i[0]);
    const e_t = (cos(degToRad(h_) + 2) + 3.8)/4;
    const J = 100 * pow(p_2 * this.N_bb / this.A_w, this.c*this.z);
    const p_1 = e_t * 50000/13 * this.F * this.N_bb;
    const t = (p_1 * sqrt(a*a + b*b)) / (u + 0.305);
    const alpha = pow(t, 0.9) * this.alpha_factor;
    const C = alpha * sqrt(J/100);
    const M = C * pow(this.F_l, 0.25);
    // Cam16Ucs
    const J_star = J / (0.007/1.7 * J + 1/1.7);
    const M_star = ln(1 + 0.0228 * M) / 0.0228;
    const a_star = M_star * cos(h_rad);
    const b_star = M_star * sin(h_rad);
    return {J, C, h, J_star, a_star, b_star};
  }
  cam16ToXyz({J, C, h}) {
    let alpha = (J == 0) ? 0 : C / sqrt(J/100);
    let t = pow(alpha / this.alpha_factor, 1/0.9);
    const h_ = h + 360 * (h < HUE_TABLE_h_i[0]);
    const e_t = (cos(degToRad(h_) + 2) + 3.8)/4;
    const p_1 = e_t * 50000/13 * this.F * this.N_bb;
    const p_2 = this.A_w * pow(J/100, 1/(this.c*this.z)) / this.N_bb;
    const h_rad = degToRad(h);
    const gamma = 23*(p_2 + 0.305)*t / (23*p_1 + 11*t*cos(h_rad) + 108*t*sin(h_rad));
    const a = gamma * cos(h_rad);
    const b = gamma * sin(h_rad);
    const RGB_a = mul_mat3_v3(PAB_TO_RGB_a, [p_2, a, b]);
    const RGB_c = [this.unadapt(RGB_a[0]), this.unadapt(RGB_a[1]), this.unadapt(RGB_a[2])];
    const RGB = [RGB_c[0]/this.D_RGB[0], RGB_c[1]/this.D_RGB[1], RGB_c[2]/this.D_RGB[2]];
    const XYZ = mul_mat3_v3(M16_INVERSE, RGB);
    return {X: XYZ[0], Y: XYZ[1], Z: XYZ[2]};
  }
}
default_viewing_conditions = new Cam16ViewingConditions();
console.log(default_viewing_conditions.xyzToCam16({X: 0, Y: 0, Z: 0})) // {J: 0, Q: 0, C: 0, M: 0, s: 0, h: 0}
const z = default_viewing_conditions.xyzToCam16({X: WHITEPOINT_D65[0]/2, Y: WHITEPOINT_D65[1]/2, Z: WHITEPOINT_D65[2]/2})
console.log(z)
console.log(default_viewing_conditions.cam16ToXyz({J: z.J, C: z.C, h: z.h})); // TODO!: one of these is wrong...
// TODO!: how does sRGB or w/e map to XYZ/CAM16?


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
