function mod(a, b) {
    return (a + b) % b;
}
function lerp(t, x, y) {
    return (1-t)*x + t*y;
}
// 180,0,0 - 0,172,0 - 0,0,255
//const P_BLUE = 0.114;
var P_BLUE = 0.30;
//const P_RED = 0.299;
//const P_GREEN = 0.587;
var P_RED = 0.33747178329571104 * (1-P_BLUE);
var P_GREEN = (1-0.33747178329571104) * (1-P_BLUE);
function getP(R, G, B) {
    return Math.sqrt(P_RED * R**2 + P_GREEN * G**2 + P_BLUE * B**2);
}
// solve for k: sqrt(c) = sqrt(a * (kR)**2 + b * (kG)**2 + c * (kB)**2)
function getPCorrection(R, G, B) {
    return Math.sqrt(0.114) / Math.sqrt((P_RED * R**2) + (P_GREEN * G**2) + (P_BLUE * B**2));
}
// TODO: drawTriangle(canvasId, callback) {}
function drawCircle(canvasId, callback) {
    const canvas = document.querySelector(canvasId);
    const context = canvas.getContext("2d");
    const imageData = context.createImageData(canvas.width, canvas.height);
    const {data, width, height} = imageData;
    const circleRadius = width / 2;
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const yCentered = y - Math.floor(height / 2);
            const xCentered = x - Math.floor(width / 2);
            const r = Math.sqrt(xCentered ** 2 + yCentered ** 2);
            let alpha = 255;
            if (r > circleRadius) {
                alpha = 0;
            } else if (r >= circleRadius - 1) {
                alpha = (circleRadius - r) * 255;
            }
            const [R, G, B] = callback(xCentered, yCentered, r/circleRadius);
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
    })
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
    console.log('ayaya.drawHSQCircle')
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
